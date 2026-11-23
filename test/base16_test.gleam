import codec_test_support
import yabase.{InvalidCharacter, InvalidLength, NonCanonical}

// --- Fixed vectors ---

pub fn encode_empty_test() -> Nil {
  assert codec_test_support.encode(<<>>, using: yabase.Base16) == ""
}

// Issue #19: encode/1 emits canonical RFC 4648 §8 uppercase. Use
// encode_lowercase/1 (covered separately below) for the opt-in
// non-canonical form.

pub fn encode_hello_test() -> Nil {
  assert codec_test_support.encode(<<"Hello":utf8>>, using: yabase.Base16)
    == "48656C6C6F"
}

pub fn encode_single_byte_test() -> Nil {
  assert codec_test_support.encode(<<255>>, using: yabase.Base16) == "FF"
}

pub fn encode_zero_byte_test() -> Nil {
  assert codec_test_support.encode(<<0>>, using: yabase.Base16) == "00"
}

pub fn encode_binary_test() -> Nil {
  assert codec_test_support.encode(
      <<0xde, 0xad, 0xbe, 0xef>>,
      using: yabase.Base16,
    )
    == "DEADBEEF"
}

pub fn encode_leading_zeros_test() -> Nil {
  assert codec_test_support.encode(<<0, 0, 1>>, using: yabase.Base16)
    == "000001"
}

pub fn encode_all_zeros_test() -> Nil {
  assert codec_test_support.encode(<<0, 0, 0, 0>>, using: yabase.Base16)
    == "00000000"
}

pub fn encode_high_bit_bytes_test() -> Nil {
  assert codec_test_support.encode(<<0xff, 0x80, 0x7f>>, using: yabase.Base16)
    == "FF807F"
}

// --- Issue #19: encode_lowercase opt-in form ---

pub fn encode_lowercase_hello_test() -> Nil {
  assert codec_test_support.encode(
      <<"Hello":utf8>>,
      using: yabase.Base16Lowercase,
    )
    == "48656c6c6f"
}

pub fn encode_lowercase_binary_test() -> Nil {
  assert codec_test_support.encode(
      <<0xde, 0xad, 0xbe, 0xef>>,
      using: yabase.Base16Lowercase,
    )
    == "deadbeef"
}

pub fn encode_lowercase_decoder_round_trip_test() -> Nil {
  // Decoder is case-insensitive, so the lowercase encoder still
  // round-trips through the same `decode/1` entry point.
  let data = <<0xff, 0x80, 0x7f, 0x00, 0x10>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base16Lowercase),
      using: yabase.Base16,
    )
    == Ok(data)
}

pub fn encode_uppercase_decoder_round_trip_test() -> Nil {
  let data = <<0xff, 0x80, 0x7f, 0x00, 0x10>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base16),
      using: yabase.Base16,
    )
    == Ok(data)
}

// --- Decode fixed vectors ---

pub fn decode_empty_test() -> Nil {
  assert yabase.decode("", using: yabase.Base16) == Ok(<<>>)
}

pub fn decode_hello_test() -> Nil {
  assert yabase.decode("48656c6c6f", using: yabase.Base16)
    == Ok(<<"Hello":utf8>>)
}

pub fn decode_uppercase_test() -> Nil {
  assert yabase.decode("48656C6C6F", using: yabase.Base16)
    == Ok(<<"Hello":utf8>>)
}

// --- Decode error cases ---

pub fn decode_invalid_length_test() -> Nil {
  assert yabase.decode("abc", using: yabase.Base16) == Error(InvalidLength(3))
}

pub fn decode_invalid_char_test() -> Nil {
  assert yabase.decode("zz", using: yabase.Base16)
    == Error(InvalidCharacter("z", 0))
}

pub fn decode_invalid_char_position_test() -> Nil {
  assert yabase.decode("0g", using: yabase.Base16)
    == Error(InvalidCharacter("g", 1))
}

// --- Roundtrip ---

pub fn roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base16),
      using: yabase.Base16,
    )
    == Ok(data)
}

pub fn roundtrip_empty_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<>>, using: yabase.Base16),
      using: yabase.Base16,
    )
    == Ok(<<>>)
}

pub fn roundtrip_single_zero_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<0>>, using: yabase.Base16),
      using: yabase.Base16,
    )
    == Ok(<<0>>)
}

pub fn roundtrip_leading_zeros_test() -> Nil {
  let data = <<0, 0, 0, 42>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base16),
      using: yabase.Base16,
    )
    == Ok(data)
}

pub fn roundtrip_high_bits_test() -> Nil {
  let data = <<0xff, 0xfe, 0xfd, 0x80, 0x00>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base16),
      using: yabase.Base16,
    )
    == Ok(data)
}

// ===== decode_strict (RFC 4648 §8 canonical-uppercase check) =====

pub fn decode_strict_canonical_uppercase_passes_test() -> Nil {
  // Canonical RFC 4648 §8 form is uppercase A-F.
  assert yabase.decode_base16_strict("DEADBEEF")
    == Ok(<<0xde, 0xad, 0xbe, 0xef>>)
}

pub fn decode_strict_lowercase_rejected_test() -> Nil {
  // Lowercase is the opt-in non-canonical form (encode_lowercase).
  // The strict path rejects it even though decode/1 accepts it.
  assert yabase.decode_base16_strict("deadbeef") == Error(NonCanonical)
}

pub fn decode_strict_mixed_case_rejected_test() -> Nil {
  // Mixed case is non-canonical.
  assert yabase.decode_base16_strict("DeAdBeEf") == Error(NonCanonical)
}

pub fn decode_strict_propagates_invalid_character_test() -> Nil {
  // Non-hex characters surface unchanged from decode/1 — strict
  // does not mask other failure modes.
  assert case yabase.decode_base16_strict("Z0") {
    Error(InvalidCharacter(_, _)) -> True
    _ -> False
  }
}

pub fn decode_strict_propagates_invalid_length_test() -> Nil {
  // Odd-length input surfaces InvalidLength from decode/1.
  assert case yabase.decode_base16_strict("ABC") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

pub fn decode_strict_empty_passes_test() -> Nil {
  // Empty input encodes to empty string — that is canonical.
  assert yabase.decode_base16_strict("") == Ok(<<>>)
}
