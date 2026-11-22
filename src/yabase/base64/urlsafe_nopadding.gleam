/// URL-safe Base64 encoding without padding.
/// Same as URL-safe Base64 but padding characters are stripped.
import yabase/core/error.{type CodecError}
import yabase/core/guard
import yabase/internal/alphabet
import yabase/internal/bitgroup

const symbols =
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

/// Encode a BitArray to URL-safe Base64 without padding.
pub fn encode(data: BitArray) -> String {
  guard.assert_byte_aligned(data)
  bitgroup.encode(
    data,
    6,
    alphabet.new(symbols, alphabet.CaseSensitive),
    bitgroup.Unpadded,
  )
}

/// Decode a URL-safe Base64 string without padding to a BitArray.
/// Length % 4 must be 0, 2, or 3 (never 1).
/// Padding characters (=) are rejected.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  bitgroup.decode_unpadded(
    input,
    6,
    alphabet.new(symbols, alphabet.CaseSensitive),
  )
}
