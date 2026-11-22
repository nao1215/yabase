/// Base62 encoding (0-9, A-Z, a-z).
/// Leading 0x00 bytes round-trip as leading "0" characters.
import yabase/core/error.{type CodecError}
import yabase/core/guard
import yabase/internal/alphabet
import yabase/internal/bignum

const symbols = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

/// Encode a BitArray to Base62.
///
/// Sub-byte input panics; see
/// `yabase/core/guard.assert_byte_aligned`.
pub fn encode(data: BitArray) -> String {
  guard.assert_byte_aligned(data)
  bignum.encode(data, alphabet.new(symbols, alphabet.CaseSensitive))
}

/// Decode a Base62 string to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  bignum.decode(input, alphabet.new(symbols, alphabet.CaseSensitive))
}
