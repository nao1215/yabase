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
/// need to handle the bit conversion yourself before calling this module.
///
/// It does NOT implement SegWit address validation (witness version,
/// program length constraints).
///
/// This is a separate API from the Encoding ADT because it carries
/// HRP metadata and a checksum.
import gleam/bit_array
import gleam/list
import gleam/string
import yabase/core/encoding.{
  type Bech32Decoded, type Bech32Variant, type CodecError, Bech32 as Bech32V,
  Bech32Decoded, Bech32m as Bech32mV, InvalidCharacter, InvalidChecksum,
  InvalidHrp, InvalidLength,
}

const charset = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"

const bech32_const = 1

const bech32m_const = 0x2bc830a3

/// Encode byte data with Bech32 (BIP 173).
/// hrp: human-readable part (e.g. "bc" for Bitcoin mainnet).
/// data: raw bytes (8-to-5 bit conversion is done internally).
pub fn encode(hrp: String, data: BitArray) -> Result(String, CodecError) {
  encode_variant(Bech32V, hrp, data)
}

/// Encode data with Bech32m (BIP 350).
pub fn encode_m(hrp: String, data: BitArray) -> Result(String, CodecError) {
  encode_variant(Bech32mV, hrp, data)
}

/// Decode a Bech32 or Bech32m string, auto-detecting the variant.
/// Per BIP 173: total length <= 90, HRP length 1..83.
pub fn decode(input: String) -> Result(Bech32Decoded, CodecError) {
  let total_len = string.length(input)
  case total_len > 90 {
    True -> Error(InvalidLength(total_len))
    False -> {
      let lower = string.lowercase(input)
      let upper = string.uppercase(input)
      // Reject mixed case
      case input != lower && input != upper {
        True -> Error(InvalidCharacter("mixed-case", 0))
        False -> {
          let work = lower
          case find_separator(work) {
            Error(Nil) -> Error(InvalidHrp("no separator '1' found"))
            Ok(#(hrp, data_part)) -> {
              let hrp_len = string.length(hrp)
              case hrp_len < 1 {
                True -> Error(InvalidHrp("empty HRP"))
                False ->
                  case hrp_len > 83 {
                    True -> Error(InvalidHrp("HRP too long"))
                    False ->
                      case validate_hrp(hrp, 0) {
                        Error(e) -> Error(e)
                        Ok(Nil) -> decode_data_part(hrp, data_part)
                      }
                  }
              }
            }
          }
        }
      }
    }
  }
}

fn encode_variant(
  variant: Bech32Variant,
  hrp: String,
  data: BitArray,
) -> Result(String, CodecError) {
  let lower_hrp = string.lowercase(hrp)
  let hrp_len = string.length(lower_hrp)
  case hrp_len < 1 {
    True -> Error(InvalidHrp("empty HRP"))
    False ->
      case hrp_len > 83 {
        True -> Error(InvalidHrp("HRP too long"))
        False ->
          case validate_hrp(lower_hrp, 0) {
            Error(e) -> Error(e)
            Ok(Nil) -> {
              let data_values = bytes_to_5bit_groups(data)
              let checksum_const = case variant {
                Bech32V -> bech32_const
                Bech32mV -> bech32m_const
              }
              let checksum =
                create_checksum(lower_hrp, data_values, checksum_const)
              let all_values = list_append(data_values, checksum)
              let encoded_data = values_to_chars(all_values, "")
              let result = lower_hrp <> "1" <> encoded_data
              // BIP 173: total length must not exceed 90
              case string.length(result) > 90 {
                True -> Error(InvalidLength(string.length(result)))
                False -> Ok(result)
              }
            }
          }
      }
  }
}

fn validate_hrp(hrp: String, pos: Int) -> Result(Nil, CodecError) {
  case string.pop_grapheme(hrp) {
    Error(Nil) -> Ok(Nil)
    Ok(#(c, rest)) -> {
      case string.to_utf_codepoints(c) {
        [cp] -> {
          let code = string.utf_codepoint_to_int(cp)
          case code >= 33 && code <= 126 {
            True -> validate_hrp(rest, pos + 1)
            False ->
              Error(InvalidHrp(
                "character out of range at " <> int_to_string(pos),
              ))
          }
        }
        _ -> Error(InvalidHrp("invalid character"))
      }
    }
  }
}

fn find_separator(input: String) -> Result(#(String, String), Nil) {
  // Find the last occurrence of "1"
  find_last_one(input, string.length(input) - 1)
}

fn find_last_one(input: String, pos: Int) -> Result(#(String, String), Nil) {
  case pos < 0 {
    True -> Error(Nil)
    False -> {
      let before = string.slice(input, 0, pos)
      let at_and_after = string.drop_start(input, pos)
      case string.pop_grapheme(at_and_after) {
        Ok(#("1", after)) -> Ok(#(before, after))
        _ -> find_last_one(input, pos - 1)
      }
    }
  }
}

fn decode_data_part(
  hrp: String,
  data_part: String,
) -> Result(Bech32Decoded, CodecError) {
  let len = string.length(data_part)
  case len < 6 {
    True -> Error(InvalidLength(len))
    False ->
      case chars_to_values(data_part, [], 0) {
        Error(e) -> Error(e)
        Ok(all_values) -> {
          let data_len = list.length(all_values) - 6
          let data_values = list_take(all_values, data_len)
          // Try Bech32 first, then Bech32m
          case verify_checksum(hrp, all_values, bech32_const) {
            True ->
              case convert_5bit_to_8bit(data_values) {
                Error(e) -> Error(e)
                Ok(data_bytes) ->
                  Ok(Bech32Decoded(
                    hrp: hrp,
                    data: list_to_bit_array(data_bytes, <<>>),
                    variant: Bech32V,
                  ))
              }
            False ->
              case verify_checksum(hrp, all_values, bech32m_const) {
                True ->
                  case convert_5bit_to_8bit(data_values) {
                    Error(e) -> Error(e)
                    Ok(data_bytes) ->
                      Ok(Bech32Decoded(
                        hrp: hrp,
                        data: list_to_bit_array(data_bytes, <<>>),
                        variant: Bech32mV,
                      ))
                  }
                False -> Error(InvalidChecksum)
              }
          }
        }
      }
  }
}

fn chars_to_values(
  input: String,
  acc: List(Int),
  pos: Int,
) -> Result(List(Int), CodecError) {
  case string.pop_grapheme(input) {
    Error(Nil) -> Ok(list_reverse(acc))
    Ok(#(c, rest)) ->
      case char_to_value(c) {
        Error(_) -> Error(InvalidCharacter(c, pos))
        Ok(v) -> chars_to_values(rest, [v, ..acc], pos + 1)
      }
  }
}

fn values_to_chars(values: List(Int), acc: String) -> String {
  case values {
    [] -> acc
    [v, ..rest] -> values_to_chars(rest, acc <> string_char_at(charset, v))
  }
}

// Bech32 polymod
fn polymod(values: List(Int)) -> Int {
  polymod_loop(values, 1)
}

fn polymod_loop(values: List(Int), chk: Int) -> Int {
  case values {
    [] -> chk
    [v, ..rest] -> {
      // b = chk >> 25
      let b = shr(chk, 25)
      // chk = ((chk & 0x1ffffff) << 5) ^ v
      let chk1 = xor({ chk % 33_554_432 } * 32, v)
      let chk2 = xor_if(chk1, b, 0, 0x3b6a57b2)
      let chk3 = xor_if(chk2, b, 1, 0x26508e6d)
      let chk4 = xor_if(chk3, b, 2, 0x1ea119fa)
      let chk5 = xor_if(chk4, b, 3, 0x3d4233dd)
      let chk6 = xor_if(chk5, b, 4, 0x2a1462b3)
      polymod_loop(rest, chk6)
    }
  }
}

fn xor_if(chk: Int, b: Int, bit: Int, gen: Int) -> Int {
  let shifted = shr(b, bit)
  case shifted % 2 == 1 {
    True -> xor(chk, gen)
    False -> chk
  }
}

fn hrp_expand(hrp: String) -> List(Int) {
  let chars = string.to_graphemes(hrp)
  let high = list.map(chars, fn(c) { char_code(c) / 32 })
  let low = list.map(chars, fn(c) { char_code(c) % 32 })
  list_append(list_append(high, [0]), low)
}

fn char_code(c: String) -> Int {
  case string.to_utf_codepoints(c) {
    [cp] -> string.utf_codepoint_to_int(cp)
    _ -> 0
  }
}

fn verify_checksum(hrp: String, data: List(Int), constant: Int) -> Bool {
  let values = list_append(hrp_expand(hrp), data)
  polymod(values) == constant
}

fn create_checksum(hrp: String, data: List(Int), constant: Int) -> List(Int) {
  let values =
    list_append(hrp_expand(hrp), list_append(data, [0, 0, 0, 0, 0, 0]))
  let p = xor(polymod(values), constant)
  [
    shr(p, 25) % 32,
    shr(p, 20) % 32,
    shr(p, 15) % 32,
    shr(p, 10) % 32,
    shr(p, 5) % 32,
    p % 32,
  ]
}

// Convert 8-bit bytes to 5-bit groups
fn bytes_to_5bit_groups(data: BitArray) -> List(Int) {
  convert_bits(data, [])
}

fn convert_bits(data: BitArray, acc: List(Int)) -> List(Int) {
  case data {
    <<group:5, rest:bits>> -> convert_bits(rest, [group, ..acc])
    <<remaining:4>> -> list_reverse([remaining * 2, ..acc])
    <<remaining:3>> -> list_reverse([remaining * 4, ..acc])
    <<remaining:2>> -> list_reverse([remaining * 8, ..acc])
    <<remaining:1>> -> list_reverse([remaining * 16, ..acc])
    _ -> list_reverse(acc)
  }
}

/// Convert 5-bit groups to 8-bit bytes (BIP 173 convertbits, pad=false).
/// Validates that:
/// - There are at most 4 leftover bits
/// - All leftover bits are zero
fn convert_5bit_to_8bit(groups: List(Int)) -> Result(List(Int), CodecError) {
  let total_bits = list.length(groups) * 5
  let leftover_bits = total_bits % 8
  // More than 4 leftover bits means invalid encoding
  case leftover_bits > 4 {
    True -> Error(InvalidLength(list.length(groups)))
    False -> {
      let bits = groups_to_bit_array(groups, <<>>)
      // Check that leftover padding bits are all zero
      case validate_padding_bits(bits, leftover_bits) {
        False -> Error(InvalidCharacter("non-zero padding", 0))
        True -> Ok(extract_bytes(bits, []))
      }
    }
  }
}

fn validate_padding_bits(bits: BitArray, leftover: Int) -> Bool {
  case leftover {
    0 -> True
    _ -> check_tail_zero(bits, leftover)
  }
}

fn check_tail_zero(bits: BitArray, leftover: Int) -> Bool {
  case bits {
    <<_byte:8, rest:bits>> -> check_tail_zero(rest, leftover)
    _ ->
      // Whatever is left should be <= 7 bits, and should be all zeros
      case leftover, bits {
        0, _ -> True
        1, <<0:1>> -> True
        1, _ -> False
        2, <<0:2>> -> True
        2, _ -> False
        3, <<0:3>> -> True
        3, _ -> False
        4, <<0:4>> -> True
        4, _ -> False
        _, <<>> -> True
        _, _ -> False
      }
  }
}

fn groups_to_bit_array(groups: List(Int), acc: BitArray) -> BitArray {
  case groups {
    [] -> acc
    [g, ..rest] -> groups_to_bit_array(rest, bit_array.append(acc, <<g:5>>))
  }
}

fn extract_bytes(bits: BitArray, acc: List(Int)) -> List(Int) {
  case bits {
    <<byte:8, rest:bits>> -> extract_bytes(rest, [byte, ..acc])
    _ -> list_reverse(acc)
  }
}

fn char_to_value(c: String) -> Result(Int, Nil) {
  find_index(charset, c, 0)
}

fn find_index(haystack: String, needle: String, idx: Int) -> Result(Int, Nil) {
  case string.pop_grapheme(haystack) {
    Error(Nil) -> Error(Nil)
    Ok(#(ch, rest)) ->
      case ch == needle {
        True -> Ok(idx)
        False -> find_index(rest, needle, idx + 1)
      }
  }
}

fn xor(a: Int, b: Int) -> Int {
  do_xor(a, b, 0, 1)
}

fn do_xor(a: Int, b: Int, result: Int, bit: Int) -> Int {
  case a == 0 && b == 0 {
    True -> result
    False -> {
      let a_bit = a % 2
      let b_bit = b % 2
      let bit_set = case a_bit != b_bit {
        True -> bit
        False -> 0
      }
      do_xor(a / 2, b / 2, result + bit_set, bit * 2)
    }
  }
}

fn shr(n: Int, amount: Int) -> Int {
  case amount {
    0 -> n
    _ -> shr(n / 2, amount - 1)
  }
}

fn string_char_at(s: String, index: Int) -> String {
  case string.drop_start(s, index) |> string.pop_grapheme {
    Ok(#(c, _)) -> c
    Error(_) -> ""
  }
}

fn list_to_bit_array(bytes: List(Int), acc: BitArray) -> BitArray {
  case bytes {
    [] -> acc
    [b, ..rest] -> list_to_bit_array(rest, bit_array.append(acc, <<b:int>>))
  }
}

fn list_reverse(l: List(a)) -> List(a) {
  list_reverse_acc(l, [])
}

fn list_reverse_acc(l: List(a), acc: List(a)) -> List(a) {
  case l {
    [] -> acc
    [h, ..t] -> list_reverse_acc(t, [h, ..acc])
  }
}

fn list_take(l: List(a), n: Int) -> List(a) {
  case n, l {
    0, _ -> []
    _, [] -> []
    _, [h, ..t] -> [h, ..list_take(t, n - 1)]
  }
}

fn list_append(a: List(x), b: List(x)) -> List(x) {
  case a {
    [] -> b
    [h, ..t] -> [h, ..list_append(t, b)]
  }
}

fn int_to_string(n: Int) -> String {
  do_int_to_string(n, "")
}

fn do_int_to_string(n: Int, acc: String) -> String {
  case n < 10 {
    True -> digit_char(n) <> acc
    False -> do_int_to_string(n / 10, digit_char(n % 10) <> acc)
  }
}

fn digit_char(d: Int) -> String {
  case d {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    _ -> "9"
  }
}
