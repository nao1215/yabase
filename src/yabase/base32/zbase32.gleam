/// z-base-32 encoding.
/// Human-oriented alphabet optimized for readability.
/// Alphabet: ybndrfg8ejkmcpqxot1uwisza345h769
/// No padding.
import yabase/core/error.{type CodecError}
import yabase/core/guard
import yabase/internal/alphabet
import yabase/internal/bitgroup

const symbols = "ybndrfg8ejkmcpqxot1uwisza345h769"

/// Encode a BitArray to z-base-32 (no padding).
///
/// Sub-byte input panics; see
/// `yabase/core/guard.assert_byte_aligned`.
pub fn encode(data: BitArray) -> String {
  guard.assert_byte_aligned(data)
  bitgroup.encode(
    data,
    5,
    alphabet.new(symbols, alphabet.FoldToLower),
    bitgroup.Unpadded,
  )
}

/// Decode a z-base-32 string to a BitArray.
///
/// Non-alphabet characters (whitespace, CR/LF, punctuation outside
/// z-base-32's accepted set) are rejected with `InvalidCharacter`
/// carrying the offending byte and its position. The alphabet check
/// runs before the length check so the caller does not see a
/// misleading `InvalidLength` when the real fault is an
/// out-of-alphabet byte.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  bitgroup.decode_unpadded(
    input,
    5,
    alphabet.new(symbols, alphabet.FoldToLower),
  )
}
