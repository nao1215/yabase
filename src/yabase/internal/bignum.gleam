//// Radix conversion for the codecs that treat their input as one big
//// number (Base8, Base10, Base36, Base58, Base62, Crockford Base32).
////
//// The number is held as a list of limbs, least significant first, and
//// converted with multiply-and-carry like Bitcoin Core's base58 code. Every
//// intermediate value stays below 2^53, so the result is the same on Erlang
//// and JavaScript.
////
//// Leading zeros: encode maps each leading 0x00 byte to the alphabet's
//// zero symbol and decode maps each leading zero symbol back to a 0x00
//// byte, so byte arrays round-trip, not just their numeric value.

import gleam/bit_array
import gleam/bool
import gleam/list
import yabase/core/error.{type CodecError}
import yabase/internal/alphabet.{type Alphabet}

/// Limbs of the output side of an encode are `radix^digits_per_limb`,
/// kept below 2^36 so that `limb * 65_536 + carry` stays below 2^53.
const limb_ceiling = 68_719_476_736

/// Decoded bytes are gathered in limbs of two bytes.
const byte_limb = 65_536

/// Encode `data` as a number written in `alphabet`.
pub fn encode(data: BitArray, alphabet: Alphabet) -> String {
  let radix = alphabet.size(alphabet)
  let #(zeros, rest) = split_leading_zero_bytes(data, 0)
  let #(digits_per_limb, limb_base) = limb_shape(radix, 1, radix)
  let limbs = bytes_to_limbs(rest, limb_base, [])
  let digits = limbs_to_digits(limbs, radix, digits_per_limb, [])
  let zero = alphabet.symbol(alphabet, 0)
  list.append(
    list.repeat(zero, zeros),
    list.map(digits, alphabet.symbol(alphabet, _)),
  )
  |> alphabet.to_string
}

/// Decode a number written in `alphabet` back to bytes.
pub fn decode(
  input: String,
  alphabet: Alphabet,
) -> Result(BitArray, CodecError) {
  let bytes = bit_array.from_string(input)
  case read_digits(bytes, bytes, alphabet, 0, 0, []) {
    Error(error) -> Error(error)
    Ok(digits) -> {
      let radix = alphabet.size(alphabet)
      let #(zeros, rest) = split_leading_zero_digits(digits, 0)
      let #(digits_per_limb, _) = limb_shape(radix, 1, radix)
      let limbs = digits_to_limbs(rest, radix, digits_per_limb, [])
      Ok(
        bit_array.concat([
          zero_bytes(zeros),
          limbs_to_bytes(limbs, []),
        ]),
      )
    }
  }
}

/// The remainder of `data`, read as a big-endian number, divided by
/// `divisor`.
pub fn remainder(data: BitArray, divisor: Int) -> Int {
  remainder_loop(data, divisor, 0)
}

fn remainder_loop(data: BitArray, divisor: Int, acc: Int) -> Int {
  case data {
    <<byte, rest:bytes>> ->
      remainder_loop(rest, divisor, { acc * 256 + byte } % divisor)
    _ -> acc
  }
}

/// The largest `digits` with `radix^digits` below `limb_ceiling`, and that
/// power.
fn limb_shape(radix: Int, digits: Int, power: Int) -> #(Int, Int) {
  use <- bool.guard(when: power * radix >= limb_ceiling, return: #(
    digits,
    power,
  ))
  limb_shape(radix, digits + 1, power * radix)
}

fn split_leading_zero_bytes(data: BitArray, count: Int) -> #(Int, BitArray) {
  case data {
    <<0, rest:bytes>> -> split_leading_zero_bytes(rest, count + 1)
    _ -> #(count, data)
  }
}

fn split_leading_zero_digits(
  digits: List(Int),
  count: Int,
) -> #(Int, List(Int)) {
  case digits {
    [0, ..rest] -> split_leading_zero_digits(rest, count + 1)
    _ -> #(count, digits)
  }
}

/// Read the input bytes into digit values, most significant first.
fn read_digits(
  input: BitArray,
  rest: BitArray,
  alphabet: Alphabet,
  offset: Int,
  position: Int,
  acc: List(Int),
) -> Result(List(Int), CodecError) {
  case rest {
    <<byte, rest:bytes>> ->
      case alphabet.lookup(alphabet, byte) {
        alphabet.Value(value) ->
          read_digits(input, rest, alphabet, offset + 1, position + 1, [
            value,
            ..acc
          ])
        alphabet.Ignored ->
          read_digits(input, rest, alphabet, offset + 1, position, acc)
        alphabet.Invalid ->
          Error(alphabet.invalid_character(alphabet, input, offset, position))
      }
    _ -> Ok(list.reverse(acc))
  }
}

/// Fold big-endian bytes, two at a time, into limbs of `limb_base`.
fn bytes_to_limbs(
  data: BitArray,
  limb_base: Int,
  limbs: List(Int),
) -> List(Int) {
  case data {
    <<pair:16, rest:bytes>> ->
      bytes_to_limbs(
        rest,
        limb_base,
        multiply_add(limbs, byte_limb, pair, limb_base, []),
      )
    <<byte>> -> multiply_add(limbs, 256, byte, limb_base, [])
    _ -> limbs
  }
}

/// Fold digits, `digits_per_limb` at a time, into limbs of two bytes.
fn digits_to_limbs(
  digits: List(Int),
  radix: Int,
  digits_per_limb: Int,
  limbs: List(Int),
) -> List(Int) {
  case digits {
    [] -> limbs
    _ -> {
      let #(value, factor, rest) =
        take_digits(digits, radix, digits_per_limb, 0, 1)
      digits_to_limbs(
        rest,
        radix,
        digits_per_limb,
        multiply_add(limbs, factor, value, byte_limb, []),
      )
    }
  }
}

fn take_digits(
  digits: List(Int),
  radix: Int,
  count: Int,
  value: Int,
  factor: Int,
) -> #(Int, Int, List(Int)) {
  case count, digits {
    0, _ | _, [] -> #(value, factor, digits)
    _, [digit, ..rest] ->
      take_digits(rest, radix, count - 1, value * radix + digit, factor * radix)
  }
}

/// `limbs * factor + carry`, with limbs least significant first. The
/// result is least significant first too.
fn multiply_add(
  limbs: List(Int),
  factor: Int,
  carry: Int,
  base: Int,
  acc: List(Int),
) -> List(Int) {
  case limbs {
    [limb, ..rest] -> {
      let value = limb * factor + carry
      multiply_add(rest, factor, value / base, base, [value % base, ..acc])
    }
    [] -> list.reverse(push_carry(carry, base, acc))
  }
}

fn push_carry(carry: Int, base: Int, acc: List(Int)) -> List(Int) {
  case carry {
    0 -> acc
    _ -> push_carry(carry / base, base, [carry % base, ..acc])
  }
}

/// Write limbs (least significant first) as digits, most significant
/// first, without leading zero digits.
fn limbs_to_digits(
  limbs: List(Int),
  radix: Int,
  digits_per_limb: Int,
  acc: List(Int),
) -> List(Int) {
  case limbs {
    [] -> acc
    [top] -> limb_digits(top, radix, -1, acc)
    [limb, ..rest] ->
      limbs_to_digits(
        rest,
        radix,
        digits_per_limb,
        limb_digits(limb, radix, digits_per_limb, acc),
      )
  }
}

/// Digits of one limb, most significant first. A negative `count` writes
/// as many digits as the value needs.
fn limb_digits(limb: Int, radix: Int, count: Int, acc: List(Int)) -> List(Int) {
  case count, limb {
    0, _ -> acc
    _, 0 if count < 0 -> acc
    _, _ -> limb_digits(limb / radix, radix, count - 1, [limb % radix, ..acc])
  }
}

/// Write two-byte limbs (least significant first) as big-endian bytes
/// without a leading zero byte.
fn limbs_to_bytes(limbs: List(Int), acc: List(BitArray)) -> BitArray {
  case limbs {
    [] -> bit_array.concat(acc)
    [top] if top < 256 -> bit_array.concat([<<top>>, ..acc])
    [limb, ..rest] -> limbs_to_bytes(rest, [<<limb:16>>, ..acc])
  }
}

fn zero_bytes(count: Int) -> BitArray {
  bit_array.concat(list.repeat(<<0>>, count))
}
