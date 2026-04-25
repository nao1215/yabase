/// Base32 encoding per RFC 4648.
import gleam/bit_array
import gleam/bool
import gleam/list
import gleam/string
import yabase/core/encoding.{type CodecError, InvalidCharacter, InvalidLength}

const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

const pad = "="

/// Encode a BitArray to a Base32 string with padding.
pub fn encode(data: BitArray) -> String {
  encode_bits(data, [])
  |> list.reverse
  |> string.join("")
  |> add_padding
}

fn encode_bits(data: BitArray, acc: List(String)) -> List(String) {
  case data {
    <<a:5, rest:bits>> -> {
      let char = string_char_at(alphabet, a)
      encode_bits(rest, [char, ..acc])
    }
    <<a:4>> -> [string_char_at(alphabet, a * 2), ..acc]
    <<a:3>> -> [string_char_at(alphabet, a * 4), ..acc]
    <<a:2>> -> [string_char_at(alphabet, a * 8), ..acc]
    <<a:1>> -> [string_char_at(alphabet, a * 16), ..acc]
    _ -> acc
  }
}

fn add_padding(encoded: String) -> String {
  let remainder = string.length(encoded) % 8
  case remainder {
    0 -> encoded
    _ -> encoded <> string.repeat(pad, 8 - remainder)
  }
}

/// Decode a Base32 string (with or without padding) to a BitArray.
///
/// Non-alphabet characters (whitespace, CR/LF, punctuation outside
/// `A-Z`, `2-7`, and `=`) are rejected with `InvalidCharacter`
/// carrying the offending byte and its position. The alphabet check
/// runs before the length check so the caller does not see a
/// misleading `InvalidLength` when the real fault is an
/// out-of-alphabet byte.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  let upper = string.uppercase(input)
  case validate_alphabet(upper, 0) {
    Error(e) -> Error(e)
    Ok(Nil) -> decode_validated(upper)
  }
}

fn decode_validated(upper: String) -> Result(BitArray, CodecError) {
  let input_len = string.length(upper)
  let has_padding = string.contains(upper, pad)
  // If padding is present, total length must be a multiple of 8
  case has_padding && input_len % 8 != 0 {
    True -> Error(InvalidLength(input_len))
    False ->
      case validate_padding(upper) {
        Error(e) -> Error(e)
        Ok(stripped) -> {
          let len = string.length(stripped)
          case has_padding && len == 0 {
            // Pure padding with no data characters is invalid
            True -> Error(InvalidLength(input_len))
            False ->
              case len % 8 {
                1 | 3 | 6 -> Error(InvalidLength(input_len))
                _ -> decode_chars(stripped, <<>>, 0)
              }
          }
        }
      }
  }
}

fn validate_alphabet(input: String, pos: Int) -> Result(Nil, CodecError) {
  case string.pop_grapheme(input) {
    Error(Nil) -> Ok(Nil)
    Ok(#(c, rest)) ->
      case is_alphabet(c) {
        True -> validate_alphabet(rest, pos + 1)
        False -> Error(InvalidCharacter(c, pos))
      }
  }
}

fn is_alphabet(c: String) -> Bool {
  use <- bool.guard(when: c == pad, return: True)
  case char_to_value(c) {
    Ok(_) -> True
    Error(Nil) -> False
  }
}

/// Validate that = only appears as trailing padding.
/// Returns the stripped (no padding) string on success.
fn validate_padding(input: String) -> Result(String, CodecError) {
  validate_padding_loop(input, 0, False, "")
}

fn validate_padding_loop(
  input: String,
  pos: Int,
  seen_pad: Bool,
  acc: String,
) -> Result(String, CodecError) {
  case string.pop_grapheme(input) {
    Error(Nil) -> Ok(acc)
    Ok(#(c, rest)) ->
      case c == pad {
        True -> validate_padding_loop(rest, pos + 1, True, acc)
        False ->
          case seen_pad {
            True ->
              // Non-pad character after padding -> invalid
              Error(InvalidCharacter(pad, pos - 1))
            False -> validate_padding_loop(rest, pos + 1, False, acc <> c)
          }
      }
  }
}

fn decode_chars(
  input: String,
  acc: BitArray,
  pos: Int,
) -> Result(BitArray, CodecError) {
  case string.pop_grapheme(input) {
    Error(Nil) -> finalize_bits(acc)
    Ok(#(c, rest)) ->
      case char_to_value(c) {
        Error(Nil) -> Error(InvalidCharacter(c, pos))
        Ok(val) -> decode_chars(rest, bit_array.append(acc, <<val:5>>), pos + 1)
      }
  }
}

fn finalize_bits(bits: BitArray) -> Result(BitArray, CodecError) {
  extract_bytes(bits, <<>>)
}

fn extract_bytes(bits: BitArray, acc: BitArray) -> Result(BitArray, CodecError) {
  case bits {
    <<byte:8, rest:bits>> ->
      extract_bytes(rest, bit_array.append(acc, <<byte:int>>))
    _ -> Ok(acc)
  }
}

fn char_to_value(c: String) -> Result(Int, Nil) {
  case c {
    "A" -> Ok(0)
    "B" -> Ok(1)
    "C" -> Ok(2)
    "D" -> Ok(3)
    "E" -> Ok(4)
    "F" -> Ok(5)
    "G" -> Ok(6)
    "H" -> Ok(7)
    "I" -> Ok(8)
    "J" -> Ok(9)
    "K" -> Ok(10)
    "L" -> Ok(11)
    "M" -> Ok(12)
    "N" -> Ok(13)
    "O" -> Ok(14)
    "P" -> Ok(15)
    "Q" -> Ok(16)
    "R" -> Ok(17)
    "S" -> Ok(18)
    "T" -> Ok(19)
    "U" -> Ok(20)
    "V" -> Ok(21)
    "W" -> Ok(22)
    "X" -> Ok(23)
    "Y" -> Ok(24)
    "Z" -> Ok(25)
    "2" -> Ok(26)
    "3" -> Ok(27)
    "4" -> Ok(28)
    "5" -> Ok(29)
    "6" -> Ok(30)
    "7" -> Ok(31)
    _ -> Error(Nil)
  }
}

fn string_char_at(s: String, index: Int) -> String {
  case string.drop_start(s, index) |> string.pop_grapheme {
    Ok(#(c, _)) -> c
    Error(Nil) -> ""
  }
}
