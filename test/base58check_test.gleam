import yabase/base58check
import yabase/core/encoding.{
  InvalidCharacter, InvalidChecksum, InvalidLength, Overflow,
}

// --- Roundtrip ---

pub fn roundtrip_version0_test() {
  let payload = <<1, 2, 3, 4, 5>>
  let assert Ok(encoded) = base58check.encode(0, payload)
  let assert Ok(decoded) = base58check.decode(encoded)
  assert decoded.version == 0
  assert decoded.payload == payload
}

pub fn roundtrip_version5_test() {
  let payload = <<0xde, 0xad, 0xbe, 0xef>>
  let assert Ok(encoded) = base58check.encode(5, payload)
  let assert Ok(decoded) = base58check.decode(encoded)
  assert decoded.version == 5
  assert decoded.payload == payload
}

pub fn roundtrip_empty_payload_test() {
  let assert Ok(encoded) = base58check.encode(0, <<>>)
  let assert Ok(decoded) = base58check.decode(encoded)
  assert decoded.version == 0
  assert decoded.payload == <<>>
}

// --- Determinism ---

pub fn deterministic_encode_test() {
  let assert Ok(a) = base58check.encode(0, <<0xab, 0xcd>>)
  let assert Ok(b) = base58check.encode(0, <<0xab, 0xcd>>)
  assert a == b
}

// --- Version boundary ---

pub fn encode_version_0_ok_test() {
  assert case base58check.encode(0, <<>>) {
    Ok(_) -> True
    _ -> False
  }
}

pub fn encode_version_255_ok_test() {
  assert case base58check.encode(255, <<>>) {
    Ok(_) -> True
    _ -> False
  }
}

pub fn encode_version_256_error_test() {
  assert base58check.encode(256, <<>>) == Error(Overflow)
}

pub fn encode_version_negative_error_test() {
  assert base58check.encode(-1, <<>>) == Error(Overflow)
}

pub fn encode_version_256_same_as_0_prevented_test() {
  // This was the original bug: encode(256, <<>>) silently truncated to version 0
  let assert Ok(v0) = base58check.encode(0, <<>>)
  assert base58check.encode(256, <<>>) != Ok(v0)
}

// --- Published Bitcoin vector ---
// "16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM" decodes to:
//   version = 0x00
//   payload = 0x010966776006953D5567439E5E39F86A0D273BEE
// This verifies SHA-256 double-hash correctness against an external reference.

pub fn bitcoin_wiki_vector_decode_test() {
  let assert Ok(decoded) =
    base58check.decode("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM")
  assert decoded.version == 0
  assert decoded.payload
    == <<
      0x01, 0x09, 0x66, 0x77, 0x60, 0x06, 0x95, 0x3D, 0x55, 0x67, 0x43, 0x9E,
      0x5E, 0x39, 0xF8, 0x6A, 0x0D, 0x27, 0x3B, 0xEE,
    >>
}

// --- 20-byte all-zeros roundtrip ---

pub fn known_vector_all_zeros_20byte_test() {
  let payload = <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  let assert Ok(encoded) = base58check.encode(0, payload)
  let assert Ok(decoded) = base58check.decode(encoded)
  assert decoded.version == 0
  assert decoded.payload == payload
}

// --- Error cases ---

pub fn decode_too_short_test() {
  assert case base58check.decode("1") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

pub fn decode_invalid_checksum_test() {
  let assert Ok(encoded) = base58check.encode(0, <<1, 2, 3>>)
  let corrupted = encoded <> "1"
  assert case base58check.decode(corrupted) {
    Error(InvalidChecksum) -> True
    _ -> False
  }
}

// Invalid Base58 characters must propagate through base58check.decode
pub fn decode_invalid_char_zero_test() {
  assert base58check.decode("0invalid") == Error(InvalidCharacter("0", 0))
}

pub fn decode_invalid_char_uppercase_o_test() {
  assert base58check.decode("O") == Error(InvalidCharacter("O", 0))
}

pub fn decode_invalid_char_uppercase_i_test() {
  assert base58check.decode("I") == Error(InvalidCharacter("I", 0))
}

pub fn decode_invalid_char_lowercase_l_test() {
  assert base58check.decode("l") == Error(InvalidCharacter("l", 0))
}
