/// Bech32/Bech32m encoding demo (BIP 173 / BIP 350).
///
/// yabase's bech32 module is a byte-payload convenience API: it takes
/// raw bytes, converts to 5-bit groups internally, and appends the
/// checksum. This example encodes an arbitrary byte payload with HRP "bc"
/// and does NOT construct a valid Bitcoin SegWit address (no witness
/// version/program semantics are applied).
import gleam/io
import yabase/bech32
import yabase/core/encoding.{Bech32 as Bech32V, Bech32m as Bech32mV}

pub fn main() -> Nil {
  // Bech32 encode with HRP "bc" (arbitrary payload, not a SegWit address)
  let data = <<0, 14, 20, 15, 7, 28, 0, 15, 7, 4>>
  let assert Ok(encoded) = bech32.encode(Bech32V, "bc", data)
  io.println("Bech32:  " <> encoded)

  // Bech32m encode (BIP 350 improved checksum)
  let assert Ok(encoded_m) = bech32.encode(Bech32mV, "bc", data)
  io.println("Bech32m: " <> encoded_m)

  // Decode auto-detects variant
  let assert Ok(decoded) = bech32.decode(encoded)
  io.println("HRP: " <> decoded.hrp)
}
