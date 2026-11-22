/// Base32 Hex encoding (RFC 4648, extended hex alphabet).
import yabase/core/error.{type CodecError}
import yabase/core/guard
import yabase/internal/alphabet
import yabase/internal/bitgroup

const symbols = "0123456789ABCDEFGHIJKLMNOPQRSTUV"

/// Encode a BitArray to Base32 Hex string with padding.
///
/// Sub-byte input panics; see
/// `yabase/core/guard.assert_byte_aligned`.
pub fn encode(data: BitArray) -> String {
  guard.assert_byte_aligned(data)
  bitgroup.encode(
    data,
    5,
    alphabet.new(symbols, alphabet.FoldToUpper),
    bitgroup.PaddedTo(8),
  )
}

/// Decode a Base32 Hex string to a BitArray.
///
/// Non-alphabet characters (whitespace, CR/LF, punctuation outside
/// `0-9`, `A-V`, and `=`) are rejected with `InvalidCharacter`
/// carrying the offending byte and its position. The alphabet check
/// runs before the length check so the caller does not see a
/// misleading `InvalidLength` when the real fault is an
/// out-of-alphabet byte.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  bitgroup.decode_base32_padded(
    input,
    alphabet.new(symbols, alphabet.FoldToUpper),
  )
}
