/// Base36 encoding (0-9, a-z). Case-insensitive decode.
/// Leading 0x00 bytes round-trip as leading "0" characters.
import gleam/string
import yabase/core/encoding.{type CodecError}
import yabase/internal/bignum

const alphabet = "0123456789abcdefghijklmnopqrstuvwxyz"

/// Encode a BitArray to Base36 (lowercase).
pub fn encode(data: BitArray) -> String {
  bignum.encode(data, 36, alphabet)
}

/// Decode a Base36 string to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  let lower = string.lowercase(input)
  bignum.decode(lower, 36, "0", char_value)
}

fn char_value(c: String) -> Result(Int, Nil) {
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
    "a" -> Ok(10)
    "b" -> Ok(11)
    "c" -> Ok(12)
    "d" -> Ok(13)
    "e" -> Ok(14)
    "f" -> Ok(15)
    "g" -> Ok(16)
    "h" -> Ok(17)
    "i" -> Ok(18)
    "j" -> Ok(19)
    "k" -> Ok(20)
    "l" -> Ok(21)
    "m" -> Ok(22)
    "n" -> Ok(23)
    "o" -> Ok(24)
    "p" -> Ok(25)
    "q" -> Ok(26)
    "r" -> Ok(27)
    "s" -> Ok(28)
    "t" -> Ok(29)
    "u" -> Ok(30)
    "v" -> Ok(31)
    "w" -> Ok(32)
    "x" -> Ok(33)
    "y" -> Ok(34)
    "z" -> Ok(35)
    _ -> Error(Nil)
  }
}
