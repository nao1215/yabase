//// The Base85 family: Z85, the RFC 1924 alphabet in 4-byte groups, btoa
//// Ascii85 and Adobe Ascii85. Every flavour writes a 4-byte group as five
//// base-85 digits; they differ in the alphabet, the shortcuts and how a
//// short final group and whitespace are handled.

import gleam/bit_array
import gleam/bool
import gleam/list
import gleam/result
import yabase/core/error.{type CodecError, InvalidLength, Overflow}
import yabase/internal/alphabet.{type Alphabet}

const max_u32 = 4_294_967_295

const ascii85_symbols =
  "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstu"

/// The Ascii85 alphabet: the characters `!` (33) to `u` (117).
pub fn ascii85_alphabet() -> Alphabet {
  alphabet.new(ascii85_symbols, alphabet.CaseSensitive)
}

/// Which group shortcuts an encoder emits and a decoder accepts.
pub type Shortcuts {
  /// No shortcuts (Z85, RFC 1924).
  NoShortcuts
  /// `z` for four zero bytes (Adobe).
  ZeroShortcut
  /// `z` for four zero bytes and `y` for four spaces (btoa).
  ZeroAndSpaceShortcuts
}

/// Encode `data`. A final group of 1 to 3 bytes is padded with zeros and
/// written as one more character than it has bytes.
pub fn encode(
  data: BitArray,
  alphabet: Alphabet,
  shortcuts: Shortcuts,
) -> String {
  encode_loop(data, alphabet, shortcuts, [])
}

fn encode_loop(
  data: BitArray,
  alphabet: Alphabet,
  shortcuts: Shortcuts,
  acc: List(BitArray),
) -> String {
  case data, shortcuts {
    <<0:32, rest:bytes>>, ZeroShortcut
    | <<0:32, rest:bytes>>, ZeroAndSpaceShortcuts
    -> encode_loop(rest, alphabet, shortcuts, [<<"z":utf8>>, ..acc])
    <<0x20202020:32, rest:bytes>>, ZeroAndSpaceShortcuts ->
      encode_loop(rest, alphabet, shortcuts, [<<"y":utf8>>, ..acc])
    <<value:32, rest:bytes>>, _ ->
      encode_loop(rest, alphabet, shortcuts, [
        group_symbols(value, alphabet, 5),
        ..acc
      ])
    <<>>, _ -> alphabet.chunks_to_string(list.reverse(acc))
    _, _ -> {
      let count = bit_array.byte_size(data)
      let value = tail_value(data, 0, 4 - count)
      alphabet.chunks_to_string(
        list.reverse([group_symbols(value, alphabet, count + 1), ..acc]),
      )
    }
  }
}

/// The value of a final group of 1 to 3 bytes padded with `padding` zero
/// bytes.
fn tail_value(data: BitArray, value: Int, padding: Int) -> Int {
  case data, padding {
    <<byte, rest:bytes>>, _ -> tail_value(rest, value * 256 + byte, padding)
    _, 0 -> value
    _, _ -> tail_value(data, value * 256, padding - 1)
  }
}

/// The first `count` of the five digits of `value`, as symbol bytes.
fn group_symbols(value: Int, alphabet: Alphabet, count: Int) -> BitArray {
  let digits = [
    value / 52_200_625 % 85,
    value / 614_125 % 85,
    value / 7225 % 85,
    value / 85 % 85,
    value % 85,
  ]
  list.take(digits, count)
  |> list.map(fn(digit) { <<{ alphabet.symbol(alphabet, digit) }>> })
  |> bit_array.concat
}

/// Decode Z85 or RFC 1924 text: no whitespace, no shortcuts, and the length
/// must be a multiple of five characters. The length is checked first.
pub fn decode_groups(
  input: String,
  alphabet: Alphabet,
) -> Result(BitArray, CodecError) {
  let bytes = bit_array.from_string(input)
  let length = alphabet.character_count(input, bytes)
  use <- bool.guard(when: length % 5 != 0, return: Error(InvalidLength(length)))
  decode_groups_loop(bytes, bytes, alphabet, 0, [])
}

fn decode_groups_loop(
  input: BitArray,
  rest: BitArray,
  alphabet: Alphabet,
  offset: Int,
  acc: List(BitArray),
) -> Result(BitArray, CodecError) {
  case rest {
    <<a, b, c, d, e, rest:bytes>> ->
      case group_value([a, b, c, d, e], alphabet, 0, offset) {
        Ok(value) if value > max_u32 -> Error(Overflow)
        Ok(value) ->
          decode_groups_loop(input, rest, alphabet, offset + 5, [
            <<value:32>>,
            ..acc
          ])
        Error(bad) ->
          Error(alphabet.invalid_character(alphabet, input, bad, bad))
      }
    <<>> -> Ok(bit_array.concat(list.reverse(acc)))
    _ -> Error(alphabet.invalid_character(alphabet, input, offset, offset))
  }
}

/// The value of a group of digits, or the offset of the first byte that is
/// not a symbol.
fn group_value(
  group: List(Int),
  alphabet: Alphabet,
  value: Int,
  offset: Int,
) -> Result(Int, Int) {
  case group {
    [] -> Ok(value)
    [byte, ..rest] ->
      case alphabet.lookup(alphabet, byte) {
        alphabet.Value(digit) ->
          group_value(rest, alphabet, value * 85 + digit, offset + 1)
        alphabet.Ignored | alphabet.Invalid -> Error(offset)
      }
  }
}

/// Decode Ascii85 text. Space, tab, CR, LF and form feed are skipped and
/// count as one position each (CR LF counts as one). A final group needs at
/// least two characters. `position` is the position of the first byte of
/// `input`, so errors can be reported against the caller's string.
pub fn decode_ascii85(
  input: String,
  shortcuts: Shortcuts,
  position: Int,
) -> Result(BitArray, CodecError) {
  let bytes = bit_array.from_string(input)
  ascii85_loop(
    Reader(input: bytes, alphabet: ascii85_alphabet(), shortcuts:),
    bytes,
    0,
    position,
    [],
    [],
  )
}

type Reader {
  Reader(input: BitArray, alphabet: Alphabet, shortcuts: Shortcuts)
}

fn ascii85_loop(
  reader: Reader,
  rest: BitArray,
  offset: Int,
  position: Int,
  group: List(Int),
  acc: List(BitArray),
) -> Result(BitArray, CodecError) {
  case rest, group {
    <<13, 10, rest:bytes>>, _ ->
      ascii85_loop(reader, rest, offset + 2, position + 1, group, acc)
    <<byte, rest:bytes>>, _
      if byte == 32 || byte == 9 || byte == 10 || byte == 13 || byte == 12
    -> ascii85_loop(reader, rest, offset + 1, position + 1, group, acc)
    <<"z":utf8, rest:bytes>>, [] if reader.shortcuts != NoShortcuts ->
      ascii85_loop(reader, rest, offset + 1, position + 1, [], [<<0:32>>, ..acc])
    <<"y":utf8, rest:bytes>>, [] if reader.shortcuts == ZeroAndSpaceShortcuts ->
      ascii85_loop(reader, rest, offset + 1, position + 1, [], [
        <<0x20202020:32>>,
        ..acc
      ])
    <<byte, rest:bytes>>, _ ->
      case alphabet.lookup(reader.alphabet, byte) {
        alphabet.Value(digit) ->
          case push_digit([digit, ..group], acc) {
            Ok(#(group, acc)) ->
              ascii85_loop(reader, rest, offset + 1, position + 1, group, acc)
            Error(error) -> Error(error)
          }
        alphabet.Ignored | alphabet.Invalid ->
          Error(alphabet.invalid_character(
            reader.alphabet,
            reader.input,
            offset,
            position,
          ))
      }
    _, [] -> Ok(bit_array.concat(list.reverse(acc)))
    _, [_] -> Error(InvalidLength(position))
    _, _ ->
      case finish_group(group) {
        Ok(chunk) -> Ok(bit_array.concat(list.reverse([chunk, ..acc])))
        Error(error) -> Error(error)
      }
  }
}

/// Add a digit to the current group, flushing the group once it has five.
fn push_digit(
  group: List(Int),
  acc: List(BitArray),
) -> Result(#(List(Int), List(BitArray)), CodecError) {
  case list.length(group) {
    5 -> result.map(finish_group(group), fn(chunk) { #([], [chunk, ..acc]) })
    _ -> Ok(#(group, acc))
  }
}

/// Turn a group of 2 to 5 digits (most recent first) into bytes. A short
/// group is padded with `u` (84) and yields one byte fewer than its digits.
fn finish_group(group: List(Int)) -> Result(BitArray, CodecError) {
  let count = list.length(group)
  let digits = list.append(list.reverse(group), list.repeat(84, 5 - count))
  let value = list.fold(digits, 0, fn(value, digit) { value * 85 + digit })
  use <- bool.guard(when: value > max_u32, return: Error(Overflow))
  bit_array.slice(<<value:32>>, 0, count - 1)
  |> result.replace_error(InvalidLength(count))
}
