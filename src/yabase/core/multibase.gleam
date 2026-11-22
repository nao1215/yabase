/// Multibase prefix-based encoding and decoding.
///
/// Prefix assignments follow the official multibase registry:
/// https://github.com/multiformats/multibase/blob/master/multibase.csv
///
/// Prefix `7` (base8) packs 3-bit groups as the multibase spec does; the
/// standalone `yabase/base8` codec reads its input as one number instead.
///
/// Encodings that have no official multibase code point (Base62,
/// Base91, Base85 Btoa/Adobe/Z85, Crockford, Clockwork, DQ) return
/// `Error(UnsupportedMultibaseEncoding)` from `encode_with_prefix`.
import gleam/result
import gleam/string
import yabase/core/encoding.{type Decoded, type Encoding}
import yabase/core/error.{
  type CodecError, UnsupportedMultibaseEncoding, UnsupportedPrefix,
}
import yabase/core/guard
import yabase/internal/alphabet
import yabase/internal/bitgroup

/// Encode data with a multibase prefix.
pub fn encode_with_prefix(
  encoding: Encoding,
  data: BitArray,
) -> Result(String, CodecError) {
  case encoding.multibase_prefix(encoding) {
    Error(Nil) ->
      Error(UnsupportedMultibaseEncoding(encoding.multibase_name(encoding)))
    Ok(prefix) ->
      encode_payload(encoding, data)
      |> result.map(fn(encoded) {
        prefix <> encoding.normalise_for_multibase_prefix(encoding, encoded)
      })
  }
}

// Multibase base8 (prefix "7") writes 3-bit groups like RFC 4648 does for
// base32, while `yabase/base8` treats its input as one number. Only the
// multibase path uses the bit-group form.
fn encode_payload(
  encoding: Encoding,
  data: BitArray,
) -> Result(String, CodecError) {
  case encoding == encoding.base8() {
    True -> {
      guard.assert_byte_aligned(data)
      Ok(bitgroup.encode(data, 3, octal(), bitgroup.Unpadded))
    }
    False -> encoding.encode(encoding, data)
  }
}

fn decode_payload(
  encoding: Encoding,
  payload: String,
) -> Result(BitArray, CodecError) {
  case encoding == encoding.base8() {
    True -> bitgroup.decode_unpadded(payload, 3, octal())
    False -> encoding.decode_as(encoding, payload)
  }
}

fn octal() -> alphabet.Alphabet {
  alphabet.new("01234567", alphabet.CaseSensitive)
}

/// Decode a multibase-prefixed string, auto-detecting the encoding.
pub fn decode(value: String) -> Result(Decoded, CodecError) {
  case string.pop_grapheme(value) {
    Error(Nil) -> Error(UnsupportedPrefix(""))
    Ok(#(prefix, rest)) ->
      case encoding.from_multibase_prefix(prefix) {
        Error(Nil) -> Error(UnsupportedPrefix(prefix))
        Ok(encoding) ->
          decode_payload(encoding, rest)
          |> result.map(fn(data) { encoding.make_decoded(encoding, data) })
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
        Ok(encoding) -> decode_payload(encoding, rest)
      }
  }
}
