/// Multibase prefix-based encoding and decoding.
///
/// Prefix assignments follow the official multibase registry:
/// https://github.com/multiformats/multibase/blob/master/multibase.csv
///
/// Encodings that have no official multibase code point (Base62,
/// Base91, Base85 Btoa/Adobe/Z85, Crockford, Clockwork, DQ) return
/// `Error(UnsupportedMultibaseEncoding)` from `encode_with_prefix`.
import gleam/result
import gleam/string
import yabase/core/encoding.{type Decoded, type Encoding, Decoded}
import yabase/core/error.{
  type CodecError, UnsupportedMultibaseEncoding, UnsupportedPrefix,
}

/// Encode data with a multibase prefix.
pub fn encode_with_prefix(
  enc: Encoding,
  data: BitArray,
) -> Result(String, CodecError) {
  case encoding.multibase_prefix(enc) {
    Error(Nil) ->
      Error(UnsupportedMultibaseEncoding(encoding.multibase_name(enc)))
    Ok(prefix) ->
      encoding.encode(enc, data)
      |> result.map(fn(encoded) {
        prefix <> encoding.normalise_for_multibase_prefix(enc, encoded)
      })
  }
}

/// Decode a multibase-prefixed string, auto-detecting the encoding.
pub fn decode(value: String) -> Result(Decoded, CodecError) {
  case string.pop_grapheme(value) {
    Error(Nil) -> Error(UnsupportedPrefix(""))
    Ok(#(prefix, rest)) ->
      case encoding.from_multibase_prefix(prefix) {
        Error(Nil) -> Error(UnsupportedPrefix(prefix))
        Ok(enc) ->
          encoding.decode_as(enc, rest)
          |> result.map(fn(data) { Decoded(encoding: enc, data: data) })
      }
  }
}

/// Decode a multibase-prefixed string to raw bytes.
pub fn decode_bytes(value: String) -> Result(BitArray, CodecError) {
  case string.pop_grapheme(value) {
    Error(Nil) -> Error(UnsupportedPrefix(""))
    Ok(#(prefix, rest)) ->
      case encoding.from_multibase_prefix(prefix) {
        Error(Nil) -> Error(UnsupportedPrefix(prefix))
        Ok(enc) -> encoding.decode_as(enc, rest)
      }
  }
}
