/// Base10 (decimal) encoding.
/// Treats the input as a big integer and encodes in base 10 (0-9).
/// Leading 0x00 bytes round-trip as leading "0" characters.
import yabase/core/error.{type CodecError}
import yabase/internal/bignum

const alphabet = "0123456789"

/// Encode a BitArray to a decimal string.
pub fn encode(data: BitArray) -> String {
  bignum.encode(data, 10, alphabet)
}

/// Decode a decimal string to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  bignum.decode(input, 10, "0", char_value)
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
    _ -> Error(Nil)
  }
}
