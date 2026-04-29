import yabase/base58check
import yabase/core/error.{
  InvalidCharacter, InvalidChecksum, InvalidLength, Overflow,
}

// --- Roundtrip ---

pub fn roundtrip_version0_test() -> Nil {
  let payload = <<1, 2, 3, 4, 5>>
  let assert Ok(encoded) = base58check.encode(0, payload)
  let assert Ok(decoded) = base58check.decode(encoded)
  assert decoded.version == 0
  assert decoded.payload == payload
}

pub fn roundtrip_version5_test() -> Nil {
  let payload = <<0xde, 0xad, 0xbe, 0xef>>
  let assert Ok(encoded) = base58check.encode(5, payload)
  let assert Ok(decoded) = base58check.decode(encoded)
  assert decoded.version == 5
  assert decoded.payload == payload
}

pub fn roundtrip_empty_payload_test() -> Nil {
  let assert Ok(encoded) = base58check.encode(0, <<>>)
  let assert Ok(decoded) = base58check.decode(encoded)
  assert decoded.version == 0
  assert decoded.payload == <<>>
}

// --- Determinism ---

pub fn deterministic_encode_test() -> Nil {
  let assert Ok(a) = base58check.encode(0, <<0xab, 0xcd>>)
  let assert Ok(b) = base58check.encode(0, <<0xab, 0xcd>>)
  assert a == b
}

// --- Version boundary ---

pub fn encode_version_0_ok_test() -> Nil {
  assert case base58check.encode(0, <<>>) {
    Ok(_) -> True
    _ -> False
  }
}

pub fn encode_version_255_ok_test() -> Nil {
  assert case base58check.encode(255, <<>>) {
    Ok(_) -> True
    _ -> False
  }
}

pub fn encode_version_256_error_test() -> Nil {
  assert base58check.encode(256, <<>>) == Error(Overflow)
}

pub fn encode_version_negative_error_test() -> Nil {
  assert base58check.encode(-1, <<>>) == Error(Overflow)
}

pub fn encode_version_256_same_as_0_prevented_test() -> Nil {
  // This was the original bug: encode(256, <<>>) silently truncated to version 0
  let assert Ok(v0) = base58check.encode(0, <<>>)
  assert base58check.encode(256, <<>>) != Ok(v0)
}

// --- Published Bitcoin vector ---
// "16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM" decodes to:
//   version = 0x00
//   payload = 0x010966776006953D5567439E5E39F86A0D273BEE
// This verifies SHA-256 double-hash correctness against an external reference.

pub fn bitcoin_wiki_vector_decode_test() -> Nil {
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

pub fn known_vector_all_zeros_20byte_test() -> Nil {
  let payload = <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  let assert Ok(encoded) = base58check.encode(0, payload)
  let assert Ok(decoded) = base58check.decode(encoded)
  assert decoded.version == 0
  assert decoded.payload == payload
}

// --- Error cases ---

pub fn decode_too_short_test() -> Nil {
  assert case base58check.decode("1") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

pub fn decode_invalid_checksum_test() -> Nil {
  let assert Ok(encoded) = base58check.encode(0, <<1, 2, 3>>)
  let corrupted = encoded <> "1"
  assert case base58check.decode(corrupted) {
    Error(InvalidChecksum) -> True
    _ -> False
  }
}

// Invalid Base58 characters must propagate through base58check.decode
pub fn decode_invalid_char_zero_test() -> Nil {
  assert base58check.decode("0invalid") == Error(InvalidCharacter("0", 0))
}

pub fn decode_invalid_char_uppercase_o_test() -> Nil {
  assert base58check.decode("O") == Error(InvalidCharacter("O", 0))
}

pub fn decode_invalid_char_uppercase_i_test() -> Nil {
  assert base58check.decode("I") == Error(InvalidCharacter("I", 0))
}

pub fn decode_invalid_char_lowercase_l_test() -> Nil {
  assert base58check.decode("l") == Error(InvalidCharacter("l", 0))
}

pub fn decode_invalid_char_middle_test() -> Nil {
  assert base58check.decode("111O1111") == Error(InvalidCharacter("O", 3))
}

// === Cross-reference: bitcoinjs/bs58check fixtures ===
// Source: https://github.com/bitcoinjs/bs58check

pub fn bs58check_vector_1agn_test() -> Nil {
  let assert Ok(decoded) =
    base58check.decode("1AGNa15ZQXAZUgFiqJ2i7Z2DPU2J6hW62i")
  assert decoded.version == 0x00
  assert decoded.payload
    == <<
      0x65,
      0xa1,
      0x60,
      0x59,
      0x86,
      0x4a,
      0x2f,
      0xdb,
      0xc7,
      0xc9,
      0x9a,
      0x47,
      0x23,
      0xa8,
      0x39,
      0x5b,
      0xc6,
      0xf1,
      0x88,
      0xeb,
    >>
}

pub fn bs58check_vector_3cmn_test() -> Nil {
  let assert Ok(decoded) =
    base58check.decode("3CMNFxN1oHBc4R1EpboAL5yzHGgE611Xou")
  assert decoded.version == 0x05
  assert decoded.payload
    == <<
      0x74,
      0xf2,
      0x09,
      0xf6,
      0xea,
      0x90,
      0x7e,
      0x2e,
      0xa4,
      0x8f,
      0x74,
      0xfa,
      0xe0,
      0x57,
      0x82,
      0xae,
      0x8a,
      0x66,
      0x52,
      0x57,
    >>
}

pub fn bs58check_vector_mo9n_test() -> Nil {
  let assert Ok(decoded) =
    base58check.decode("mo9ncXisMeAoXwqcV5EWuyncbmCcQN4rVs")
  assert decoded.version == 0x6f
}

pub fn bs58check_vector_1ax4_test() -> Nil {
  let assert Ok(decoded) =
    base58check.decode("1Ax4gZtb7gAit2TivwejZHYtNNLT18PUXJ")
  assert decoded.version == 0x00
  assert decoded.payload
    == <<
      0x6d,
      0x23,
      0x15,
      0x6c,
      0xbb,
      0xdc,
      0xc8,
      0x2a,
      0x5a,
      0x47,
      0xee,
      0xe4,
      0xc2,
      0xc7,
      0xc5,
      0x83,
      0xc1,
      0x8b,
      0x6b,
      0xf4,
    >>
}
