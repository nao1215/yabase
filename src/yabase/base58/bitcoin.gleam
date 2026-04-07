/// Base58 encoding (Bitcoin alphabet).
/// Alphabet: 123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz
import gleam/string
import yabase/core/encoding.{type CodecError}
import yabase/internal/bignum

const alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

/// Encode a BitArray to Base58 (Bitcoin).
pub fn encode(data: BitArray) -> String {
  bignum.encode(data, 58, alphabet)
}

/// Decode a Base58 string to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  bignum.decode(input, 58, "1", char_value)
}

fn char_value(c: String) -> Result(Int, Nil) {
  find_index(alphabet, c, 0)
}

fn find_index(haystack: String, needle: String, idx: Int) -> Result(Int, Nil) {
  case string.pop_grapheme(haystack) {
    Error(Nil) -> Error(Nil)
    Ok(#(c, rest)) ->
      case c == needle {
        True -> Ok(idx)
        False -> find_index(rest, needle, idx + 1)
      }
  }
}
