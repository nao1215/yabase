/// Bech32 and Bech32m byte-payload encoding (BIP 173, BIP 350).
///
/// This module provides a convenience API that accepts raw bytes,
/// converts them to 5-bit groups internally (8-to-5 bit conversion),
/// computes the polynomial checksum, and produces the final
/// HRP + "1" + data + checksum string. Decoding reverses the process
/// (5-to-8 bit conversion) and returns bytes.
///
/// This is NOT a raw 5-bit framing API. If you need to work with
/// pre-converted 5-bit values (e.g. for SegWit witness programs
/// where the witness version is a separate 5-bit value), you will
/// need a separate raw 5-bit framing API; this module always converts bytes.
///
/// It does NOT implement SegWit address validation (witness version,
/// program length constraints).
///
/// This is a separate API from the Encoding ADT because it carries
/// HRP metadata and a checksum.
import gleam/bit_array
import gleam/bool
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import yabase/core/error.{
  type Bech32Decoded, type Bech32Variant, type CodecError, Bech32 as Bech32V,
  Bech32Decoded, Bech32m as Bech32mV, InvalidCharacter, InvalidChecksum,
  InvalidHrp, InvalidLength,
}

import yabase/internal/alphabet
import yabase/internal/bitgroup

const charset = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"

const bech32_const = 1

const bech32m_const = 0x2bc830a3

/// Encode byte data with Bech32 or Bech32m.
/// variant: Bech32 (BIP 173) or Bech32m (BIP 350).
/// hrp: human-readable part (e.g. `"bc"` for Bitcoin mainnet). Must be
///   all lowercase per BIP 173 — uppercase characters are rejected with
///   `Error(InvalidHrp("HRP must be lowercase"))` rather than silently
///   normalized, so the input is never quietly mutated. Lowercase the
///   value at the call site if you started from a mixed-case identifier.
/// data: raw bytes (8-to-5 bit conversion is done internally). Input that
///   is not a whole number of bytes is rejected with
///   `Error(InvalidLength(bit_size))`.
pub fn encode(
  variant: Bech32Variant,
  hrp: String,
  data: BitArray,
) -> Result(String, CodecError) {
  encode_variant(variant, hrp, data)
}

/// Encode byte data with the recommended default variant (Bech32m,
/// BIP 350) for callers that don't need to distinguish BIP 173 from
/// BIP 350.
///
/// Issue #21: Bitcoin / SegWit tooling has a load-bearing reason to
/// pick `Bech32` (BIP 173) over `Bech32m` (BIP 350) — witness version
/// 0 must use BIP 173, witness version 1+ must use BIP 350. Outside
/// that one use case, every other `bech32`-shaped use (short
/// human-readable IDs with a custom HRP, copy-pasteable application
/// tokens, etc.) is better served by the strict-checksum BIP 350
/// variant. This helper picks `Bech32m` so application authors who
/// just want "give me a short, error-resistant ID with my HRP"
/// don't have to decide which BIP they're targeting.
///
/// Use the variant-explicit `encode/3` if you actually need
/// `Bech32` (BIP 173) for a byte payload. SegWit witness-program addresses
/// require a separate raw 5-bit framing API.
pub fn encode_default(
  hrp: String,
  data: BitArray,
) -> Result(String, CodecError) {
  encode_variant(Bech32mV, hrp, data)
}

/// Decode a Bech32 or Bech32m string, auto-detecting the variant.
/// Per BIP 173: total length <= 90, HRP length 1..83.
pub fn decode(input: String) -> Result(Bech32Decoded, CodecError) {
  let total_length = string.length(input)
  use <- bool.guard(
    when: total_length > 90,
    return: Error(InvalidLength(total_length)),
  )
  use Nil <- result.try(validate_ascii(bit_array.from_string(input), 0))
  let lower = string.lowercase(input)
  use <- bool.guard(
    when: input != lower && input != string.uppercase(input),
    return: Error(InvalidCharacter("mixed-case", 0)),
  )
  // Split on the last separator, since the HRP may itself contain '1'.
  case list.reverse(string.split(lower, "1")) {
    [] | [_] -> Error(InvalidHrp("no separator '1' found"))
    [data_part, ..hrp_parts] -> {
      let hrp = hrp_parts |> list.reverse |> string.join("1")
      use Nil <- result.try(check_hrp(hrp))
      decode_data_part(hrp, data_part)
    }
  }
}

fn validate_ascii(input: BitArray, position: Int) -> Result(Nil, CodecError) {
  case input {
    <<byte, rest:bytes>> if byte < 128 -> validate_ascii(rest, position + 1)
    <<>> -> Ok(Nil)
    _ -> {
      let character = case
        bit_array.to_string(input) |> result.try(string.pop_grapheme)
      {
        Ok(#(character, _)) -> character
        Error(Nil) -> ""
      }
      Error(InvalidCharacter(character, position))
    }
  }
}

fn check_hrp(hrp: String) -> Result(Nil, CodecError) {
  let length = string.length(hrp)
  use <- bool.guard(when: length < 1, return: Error(InvalidHrp("empty HRP")))
  use <- bool.guard(
    when: length > 83,
    return: Error(InvalidHrp("HRP too long")),
  )
  validate_hrp(hrp, 0)
}

fn validate_hrp(hrp: String, position: Int) -> Result(Nil, CodecError) {
  case string.pop_grapheme(hrp) {
    Error(Nil) -> Ok(Nil)
    Ok(#(character, rest)) -> {
      case string.to_utf_codepoints(character) {
        [codepoint] -> {
          let code = string.utf_codepoint_to_int(codepoint)
          case code >= 33 && code <= 126 {
            True -> validate_hrp(rest, position + 1)
            False ->
              Error(InvalidHrp(
                "character out of range at " <> int.to_string(position),
              ))
          }
        }
        _ -> Error(InvalidHrp("invalid character"))
      }
    }
  }
}

fn encode_variant(
  variant: Bech32Variant,
  hrp: String,
  data: BitArray,
) -> Result(String, CodecError) {
  use <- bool.guard(
    when: hrp != string.lowercase(hrp),
    return: Error(InvalidHrp("HRP must be lowercase")),
  )
  use Nil <- result.try(check_hrp(hrp))
  let bits = bit_array.bit_size(data)
  use <- bool.guard(when: bits % 8 != 0, return: Error(InvalidLength(bits)))
  let length = string.length(hrp) + 7 + { bits + 4 } / 5
  use <- bool.guard(when: length > 90, return: Error(InvalidLength(length)))
  let table = alphabet.new(charset, alphabet.CaseSensitive)
  let payload = bitgroup.encode(data, 5, table, bitgroup.Unpadded)
  use values <- result.try(chars_to_values(
    bit_array.from_string(payload),
    table,
    [],
    0,
  ))
  let constant = case variant {
    Bech32V -> bech32_const
    Bech32mV -> bech32m_const
  }
  let checksum = create_checksum(hrp, values, constant)
  Ok(hrp <> "1" <> payload <> values_to_chars(checksum, table))
}

fn decode_data_part(
  hrp: String,
  data_part: String,
) -> Result(Bech32Decoded, CodecError) {
  let length = string.length(data_part)
  use <- bool.guard(when: length < 6, return: Error(InvalidLength(length)))
  let table = alphabet.new(charset, alphabet.CaseSensitive)
  use values <- result.try(chars_to_values(
    bit_array.from_string(data_part),
    table,
    [],
    0,
  ))
  let checksum = polymod(list.append(hrp_expand(hrp), values))
  let variant = case checksum {
    _ if checksum == bech32_const -> Ok(Bech32V)
    _ if checksum == bech32m_const -> Ok(Bech32mV)
    _ -> Error(InvalidChecksum)
  }
  use variant <- result.try(variant)
  let data_values = list.take(values, length - 6)
  let leftover = { length - 6 } * 5 % 8
  use <- bool.guard(
    when: leftover > 4,
    return: Error(InvalidLength(length - 6)),
  )
  let last = case list.last(data_values) {
    Ok(value) -> value
    Error(Nil) -> 0
  }
  use <- bool.guard(
    when: last % int.bitwise_shift_left(1, leftover) != 0,
    return: Error(InvalidCharacter("non-zero padding", 0)),
  )
  use bytes <- result.map(bitgroup.decode_unpadded(
    values_to_chars(data_values, table),
    5,
    table,
  ))
  Bech32Decoded(hrp:, data: bytes, variant:)
}

fn chars_to_values(
  input: BitArray,
  table: alphabet.Alphabet,
  values: List(Int),
  position: Int,
) -> Result(List(Int), CodecError) {
  case input {
    <<byte, rest:bytes>> ->
      case alphabet.lookup(table, byte) {
        alphabet.Value(value) ->
          chars_to_values(rest, table, [value, ..values], position + 1)
        alphabet.Invalid | alphabet.Ignored ->
          Error(InvalidCharacter(alphabet.to_string([byte]), position))
      }
    _ -> Ok(list.reverse(values))
  }
}

fn values_to_chars(values: List(Int), table: alphabet.Alphabet) -> String {
  values |> list.map(alphabet.symbol(table, _)) |> alphabet.to_string
}

fn polymod(values: List(Int)) -> Int {
  list.fold(values, 1, fn(checksum, value) {
    let head = int.bitwise_shift_right(checksum, 25)
    let checksum =
      int.bitwise_exclusive_or({ checksum % 33_554_432 } * 32, value)
    checksum
    |> xor_if(head, 0, 0x3b6a57b2)
    |> xor_if(head, 1, 0x26508e6d)
    |> xor_if(head, 2, 0x1ea119fa)
    |> xor_if(head, 3, 0x3d4233dd)
    |> xor_if(head, 4, 0x2a1462b3)
  })
}

fn xor_if(checksum: Int, head: Int, bit: Int, generator: Int) -> Int {
  case int.bitwise_and(int.bitwise_shift_right(head, bit), 1) {
    1 -> int.bitwise_exclusive_or(checksum, generator)
    _ -> checksum
  }
}

fn hrp_expand(hrp: String) -> List(Int) {
  let codes =
    hrp |> string.to_utf_codepoints |> list.map(string.utf_codepoint_to_int)
  let high = list.map(codes, fn(code) { code / 32 })
  let low = list.map(codes, fn(code) { code % 32 })
  list.append(high, [0, ..low])
}

fn create_checksum(hrp: String, data: List(Int), constant: Int) -> List(Int) {
  let values =
    list.append(hrp_expand(hrp), list.append(data, [0, 0, 0, 0, 0, 0]))
  let checksum = int.bitwise_exclusive_or(polymod(values), constant)
  list.map([25, 20, 15, 10, 5, 0], fn(shift) {
    int.bitwise_and(int.bitwise_shift_right(checksum, shift), 31)
  })
}
