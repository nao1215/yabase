/// Standard Base64 encoding per RFC 4648.
import yabase/core/error.{type CodecError, NonCanonical}
import yabase/core/guard
import yabase/internal/alphabet
import yabase/internal/bitgroup

const symbols =
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

/// Encode a BitArray to standard Base64 with padding.
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

/// Decode a standard Base64 string to a BitArray.
/// Per RFC 4648 section 3.3, non-alphabet characters (including
/// whitespace, CR/LF, and other punctuation) are rejected. The
/// alphabet check runs before the length check so the caller sees
/// `InvalidCharacter` (with the offending byte and its position)
/// rather than a misleading `InvalidLength` whenever the real fault
/// is an out-of-alphabet byte.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  bitgroup.decode_base64_padded(
    input,
    alphabet.new(symbols, alphabet.CaseSensitive),
  )
}

/// Decode `input` and additionally reject non-canonical encodings
/// per RFC 4648 §3.5: the trailing pad bits in a 1- or 2-byte final
/// block must be zero. Useful for signature verification and
/// content-addressable storage, where the wire encoding's uniqueness
/// is part of the contract.
///
/// Returns `Error(NonCanonical)` when the input decodes to bytes
/// whose canonical re-encoding differs from the original input.
/// Other failure modes (`InvalidCharacter`, `InvalidLength`) are
/// surfaced unchanged from `decode/1`.
pub fn decode_strict(input: String) -> Result(BitArray, CodecError) {
  case decode(input) {
    Error(e) -> Error(e)
    Ok(bytes) ->
      case encode(bytes) == input {
        True -> Ok(bytes)
        False -> Error(NonCanonical)
      }
  }
}
