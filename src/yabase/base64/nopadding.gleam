/// Base64 encoding without padding.
/// Same as standard Base64 but padding characters are stripped.
import yabase/core/error.{type CodecError}
import yabase/core/guard
import yabase/internal/alphabet
import yabase/internal/bitgroup

const symbols =
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

/// Encode a BitArray to Base64 without padding.
pub fn encode(data: BitArray) -> String {
  guard.assert_byte_aligned(data)
  bitgroup.encode(
    data,
    6,
    alphabet.new(symbols, alphabet.CaseSensitive),
    bitgroup.Unpadded,
  )
}

/// Decode a Base64 string (without padding) to a BitArray.
/// Length % 4 must be 0, 2, or 3 (never 1).
/// Padding characters (=) and any non-alphabet byte (whitespace,
/// CR/LF, punctuation) are rejected with `InvalidCharacter` carrying
/// the offending byte and its position. The alphabet check runs
/// before the length check so a whitespace byte does not surface as
/// a misleading `InvalidLength`.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  bitgroup.decode_unpadded(
    input,
    6,
    alphabet.new(symbols, alphabet.CaseSensitive),
  )
}
