/// Base8 (octal) encoding.
/// Treats the input as a big integer and encodes in base 8 (0-7).
/// Leading 0x00 bytes round-trip as leading "0" characters.
import yabase/core/error.{type CodecError}
import yabase/core/guard
import yabase/internal/alphabet
import yabase/internal/bignum

const symbols = "01234567"

/// Encode a BitArray to an octal string.
///
/// Sub-byte input panics; see
/// `yabase/core/guard.assert_byte_aligned`.
pub fn encode(data: BitArray) -> String {
  guard.assert_byte_aligned(data)
  bignum.encode(data, alphabet.new(symbols, alphabet.CaseSensitive))
}

/// Decode an octal string to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  bignum.decode(input, alphabet.new(symbols, alphabet.CaseSensitive))
}
