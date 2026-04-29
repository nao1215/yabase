/// Base62 encoding (0-9, A-Z, a-z).
/// Leading 0x00 bytes round-trip as leading "0" characters.
import gleam/string
import yabase/core/error.{type CodecError}
import yabase/internal/bignum

const alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

/// Encode a BitArray to Base62.
pub fn encode(data: BitArray) -> String {
  bignum.encode(data, 62, alphabet)
}

/// Decode a Base62 string to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  bignum.decode(input, 62, "0", char_value)
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
