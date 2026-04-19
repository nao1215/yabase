/// Crockford's Base32 encoding.
/// Encodes data as a number in base 32 per https://www.crockford.com/base32.html
/// Alphabet: 0123456789ABCDEFGHJKMNPQRSTVWXYZ
/// Case-insensitive decoding. O->0, I/L->1 on decode. Hyphens ignored.
/// No padding.
import gleam/string
import yabase/core/encoding.{type CodecError, InvalidChecksum, InvalidLength}
import yabase/internal/bignum

const alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

/// Encode a BitArray to Crockford Base32 string.
/// The input is treated as a big-endian unsigned integer and
/// converted to base 32 using Crockford's alphabet.
pub fn encode(data: BitArray) -> String {
  bignum.encode(data, 32, alphabet)
}

/// Decode a Crockford Base32 string to a BitArray.
/// Accepts hyphens (ignored). O->0, I/L->1. Case-insensitive.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  let cleaned =
    string.uppercase(input)
    |> string.replace("-", "")
  bignum.decode(cleaned, 32, "0", char_to_value)
}

/// Encode a BitArray to Crockford Base32 with a check symbol appended.
/// The check symbol is computed as the numeric value of the data mod 37,
/// mapped to the 37-character check alphabet (0-9A-Z plus *~$=U).
pub fn encode_check(data: BitArray) -> String {
  let encoded = encode(data)
  let num = bignum.bytes_to_int(data, 0)
  let check_index = num % 37
  encoded <> string_char_at(check_alphabet, check_index)
}

/// Decode a Crockford Base32 string with check symbol verification.
/// The last character is the check symbol; the rest is the encoded data.
/// Returns Error(InvalidChecksum) if the check symbol does not match.
pub fn decode_check(input: String) -> Result(BitArray, CodecError) {
  let len = string.length(input)
  case len < 1 {
    True -> Error(InvalidLength(0))
    False -> {
      let body = string.slice(input, 0, len - 1)
      let check_char = string.uppercase(string.slice(input, len - 1, 1))
      case decode(body) {
        Error(e) -> Error(e)
        Ok(data) -> {
          let num = bignum.bytes_to_int(data, 0)
          let expected_index = num % 37
          let expected_char = string_char_at(check_alphabet, expected_index)
          case check_char == expected_char {
            True -> Ok(data)
            False -> Error(InvalidChecksum)
          }
        }
      }
    }
  }
}

const check_alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ*~$=U"

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
    Ok(#(char, _)) -> char
    Error(Nil) -> ""
  }
}
