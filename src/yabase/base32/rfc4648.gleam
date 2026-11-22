/// Base32 encoding per RFC 4648.
import yabase/core/error.{type CodecError, NonCanonical}
import yabase/core/guard
import yabase/internal/alphabet
import yabase/internal/bitgroup

const symbols = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

/// Encode a BitArray to a Base32 string with padding.
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

/// Decode a Base32 string (with or without padding) to a BitArray.
///
/// Non-alphabet characters (whitespace, CR/LF, punctuation outside
/// `A-Z`, `2-7`, and `=`) are rejected with `InvalidCharacter`
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

/// Decode `input` and additionally reject non-canonical encodings
/// per RFC 4648 §3.5 / §6: the canonical form is the uppercase,
/// padded shape produced by `encode/1`, and any deviation
/// (lowercase, mixed case, missing padding, non-zero pad bits in a
/// final partial block) is rejected with `Error(NonCanonical)`.
/// Useful for signature verification, content-addressable storage,
/// and replay-attack-resistant token handling, where the wire
/// encoding's uniqueness is part of the contract.
///
/// Returns `Error(NonCanonical)` when the input is not byte-equal
/// to `encode(decode(input))`. Other failure modes
/// (`InvalidCharacter`, `InvalidLength`) are surfaced unchanged from
/// `decode/1`.
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
