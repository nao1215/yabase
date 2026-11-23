import yabase

// Match the public subject-first signature in positive roundtrip tests.
// nolint: label_possible
pub fn encode(value: BitArray, using encoding: yabase.Encoding) -> String {
  let assert Ok(encoded) = yabase.encode(value, using: encoding)
  encoded
}
