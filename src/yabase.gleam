/// yabase - Yet Another Base encoding library.
/// Provides a unified, type-safe interface for multiple binary-to-text encodings.
import yabase/core/encoding.{type Decoded, type Encoding}
import yabase/core/error.{type CodecError as CoreCodecError}
import yabase/core/multibase

/// Issue #74: re-export `CodecError` so callers who only
/// `import yabase` can type-annotate around `encode` / `decode` /
/// `encode_multibase` / `decode_multibase` without reaching into
/// `yabase/core/error`. The alias keeps the type identity (same
/// `CodecError` the underlying functions return), so error values
/// flow through unchanged.
pub type CodecError =
  CoreCodecError

/// Encode data using the specified encoding.
/// Returns Result because some encodings (Base85 Z85/Rfc1924) have input
/// length constraints.
pub fn encode(enc: Encoding, data: BitArray) -> Result(String, CodecError) {
  encoding.encode(enc, data)
}

/// Decode a string using the specified encoding.
pub fn decode(enc: Encoding, value: String) -> Result(BitArray, CodecError) {
  encoding.decode_as(enc, value)
}

/// Encode with a multibase prefix.
/// Returns Error for encodings without a defined prefix.
pub fn encode_multibase(
  enc: Encoding,
  data: BitArray,
) -> Result(String, CodecError) {
  multibase.encode_with_prefix(enc, data)
}

/// Decode a multibase-prefixed string, auto-detecting encoding.
/// Inspect the result with `encoding.decoded_encoding/1` and
/// `encoding.decoded_data/1` — the `Decoded` type is opaque so its
/// representation can evolve without breaking external pattern matches.
pub fn decode_multibase(value: String) -> Result(Decoded, CodecError) {
  multibase.decode(value)
}
