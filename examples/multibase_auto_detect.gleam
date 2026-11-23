/// Multibase auto-detection.
///
/// Multibase prefixes a single character to identify the encoding.
/// This allows a decoder to determine the encoding without out-of-band
/// information. Useful for content-addressed systems (IPFS, CID).
import gleam/bit_array
import gleam/io
import yabase

pub fn main() -> Nil {
  let data = <<"Hello, multibase!":utf8>>

  // Encode the same data with different encodings
  let assert Ok(hex) = yabase.encode_multibase(data, using: yabase.Base16)
  let assert Ok(b58) =
    yabase.encode_multibase(data, using: yabase.Base58Bitcoin)
  let assert Ok(b64) = yabase.encode_multibase(data, using: yabase.Base64)

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
    let enc = { d }.encoding
    let decoded = { d }.data
    let assert Ok(text) = bit_array.to_string(decoded)
    io.println("Detected " <> yabase.encoding_to_string(enc) <> " -> " <> text)
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
