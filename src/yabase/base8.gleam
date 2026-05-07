/// Base8 (octal) encoding.
/// Treats the input as a big integer and encodes in base 8 (0-7).
/// Leading 0x00 bytes round-trip as leading "0" characters.
import yabase/core/error.{type CodecError}
import yabase/core/guard
import yabase/internal/bignum

const alphabet = "01234567"

/// Encode a BitArray to an octal string.
///
/// Sub-byte input panics; see
/// `yabase/core/guard.assert_byte_aligned`.
pub fn encode(data: BitArray) -> String {
  guard.assert_byte_aligned(data)
  bignum.encode(data, 8, alphabet)
}

/// Decode an octal string to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  bignum.decode(input, 8, "0", char_value)
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
    _ -> Error(Nil)
  }
}
