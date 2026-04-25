/// Base32 Hex encoding (RFC 4648, extended hex alphabet).
import gleam/bit_array
import gleam/bool
import gleam/list
import gleam/string
import yabase/core/encoding.{type CodecError, InvalidCharacter, InvalidLength}

const alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUV"

const pad = "="

/// Encode a BitArray to Base32 Hex string with padding.
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

/// Decode a Base32 Hex string to a BitArray.
///
/// Non-alphabet characters (whitespace, CR/LF, punctuation outside
/// `0-9`, `A-V`, and `=`) are rejected with `InvalidCharacter`
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
  case has_padding && input_len % 8 != 0 {
    True -> Error(InvalidLength(input_len))
    False ->
      case validate_padding(upper) {
        Error(e) -> Error(e)
        Ok(stripped) -> {
          let len = string.length(stripped)
          case has_padding && len == 0 {
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
            True -> Error(InvalidCharacter(pad, pos - 1))
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
    Error(Nil) -> extract_bytes(acc, <<>>)
    Ok(#(c, rest)) ->
      case char_to_value(c) {
        Error(Nil) -> Error(InvalidCharacter(c, pos))
        Ok(val) -> decode_chars(rest, bit_array.append(acc, <<val:5>>), pos + 1)
      }
  }
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
    "0" -> Ok(0)
    "1" -> Ok(1)
    "2" -> Ok(2)
    "3" -> Ok(3)
    "4" -> Ok(4)
    "5" -> Ok(5)
    "6" -> Ok(6)
    "7" -> Ok(7)
    "8" -> Ok(8)
    "9" -> Ok(9)
    "A" -> Ok(10)
    "B" -> Ok(11)
    "C" -> Ok(12)
    "D" -> Ok(13)
    "E" -> Ok(14)
    "F" -> Ok(15)
    "G" -> Ok(16)
    "H" -> Ok(17)
    "I" -> Ok(18)
    "J" -> Ok(19)
    "K" -> Ok(20)
    "L" -> Ok(21)
    "M" -> Ok(22)
    "N" -> Ok(23)
    "O" -> Ok(24)
    "P" -> Ok(25)
    "Q" -> Ok(26)
    "R" -> Ok(27)
    "S" -> Ok(28)
    "T" -> Ok(29)
    "U" -> Ok(30)
    "V" -> Ok(31)
    _ -> Error(Nil)
  }
}

fn string_char_at(s: String, index: Int) -> String {
  case string.drop_start(s, index) |> string.pop_grapheme {
    Ok(#(c, _)) -> c
    Error(Nil) -> ""
  }
}
