/// Multibase auto-detection.
///
/// Multibase prefixes a single character to identify the encoding.
/// This allows a decoder to determine the encoding without out-of-band
/// information. Useful for content-addressed systems (IPFS, CID).
import gleam/bit_array
import gleam/io
import gleam/string
import yabase
import yabase/core/encoding.{Base16, Base58, Base64, Bitcoin, Decoded, Standard}

pub fn main() {
  let data = <<"Hello, multibase!":utf8>>

  // Encode the same data with different encodings
  let assert Ok(hex) = yabase.encode_with_prefix(Base16, data)
  let assert Ok(b58) = yabase.encode_with_prefix(Base58(Bitcoin), data)
  let assert Ok(b64) = yabase.encode_with_prefix(Base64(Standard), data)

  io.println("Base16:  " <> hex)
  io.println("Base58:  " <> b58)
  io.println("Base64:  " <> b64)

  // Auto-detect and decode
  [hex, b58, b64]
  |> list_each(fn(encoded) {
    let assert Ok(Decoded(encoding: enc, data: decoded)) =
      yabase.decode(encoded)
    let assert Ok(text) = bit_array.to_string(decoded)
    io.println("Detected " <> string.inspect(enc) <> " -> " <> text)
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
