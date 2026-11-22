/// Base16 (hexadecimal) encoding and decoding.
///
/// Issue #19: `encode/1` now emits the canonical uppercase form
/// (`0-9 A-F`) per RFC 4648 §8. Use `encode_lowercase/1` for the
/// opt-in lowercase variant. The decoder remains case-insensitive,
/// so round-trips with both encoders work.
import yabase/core/error.{type CodecError, NonCanonical}
import yabase/core/guard
import yabase/internal/alphabet
import yabase/internal/bitgroup

const upper_symbols = "0123456789ABCDEF"

const lower_symbols = "0123456789abcdef"

/// Encode a BitArray to an uppercase hexadecimal string per
/// RFC 4648 §8 (the canonical Base 16 encoding).
///
/// Use `encode_lowercase/1` when interoperating with tools that
/// emit lowercase hex (e.g. `sha256sum`, IPFS multibase prefix `f`,
/// many JSON Web Token implementations); the decoder accepts either
/// case, so round-trips work in both directions.
pub fn encode(data: BitArray) -> String {
  guard.assert_byte_aligned(data)
  bitgroup.encode(
    data,
    4,
    alphabet.new(upper_symbols, alphabet.CaseSensitive),
    bitgroup.Unpadded,
  )
}

/// Encode a BitArray to a lowercase hexadecimal string. Use this
/// when interoperating with tools that expect the lowercase variant
/// (`sha256sum` shell output, IPFS multibase prefix `f`, etc.). The
/// canonical RFC 4648 §8 form is uppercase — see `encode/1`.
pub fn encode_lowercase(data: BitArray) -> String {
  guard.assert_byte_aligned(data)
  bitgroup.encode(
    data,
    4,
    alphabet.new(lower_symbols, alphabet.CaseSensitive),
    bitgroup.Unpadded,
  )
}

/// Decode a hexadecimal string to a BitArray.
pub fn decode(input: String) -> Result(BitArray, CodecError) {
  bitgroup.decode_exact(
    input,
    4,
    alphabet.new(upper_symbols, alphabet.FoldToLower),
  )
}

/// Decode `input` and additionally reject non-canonical encodings
/// per RFC 4648 §8: the canonical Base 16 form is uppercase
/// (`0-9 A-F`). Useful for HMAC / TOTP / WebAuthn / content-
/// addressable storage and any signature-verification context where
/// the encoded string itself is part of the contract — strict mode
/// rejects the lowercase form (`encode_lowercase/1`'s output) as
/// non-canonical even though it decodes to the same bytes through
/// the lenient `decode/1`.
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
