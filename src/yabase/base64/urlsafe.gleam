/// URL-safe Base64 encoding (RFC 4648 section 5).
/// Uses - instead of + and _ instead of /.
import yabase/core/error.{type CodecError}
import yabase/core/guard
import yabase/internal/alphabet
import yabase/internal/bitgroup

const symbols =
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

/// Encode a BitArray to URL-safe Base64 with padding.
///
/// Sub-byte input panics; see
/// `yabase/core/guard.assert_byte_aligned`.
pub fn encode(data: BitArray) -> String {
  guard.assert_byte_aligned(data)
  bitgroup.encode(
    data,
    6,
    alphabet.new(symbols, alphabet.CaseSensitive),
    bitgroup.PaddedTo(4),
  )
}

/// Decode a URL-safe Base64 string to a BitArray.
/// Per RFC 4648 section 3.3, non-alphabet characters (including
/// whitespace, CR/LF, and other punctuation) are rejected. The
/// alphabet check runs before the length check so the caller sees
/// `InvalidCharacter` rather than `InvalidLength` whenever the real
/// fault is an out-of-alphabet byte.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  bitgroup.decode_base64_padded(
    input,
    alphabet.new(symbols, alphabet.CaseSensitive),
  )
}
