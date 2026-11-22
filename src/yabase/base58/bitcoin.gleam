/// Base58 encoding (Bitcoin alphabet).
/// Alphabet: 123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz
import yabase/core/error.{type CodecError}
import yabase/core/guard
import yabase/internal/alphabet
import yabase/internal/bignum

const symbols = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

/// Encode a BitArray to Base58 (Bitcoin).
///
/// Sub-byte input panics; see
/// `yabase/core/guard.assert_byte_aligned`.
pub fn encode(data: BitArray) -> String {
  guard.assert_byte_aligned(data)
  bignum.encode(data, alphabet.new(symbols, alphabet.CaseSensitive))
}

/// Decode a Base58 string to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  bignum.decode(input, alphabet.new(symbols, alphabet.CaseSensitive))
}
