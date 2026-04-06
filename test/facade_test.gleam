import yabase/core/encoding.{InvalidLength}
import yabase/facade

// Thin wiring tests: verify each facade function delegates correctly.
// Spec-vector tests belong in the individual codec test files.

// --- Roundtrip tests for each facade pair ---

pub fn base16_roundtrip_test() {
  let data = <<"Hello":utf8>>
  assert facade.decode_base16(facade.encode_base16(data)) == Ok(data)
}

pub fn base32_roundtrip_test() {
  let data = <<"Hello":utf8>>
  assert facade.decode_base32(facade.encode_base32(data)) == Ok(data)
}

pub fn base32_hex_roundtrip_test() {
  let data = <<"Hello":utf8>>
  assert facade.decode_base32_hex(facade.encode_base32_hex(data)) == Ok(data)
}

pub fn base32_crockford_roundtrip_test() {
  let data = <<"Hello":utf8>>
  assert facade.decode_base32_crockford(facade.encode_base32_crockford(data))
    == Ok(data)
}

pub fn base32_clockwork_roundtrip_test() {
  let data = <<"Hello":utf8>>
  assert facade.decode_base32_clockwork(facade.encode_base32_clockwork(data))
    == Ok(data)
}

pub fn base36_roundtrip_test() {
  let data = <<"Hello":utf8>>
  assert facade.decode_base36(facade.encode_base36(data)) == Ok(data)
}

pub fn base45_roundtrip_test() {
  let data = <<"Hello!":utf8>>
  assert facade.decode_base45(facade.encode_base45(data)) == Ok(data)
}

pub fn base58_roundtrip_test() {
  let data = <<"Hello":utf8>>
  assert facade.decode_base58(facade.encode_base58(data)) == Ok(data)
}

pub fn base62_roundtrip_test() {
  let data = <<"Hello":utf8>>
  assert facade.decode_base62(facade.encode_base62(data)) == Ok(data)
}

pub fn base64_roundtrip_test() {
  let data = <<"Hello":utf8>>
  assert facade.decode_base64(facade.encode_base64(data)) == Ok(data)
}

pub fn base64_urlsafe_roundtrip_test() {
  let data = <<"Hello":utf8>>
  assert facade.decode_base64_urlsafe(facade.encode_base64_urlsafe(data))
    == Ok(data)
}

pub fn base64_nopadding_roundtrip_test() {
  let data = <<"Hello":utf8>>
  assert facade.decode_base64_nopadding(facade.encode_base64_nopadding(data))
    == Ok(data)
}

pub fn base64_dq_roundtrip_test() {
  let data = <<"Hello":utf8>>
  assert facade.decode_base64_dq(facade.encode_base64_dq(data)) == Ok(data)
}

pub fn base91_roundtrip_test() {
  let data = <<"Hello":utf8>>
  assert facade.decode_base91(facade.encode_base91(data)) == Ok(data)
}

pub fn ascii85_roundtrip_test() {
  let data = <<"test":utf8>>
  assert facade.decode_ascii85(facade.encode_ascii85(data)) == Ok(data)
}

pub fn z85_roundtrip_test() {
  let data = <<0x86, 0x4F, 0xD2, 0x6F>>
  let assert Ok(encoded) = facade.encode_z85(data)
  assert facade.decode_z85(encoded) == Ok(data)
}

pub fn z85_encode_non_aligned_error_test() {
  assert facade.encode_z85(<<1, 2, 3>>) == Error(InvalidLength(3))
}

pub fn zbase32_roundtrip_test() {
  let data = <<"Hello":utf8>>
  assert facade.decode_zbase32(facade.encode_zbase32(data)) == Ok(data)
}

pub fn base64_urlsafe_nopadding_roundtrip_test() {
  let data = <<"Hello":utf8>>
  assert facade.decode_base64_urlsafe_nopadding(
      facade.encode_base64_urlsafe_nopadding(data),
    )
    == Ok(data)
}

pub fn adobe_ascii85_roundtrip_test() {
  let data = <<"test":utf8>>
  assert facade.decode_adobe_ascii85(facade.encode_adobe_ascii85(data))
    == Ok(data)
}

pub fn rfc1924_base85_roundtrip_test() {
  let data = <<1, 2, 3, 4>>
  let assert Ok(encoded) = facade.encode_rfc1924_base85(data)
  assert facade.decode_rfc1924_base85(encoded) == Ok(data)
}
