/// Crockford's Base32 encoding.
/// Alphabet: 0123456789ABCDEFGHJKMNPQRSTVWXYZ
/// Case-insensitive decoding. O->0, I/L->1 on decode.
/// No padding.
import gleam/bit_array
import gleam/string
import yabase/core/encoding.{type CodecError, InvalidCharacter, InvalidLength}

const alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

/// Encode a BitArray to Crockford Base32 string (no padding).
pub fn encode(data: BitArray) -> String {
  encode_bits(data, "")
}

fn encode_bits(data: BitArray, acc: String) -> String {
  case data {
    <<a:5, rest:bits>> -> {
      let char = string_char_at(alphabet, a)
      encode_bits(rest, acc <> char)
    }
    <<a:4>> -> acc <> string_char_at(alphabet, a * 2)
    <<a:3>> -> acc <> string_char_at(alphabet, a * 4)
    <<a:2>> -> acc <> string_char_at(alphabet, a * 8)
    <<a:1>> -> acc <> string_char_at(alphabet, a * 16)
    _ -> acc
  }
}

/// Decode a Crockford Base32 string to a BitArray.
/// Accepts hyphens (ignored). O->0, I/L->1.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  let cleaned =
    string.uppercase(input)
    |> string.replace("-", "")
  let len = string.length(cleaned)
  case len % 8 {
    1 | 3 | 6 -> Error(InvalidLength(string.length(input)))
    _ -> decode_chars(cleaned, <<>>, 0)
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
        Error(_) -> Error(InvalidCharacter(c, pos))
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
    Error(_) -> ""
  }
}
