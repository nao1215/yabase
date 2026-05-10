import yabase/base16
import yabase/core/error.{InvalidCharacter, InvalidLength, NonCanonical}

// --- Fixed vectors ---

pub fn encode_empty_test() -> Nil {
  assert base16.encode(<<>>) == ""
}

// Issue #19: encode/1 emits canonical RFC 4648 §8 uppercase. Use
// encode_lowercase/1 (covered separately below) for the opt-in
// non-canonical form.

pub fn encode_hello_test() -> Nil {
  assert base16.encode(<<"Hello":utf8>>) == "48656C6C6F"
}

pub fn encode_single_byte_test() -> Nil {
  assert base16.encode(<<255>>) == "FF"
}

pub fn encode_zero_byte_test() -> Nil {
  assert base16.encode(<<0>>) == "00"
}

pub fn encode_binary_test() -> Nil {
  assert base16.encode(<<0xde, 0xad, 0xbe, 0xef>>) == "DEADBEEF"
}

pub fn encode_leading_zeros_test() -> Nil {
  assert base16.encode(<<0, 0, 1>>) == "000001"
}

pub fn encode_all_zeros_test() -> Nil {
  assert base16.encode(<<0, 0, 0, 0>>) == "00000000"
}

pub fn encode_high_bit_bytes_test() -> Nil {
  assert base16.encode(<<0xff, 0x80, 0x7f>>) == "FF807F"
}

// --- Issue #19: encode_lowercase opt-in form ---

pub fn encode_lowercase_hello_test() -> Nil {
  assert base16.encode_lowercase(<<"Hello":utf8>>) == "48656c6c6f"
}

pub fn encode_lowercase_binary_test() -> Nil {
  assert base16.encode_lowercase(<<0xde, 0xad, 0xbe, 0xef>>) == "deadbeef"
}

pub fn encode_lowercase_decoder_round_trip_test() -> Nil {
  // Decoder is case-insensitive, so the lowercase encoder still
  // round-trips through the same `decode/1` entry point.
  let data = <<0xff, 0x80, 0x7f, 0x00, 0x10>>
  assert base16.decode(base16.encode_lowercase(data)) == Ok(data)
}

pub fn encode_uppercase_decoder_round_trip_test() -> Nil {
  let data = <<0xff, 0x80, 0x7f, 0x00, 0x10>>
  assert base16.decode(base16.encode(data)) == Ok(data)
}

// --- Decode fixed vectors ---

pub fn decode_empty_test() -> Nil {
  assert base16.decode("") == Ok(<<>>)
}

pub fn decode_hello_test() -> Nil {
  assert base16.decode("48656c6c6f") == Ok(<<"Hello":utf8>>)
}

pub fn decode_uppercase_test() -> Nil {
  assert base16.decode("48656C6C6F") == Ok(<<"Hello":utf8>>)
}

// --- Decode error cases ---

pub fn decode_invalid_length_test() -> Nil {
  assert base16.decode("abc") == Error(InvalidLength(3))
}

pub fn decode_invalid_char_test() -> Nil {
  assert base16.decode("zz") == Error(InvalidCharacter("z", 0))
}

pub fn decode_invalid_char_position_test() -> Nil {
  assert base16.decode("0g") == Error(InvalidCharacter("g", 1))
}

// --- Roundtrip ---

pub fn roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert base16.decode(base16.encode(data)) == Ok(data)
}

pub fn roundtrip_empty_test() -> Nil {
  assert base16.decode(base16.encode(<<>>)) == Ok(<<>>)
}

pub fn roundtrip_single_zero_test() -> Nil {
  assert base16.decode(base16.encode(<<0>>)) == Ok(<<0>>)
}

pub fn roundtrip_leading_zeros_test() -> Nil {
  let data = <<0, 0, 0, 42>>
  assert base16.decode(base16.encode(data)) == Ok(data)
}

pub fn roundtrip_high_bits_test() -> Nil {
  let data = <<0xff, 0xfe, 0xfd, 0x80, 0x00>>
  assert base16.decode(base16.encode(data)) == Ok(data)
}

// ===== decode_strict (RFC 4648 §8 canonical-uppercase check) =====

pub fn decode_strict_canonical_uppercase_passes_test() -> Nil {
  // Canonical RFC 4648 §8 form is uppercase A-F.
  assert base16.decode_strict("DEADBEEF") == Ok(<<0xde, 0xad, 0xbe, 0xef>>)
}

pub fn decode_strict_lowercase_rejected_test() -> Nil {
  // Lowercase is the opt-in non-canonical form (encode_lowercase).
  // The strict path rejects it even though decode/1 accepts it.
  assert base16.decode_strict("deadbeef") == Error(NonCanonical)
}

pub fn decode_strict_mixed_case_rejected_test() -> Nil {
  // Mixed case is non-canonical.
  assert base16.decode_strict("DeAdBeEf") == Error(NonCanonical)
}

pub fn decode_strict_propagates_invalid_character_test() -> Nil {
  // Non-hex characters surface unchanged from decode/1 — strict
  // does not mask other failure modes.
  assert case base16.decode_strict("Z0") {
    Error(InvalidCharacter(_, _)) -> True
    _ -> False
  }
}

pub fn decode_strict_propagates_invalid_length_test() -> Nil {
  // Odd-length input surfaces InvalidLength from decode/1.
  assert case base16.decode_strict("ABC") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

pub fn decode_strict_empty_passes_test() -> Nil {
  // Empty input encodes to empty string — that is canonical.
  assert base16.decode_strict("") == Ok(<<>>)
}
