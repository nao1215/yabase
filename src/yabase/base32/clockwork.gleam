/// Clockwork Base32 encoding.
/// Human-friendly variant: no padding, no confusable characters.
/// Alphabet: 0123456789ABCDEFGHJKMNPQRSTVWXYZ
/// Decoding: o/O->0, i/I/l/L->1
import gleam/bit_array
import gleam/list
import gleam/string
import yabase/core/error.{type CodecError, InvalidCharacter, InvalidLength}

const alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

/// Encode a BitArray to Clockwork Base32 (no padding).
pub fn encode(data: BitArray) -> String {
  encode_bits(data, [])
  |> list.reverse
  |> string.join("")
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

/// Decode a Clockwork Base32 string to a BitArray.
/// Case-insensitive. o/O->0, i/I/l/L->1.
///
/// Non-alphabet characters (whitespace, CR/LF, punctuation outside
/// Clockwork's accepted set) are rejected with `InvalidCharacter`
/// carrying the offending byte and its position. The alphabet
/// check runs before the length check so the caller does not see
/// a misleading `InvalidLength` when the real fault is an
/// out-of-alphabet byte.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  let upper = string.uppercase(input)
  case validate_alphabet(upper, 0) {
    Error(e) -> Error(e)
    Ok(Nil) -> {
      let len = string.length(upper)
      case len % 8 {
        1 | 3 | 6 -> Error(InvalidLength(len))
        _ -> decode_chars(upper, <<>>, 0)
      }
    }
  }
}

fn validate_alphabet(input: String, pos: Int) -> Result(Nil, CodecError) {
  case string.pop_grapheme(input) {
    Error(Nil) -> Ok(Nil)
    Ok(#(c, rest)) ->
      case char_to_value(c) {
        Ok(_) -> validate_alphabet(rest, pos + 1)
        Error(Nil) -> Error(InvalidCharacter(c, pos))
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
    "0" | "O" -> Ok(0)
    "1" | "I" | "L" -> Ok(1)
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
    "J" -> Ok(18)
    "K" -> Ok(19)
    "M" -> Ok(20)
    "N" -> Ok(21)
    "P" -> Ok(22)
    "Q" -> Ok(23)
    "R" -> Ok(24)
    "S" -> Ok(25)
    "T" -> Ok(26)
    "V" -> Ok(27)
    "W" -> Ok(28)
    "X" -> Ok(29)
    "Y" -> Ok(30)
    "Z" -> Ok(31)
    _ -> Error(Nil)
  }
}

fn string_char_at(s: String, index: Int) -> String {
  case string.drop_start(s, index) |> string.pop_grapheme {
    Ok(#(c, _)) -> c
    Error(Nil) -> ""
  }
}
