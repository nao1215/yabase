/// Base10 (decimal) encoding.
/// Treats the input as a big integer and encodes in base 10 (0-9).
/// Leading 0x00 bytes round-trip as leading "0" characters.
import yabase/core/error.{type CodecError}
import yabase/core/guard
import yabase/internal/alphabet
import yabase/internal/bignum

const symbols = "0123456789"

/// Encode a BitArray to a decimal string.
///
/// Sub-byte input panics; see
/// `yabase/core/guard.assert_byte_aligned`.
pub fn encode(data: BitArray) -> String {
  guard.assert_byte_aligned(data)
  bignum.encode(data, alphabet.new(symbols, alphabet.CaseSensitive))
}

/// Decode a decimal string to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  bignum.decode(input, alphabet.new(symbols, alphabet.CaseSensitive))
}
