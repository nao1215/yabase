/// Multibase auto-detection.
///
/// Multibase prefixes a single character to identify the encoding.
/// This allows a decoder to determine the encoding without out-of-band
/// information. Useful for content-addressed systems (IPFS, CID).
import gleam/bit_array
import gleam/io
import yabase
import yabase/core/encoding

pub fn main() -> Nil {
  let data = <<"Hello, multibase!":utf8>>

  // Encode the same data with different encodings
  let assert Ok(hex) = yabase.encode_multibase(encoding.base16(), data)
  let assert Ok(b58) = yabase.encode_multibase(encoding.base58_bitcoin(), data)
  let assert Ok(b64) = yabase.encode_multibase(encoding.base64_standard(), data)

  io.println("Base16:  " <> hex)
  io.println("Base58:  " <> b58)
  io.println("Base64:  " <> b64)

  // Auto-detect and decode. The result is an opaque `Decoded` value
  // — use `encoding.decoded_encoding/1` and `encoding.decoded_data/1`
  // to inspect it, and `encoding.multibase_name/1` to label the
  // detected codec.
  [hex, b58, b64]
  |> list_each(fn(encoded) {
    let assert Ok(d) = yabase.decode_multibase(encoded)
    let enc = encoding.decoded_encoding(d)
    let decoded = encoding.decoded_data(d)
    let assert Ok(text) = bit_array.to_string(decoded)
    io.println("Detected " <> encoding.multibase_name(enc) <> " -> " <> text)
  })
}

fn list_each(items: List(a), f: fn(a) -> b) -> Nil {
  case items {
    [] -> Nil
    [first, ..rest] -> {
      f(first)
      list_each(rest, f)
    }
  }
}
