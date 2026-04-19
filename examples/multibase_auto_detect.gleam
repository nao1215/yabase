/// Multibase auto-detection.
///
/// Multibase prefixes a single character to identify the encoding.
/// This allows a decoder to determine the encoding without out-of-band
/// information. Useful for content-addressed systems (IPFS, CID).
import gleam/bit_array
import gleam/io
import yabase
import yabase/core/encoding.{
  type Base58Variant, type Base64Variant, type Encoding, Base16, Base58, Base64,
  Bitcoin, Decoded, Standard,
}

pub fn main() -> Nil {
  let data = <<"Hello, multibase!":utf8>>

  // Encode the same data with different encodings
  let assert Ok(hex) = yabase.encode_multibase(Base16, data)
  let assert Ok(b58) = yabase.encode_multibase(Base58(Bitcoin), data)
  let assert Ok(b64) = yabase.encode_multibase(Base64(Standard), data)

  io.println("Base16:  " <> hex)
  io.println("Base58:  " <> b58)
  io.println("Base64:  " <> b64)

  // Auto-detect and decode
  [hex, b58, b64]
  |> list_each(fn(encoded) {
    let assert Ok(Decoded(encoding: enc, data: decoded)) =
      yabase.decode_multibase(encoded)
    let assert Ok(text) = bit_array.to_string(decoded)
    io.println("Detected " <> encoding_name(enc) <> " -> " <> text)
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

fn encoding_name(encoding: Encoding) -> String {
  case encoding {
    Base16 -> "Base16"
    Base58(variant) -> "Base58(" <> base58_variant_name(variant) <> ")"
    Base64(variant) -> "Base64(" <> base64_variant_name(variant) <> ")"
    _ -> "Unknown"
  }
}

fn base58_variant_name(variant: Base58Variant) -> String {
  case variant {
    Bitcoin -> "Bitcoin"
    _ -> "Unknown"
  }
}

fn base64_variant_name(variant: Base64Variant) -> String {
  case variant {
    Standard -> "Standard"
    _ -> "Unknown"
  }
}
