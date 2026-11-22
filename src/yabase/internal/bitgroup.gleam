//// Codecs that write a fixed number of bits per character: Base2 (1),
//// the multibase form of Base8 (3), Base16 (4), the Base32 family (5) and
//// the Base64 family (6).
////
//// Input is read as bytes and output is gathered in a list that is joined
//// once, so encode and decode are linear on both targets.

import gleam/bit_array
import gleam/bool
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import yabase/core/error.{type CodecError, InvalidCharacter, InvalidLength}
import yabase/internal/alphabet.{type Alphabet}

const pad = 61

/// Whether encoded output is padded with "=".
pub type Padding {
  Unpadded
  /// Pad with "=" to a multiple of this many characters.
  PaddedTo(block: Int)
}

/// Encode `data` `bits` at a time. A final partial group is filled with
/// zero bits. `data` must be a whole number of bytes.
pub fn encode(
  data: BitArray,
  bits: Int,
  alphabet: Alphabet,
  padding: Padding,
) -> String {
  let #(symbols, count) = encode_loop(data, bits, alphabet, 0, 0, [], 0)
  let padding_length = case padding {
    Unpadded -> 0
    PaddedTo(block) -> { block - count % block } % block
  }
  list.repeat(pad, padding_length)
  |> list.append(symbols)
  |> list.reverse
  |> alphabet.to_string
}

fn encode_loop(
  data: BitArray,
  bits: Int,
  alphabet: Alphabet,
  buffer: Int,
  buffered: Int,
  acc: List(Int),
  count: Int,
) -> #(List(Int), Int) {
  case buffered >= bits, data {
    True, _ -> {
      let shift = buffered - bits
      let value = int.bitwise_shift_right(buffer, shift)
      let rest = buffer - int.bitwise_shift_left(value, shift)
      encode_loop(
        data,
        bits,
        alphabet,
        rest,
        shift,
        [alphabet.symbol(alphabet, value), ..acc],
        count + 1,
      )
    }
    False, <<byte, data:bytes>> ->
      encode_loop(
        data,
        bits,
        alphabet,
        buffer * 256 + byte,
        buffered + 8,
        acc,
        count,
      )
    False, _ ->
      case buffered {
        0 -> #(acc, count)
        _ -> {
          let value = int.bitwise_shift_left(buffer, bits - buffered)
          #([alphabet.symbol(alphabet, value), ..acc], count + 1)
        }
      }
  }
}

/// Decode input with no padding. Characters are checked first; then the
/// bits left over after the last whole byte must be fewer than `bits`, or
/// the result is `InvalidLength(character count)`. Leftover bits are
/// dropped.
pub fn decode_unpadded(
  input: String,
  bits: Int,
  alphabet: Alphabet,
) -> Result(BitArray, CodecError) {
  let bytes = bit_array.from_string(input)
  use length <- check_characters(bytes, alphabet, -1)
  use <- bool.guard(
    when: length * bits % 8 >= bits,
    return: Error(InvalidLength(length)),
  )
  Ok(unpack(bytes, bits, alphabet))
}

/// Decode input whose length must hold whole bytes exactly. The length is
/// checked before the characters, and counts characters (graphemes).
pub fn decode_exact(
  input: String,
  bits: Int,
  alphabet: Alphabet,
) -> Result(BitArray, CodecError) {
  let bytes = bit_array.from_string(input)
  case first_invalid(bytes, alphabet, -1, 0) {
    Ok(length) ->
      case length * bits % 8 {
        0 -> Ok(unpack(bytes, bits, alphabet))
        _ -> Error(InvalidLength(length))
      }
    Error(offset) -> {
      let length = string.length(input)
      case length * bits % 8 {
        0 -> Error(alphabet.invalid_character(alphabet, bytes, offset, offset))
        _ -> Error(InvalidLength(length))
      }
    }
  }
}

/// Decode RFC 4648 Base32 with optional "=" padding. Characters (and "=")
/// are checked first, then the padding, then the length.
pub fn decode_base32_padded(
  input: String,
  alphabet: Alphabet,
) -> Result(BitArray, CodecError) {
  let bytes = bit_array.from_string(input)
  use length <- check_characters(bytes, alphabet, pad)
  let data_length = first_pad(bytes, 0)
  let has_padding = data_length < length
  use <- bool.guard(
    when: has_padding && length % 8 != 0,
    return: Error(InvalidLength(length)),
  )
  use <- only_padding_after(bytes, data_length)
  use <- bool.guard(
    when: has_padding && data_length == 0,
    return: Error(InvalidLength(length)),
  )
  use <- bool.guard(
    when: data_length * 5 % 8 >= 5,
    return: Error(InvalidLength(length)),
  )
  Ok(unpack(take(bytes, data_length), 5, alphabet))
}

/// Decode RFC 4648 Base64 with mandatory "=" padding. Characters (and "=")
/// are checked first, then the length, then each group of four.
pub fn decode_base64_padded(
  input: String,
  alphabet: Alphabet,
) -> Result(BitArray, CodecError) {
  let bytes = bit_array.from_string(input)
  use length <- check_characters(bytes, alphabet, pad)
  use <- bool.guard(when: length % 4 != 0, return: Error(InvalidLength(length)))
  case base64_data_length(bytes, length, 0) {
    Ok(data_length) -> Ok(unpack(take(bytes, data_length), 6, alphabet))
    Error(error) -> Error(error)
  }
}

/// Where "=" may appear in padded Base64: as the last one or two characters
/// of the final group. Returns the number of data characters.
fn base64_data_length(
  bytes: BitArray,
  length: Int,
  position: Int,
) -> Result(Int, CodecError) {
  case bytes {
    <<a, b, c, d, rest:bytes>> -> {
      let last = bit_array.byte_size(rest) == 0
      case c == pad && d == pad, d == pad, no_pad_in([a, b, c, d], position) {
        True, _, _ if !last -> Error(InvalidLength(length))
        _, True, _ if !last -> Error(InvalidLength(length))
        True, _, _ ->
          no_pad_in([a, b], position) |> result.replace(position + 2)
        _, True, _ ->
          no_pad_in([a, b, c], position) |> result.replace(position + 3)
        _, _, Error(error) -> Error(error)
        _, _, Ok(Nil) if last -> Ok(position + 4)
        _, _, Ok(Nil) -> base64_data_length(rest, length, position + 4)
      }
    }
    _ -> Ok(position)
  }
}

fn no_pad_in(group: List(Int), position: Int) -> Result(Nil, CodecError) {
  case group {
    [] -> Ok(Nil)
    [byte, ..] if byte == pad -> Error(InvalidCharacter("=", position))
    [_, ..rest] -> no_pad_in(rest, position + 1)
  }
}

/// Check that every byte is a symbol (or `extra`), then continue with the
/// character count. Only ASCII passes, so the count is also the byte count.
fn check_characters(
  bytes: BitArray,
  alphabet: Alphabet,
  extra: Int,
  next: fn(Int) -> Result(BitArray, CodecError),
) -> Result(BitArray, CodecError) {
  case first_invalid(bytes, alphabet, extra, 0) {
    Ok(length) -> next(length)
    Error(offset) ->
      Error(alphabet.invalid_character(alphabet, bytes, offset, offset))
  }
}

/// The byte count if every byte is a symbol or `extra`, otherwise the
/// offset of the first one that is not.
fn first_invalid(
  bytes: BitArray,
  alphabet: Alphabet,
  extra: Int,
  offset: Int,
) -> Result(Int, Int) {
  case bytes {
    <<byte, rest:bytes>> ->
      case byte == extra, alphabet.lookup(alphabet, byte) {
        True, _ | _, alphabet.Value(_) ->
          first_invalid(rest, alphabet, extra, offset + 1)
        _, _ -> Error(offset)
      }
    _ -> Ok(offset)
  }
}

fn first_pad(bytes: BitArray, offset: Int) -> Int {
  case bytes {
    <<byte, _:bytes>> if byte == pad -> offset
    <<_, rest:bytes>> -> first_pad(rest, offset + 1)
    _ -> offset
  }
}

/// Every byte from `from` on must be "="; a data character after padding
/// is reported at the "=" just before it.
fn only_padding_after(
  bytes: BitArray,
  from: Int,
  next: fn() -> Result(BitArray, CodecError),
) -> Result(BitArray, CodecError) {
  case bit_array.slice(bytes, from, bit_array.byte_size(bytes) - from) {
    Ok(tail) ->
      case first_non_pad(tail, from) {
        Ok(Nil) -> next()
        Error(offset) -> Error(InvalidCharacter("=", offset - 1))
      }
    Error(Nil) -> next()
  }
}

fn first_non_pad(bytes: BitArray, offset: Int) -> Result(Nil, Int) {
  case bytes {
    <<byte, rest:bytes>> if byte == pad -> first_non_pad(rest, offset + 1)
    <<_, _:bytes>> -> Error(offset)
    _ -> Ok(Nil)
  }
}

fn take(bytes: BitArray, count: Int) -> BitArray {
  case bit_array.slice(bytes, 0, count) {
    Ok(head) -> head
    Error(Nil) -> bytes
  }
}

/// Turn validated symbol bytes back into data bytes. Bits left over after
/// the last whole byte are dropped.
fn unpack(bytes: BitArray, bits: Int, alphabet: Alphabet) -> BitArray {
  unpack_loop(bytes, bits, alphabet, 0, 0, [])
}

fn unpack_loop(
  bytes: BitArray,
  bits: Int,
  alphabet: Alphabet,
  buffer: Int,
  buffered: Int,
  acc: List(BitArray),
) -> BitArray {
  case buffered >= 8, bytes {
    True, _ -> {
      let shift = buffered - 8
      let byte = int.bitwise_shift_right(buffer, shift)
      let rest = buffer - int.bitwise_shift_left(byte, shift)
      unpack_loop(bytes, bits, alphabet, rest, shift, [<<byte>>, ..acc])
    }
    False, <<symbol, bytes:bytes>> -> {
      let value = case alphabet.lookup(alphabet, symbol) {
        alphabet.Value(value) -> value
        // Callers validate the input first.
        alphabet.Ignored | alphabet.Invalid -> 0
      }
      unpack_loop(
        bytes,
        bits,
        alphabet,
        int.bitwise_shift_left(buffer, bits) + value,
        buffered + bits,
        acc,
      )
    }
    False, _ -> bit_array.concat(list.reverse(acc))
  }
}
