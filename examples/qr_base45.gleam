/// QR-code-friendly Base45 encoding (RFC 9285).
///
/// Base45 is used in EU Digital COVID Certificates and other QR-code
/// applications because its alphabet is a subset of the QR alphanumeric
/// mode character set, resulting in smaller QR codes.
import gleam/bit_array
import gleam/io
import yabase/base45

pub fn main() -> Nil {
  let payload = <<"Hello, QR world!":utf8>>
  let encoded = base45.encode(payload)
  io.println("Base45: " <> encoded)

  let assert Ok(decoded) = base45.decode(encoded)
  let assert Ok(text) = bit_array.to_string(decoded)
  io.println("Decoded: " <> text)
}
