/// Bitcoin Base58Check encoding demo.
///
/// Base58Check prepends a version byte and appends a 4-byte SHA-256d
/// checksum. Version 0x00 is used for mainnet P2PKH (with a 20-byte
/// hash160 payload), 0x05 for P2SH. This example uses a short payload
/// for brevity, so the output is not a real Bitcoin address.
import gleam/bit_array
import gleam/int
import gleam/io
import yabase/base58check

pub fn main() -> Nil {
  // Encode a short payload with version byte 0
  let payload = <<0xab, 0xcd, 0xef, 0x01, 0x23>>
  let assert Ok(encoded) = base58check.encode(0, payload)
  io.println("Base58Check: " <> encoded)

  // Decode and verify checksum
  let assert Ok(decoded) = base58check.decode(encoded)
  io.println("Version: " <> int.to_string(decoded.version))
  io.println(
    "Payload size: " <> int.to_string(bit_array.byte_size(decoded.payload)),
  )
}
