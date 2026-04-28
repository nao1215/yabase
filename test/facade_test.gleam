import yabase/core/encoding.{InvalidLength}
import yabase/facade

// Thin wiring tests: verify each facade function delegates correctly.
// Spec-vector tests belong in the individual codec test files.

// --- Roundtrip tests for each facade pair ---

pub fn base2_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert facade.decode_base2(facade.encode_base2(data)) == Ok(data)
}

pub fn base8_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert facade.decode_base8(facade.encode_base8(data)) == Ok(data)
}

pub fn base10_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert facade.decode_base10(facade.encode_base10(data)) == Ok(data)
}

pub fn base16_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert facade.decode_base16(facade.encode_base16(data)) == Ok(data)
}

// Issue #19: `encode_base16` emits canonical uppercase per RFC 4648
// §8; `encode_base16_lowercase` is the opt-in lowercase variant. The
// decoder is case-insensitive so both round-trip cleanly.
pub fn base16_uppercase_canonical_test() -> Nil {
  assert facade.encode_base16(<<0xde, 0xad, 0xbe, 0xef>>) == "DEADBEEF"
}

pub fn base16_lowercase_round_trip_test() -> Nil {
  let data = <<"Hello":utf8>>
  let lowercase = facade.encode_base16_lowercase(data)
  assert lowercase == "48656c6c6f"
  assert facade.decode_base16(lowercase) == Ok(data)
}

pub fn base32_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert facade.decode_base32(facade.encode_base32(data)) == Ok(data)
}

pub fn base32_hex_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert facade.decode_base32_hex(facade.encode_base32_hex(data)) == Ok(data)
}

pub fn base32_crockford_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert facade.decode_base32_crockford(facade.encode_base32_crockford(data))
    == Ok(data)
}

pub fn base32_crockford_check_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert facade.decode_base32_crockford_check(
      facade.encode_base32_crockford_check(data),
    )
    == Ok(data)
}

pub fn base32_clockwork_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert facade.decode_base32_clockwork(facade.encode_base32_clockwork(data))
    == Ok(data)
}

pub fn base36_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert facade.decode_base36(facade.encode_base36(data)) == Ok(data)
}

pub fn base45_roundtrip_test() -> Nil {
  let data = <<"Hello!":utf8>>
  assert facade.decode_base45(facade.encode_base45(data)) == Ok(data)
}

pub fn base58_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert facade.decode_base58(facade.encode_base58(data)) == Ok(data)
}

pub fn base58_flickr_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert facade.decode_base58_flickr(facade.encode_base58_flickr(data))
    == Ok(data)
}

pub fn base62_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert facade.decode_base62(facade.encode_base62(data)) == Ok(data)
}

pub fn base64_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert facade.decode_base64(facade.encode_base64(data)) == Ok(data)
}

pub fn base64_urlsafe_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert facade.decode_base64_urlsafe(facade.encode_base64_urlsafe(data))
    == Ok(data)
}

pub fn base64_nopadding_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert facade.decode_base64_nopadding(facade.encode_base64_nopadding(data))
    == Ok(data)
}

pub fn base64_dq_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert facade.decode_base64_dq(facade.encode_base64_dq(data)) == Ok(data)
}

pub fn base91_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert facade.decode_base91(facade.encode_base91(data)) == Ok(data)
}

pub fn ascii85_roundtrip_test() -> Nil {
  let data = <<"test":utf8>>
  assert facade.decode_ascii85(facade.encode_ascii85(data)) == Ok(data)
}

pub fn z85_roundtrip_test() -> Nil {
  let data = <<0x86, 0x4F, 0xD2, 0x6F>>
  let assert Ok(encoded) = facade.encode_z85(data)
  assert facade.decode_z85(encoded) == Ok(data)
}

pub fn z85_encode_non_aligned_error_test() -> Nil {
  assert facade.encode_z85(<<1, 2, 3>>) == Error(InvalidLength(3))
}

pub fn zbase32_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert facade.decode_zbase32(facade.encode_zbase32(data)) == Ok(data)
}

pub fn base64_urlsafe_nopadding_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert facade.decode_base64_urlsafe_nopadding(
      facade.encode_base64_urlsafe_nopadding(data),
    )
    == Ok(data)
}

pub fn adobe_ascii85_roundtrip_test() -> Nil {
  let data = <<"test":utf8>>
  assert facade.decode_adobe_ascii85(facade.encode_adobe_ascii85(data))
    == Ok(data)
}

pub fn rfc1924_base85_roundtrip_test() -> Nil {
  let data = <<1, 2, 3, 4>>
  let assert Ok(encoded) = facade.encode_rfc1924_base85(data)
  assert facade.decode_rfc1924_base85(encoded) == Ok(data)
}
