/// JWT-style URL-safe Base64 encoding.
///
/// JWT headers and payloads use Base64 URL-safe without padding (RFC 7515).
/// This example shows how to encode and decode JWT-like segments.
import gleam/bit_array
import gleam/io
import yabase/base64/urlsafe_nopadding

pub fn main() {
  // A typical JWT header: {"alg":"HS256","typ":"JWT"}
  let header = <<"{\"alg\":\"HS256\",\"typ\":\"JWT\"}":utf8>>
  let encoded = urlsafe_nopadding.encode(header)
  io.println("Encoded: " <> encoded)
  // => eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9

  let assert Ok(decoded) = urlsafe_nopadding.decode(encoded)
  let assert Ok(text) = bit_array.to_string(decoded)
  io.println("Decoded: " <> text)
}
