/// yabase - Yet Another Base encoding library.
/// Provides a unified, type-safe interface for multiple binary-to-text encodings.
import yabase/core/dispatcher
import yabase/core/encoding.{type CodecError, type Decoded, type Encoding}
import yabase/core/multibase

/// Encode data using the specified encoding.
/// Returns Result because some encodings (Z85, RFC 1924 Base85) have input
/// length constraints.
pub fn encode(enc: Encoding, data: BitArray) -> Result(String, CodecError) {
  dispatcher.encode(enc, data)
}

/// Decode a string using the specified encoding.
pub fn decode_as(enc: Encoding, value: String) -> Result(BitArray, CodecError) {
  dispatcher.decode_as(enc, value)
}

/// Encode with a multibase prefix.
/// Returns Error for encodings without a defined prefix.
pub fn encode_with_prefix(
  enc: Encoding,
  data: BitArray,
) -> Result(String, CodecError) {
  multibase.encode_with_prefix(enc, data)
}

/// Decode a multibase-prefixed string, auto-detecting encoding.
/// Returns Decoded(encoding, data) where data is the decoded BitArray.
pub fn decode(value: String) -> Result(Decoded, CodecError) {
  multibase.decode(value)
}
