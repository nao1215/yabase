/// yabase - Yet Another Base encoding library.
/// Provides a unified, type-safe interface for multiple binary-to-text encodings.
import yabase/core/encoding.{type Decoded, type Encoding}
import yabase/core/error.{type CodecError}
import yabase/core/multibase

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
/// Returns Decoded(encoding, data) where data is the decoded BitArray.
pub fn decode_multibase(value: String) -> Result(Decoded, CodecError) {
  multibase.decode(value)
}
