import yabase/core/encoding.{type Encoding}
import yabase/core/error.{InvalidLength}

// Verify that each encoding roundtrips through the dispatcher.
// These are thin wiring tests, not spec-vector tests.

fn assert_roundtrip(enc: Encoding, data: BitArray) -> Nil {
  let assert Ok(encoded) = encoding.encode(enc, data)
  assert encoding.decode_as(enc, encoded) == Ok(data)
}

pub fn base2_test() -> Nil {
  assert_roundtrip(encoding.base2(), <<"test":utf8>>)
}

pub fn base8_test() -> Nil {
  assert_roundtrip(encoding.base8(), <<"test":utf8>>)
}

pub fn base10_test() -> Nil {
  assert_roundtrip(encoding.base10(), <<"test":utf8>>)
}

pub fn base16_test() -> Nil {
  assert_roundtrip(encoding.base16(), <<"test":utf8>>)
}

pub fn base32_rfc4648_test() -> Nil {
  assert_roundtrip(encoding.base32_rfc4648(), <<"test":utf8>>)
}

pub fn base32_hex_test() -> Nil {
  assert_roundtrip(encoding.base32_hex(), <<"test":utf8>>)
}

pub fn base32_crockford_test() -> Nil {
  assert_roundtrip(encoding.base32_crockford(), <<"test":utf8>>)
}

pub fn base32_crockford_check_test() -> Nil {
  assert_roundtrip(encoding.base32_crockford_check(), <<"test":utf8>>)
}

pub fn base32_clockwork_test() -> Nil {
  assert_roundtrip(encoding.base32_clockwork(), <<"test":utf8>>)
}

pub fn base64_standard_test() -> Nil {
  assert_roundtrip(encoding.base64_standard(), <<"test":utf8>>)
}

pub fn base64_urlsafe_test() -> Nil {
  assert_roundtrip(encoding.base64_url_safe(), <<"test":utf8>>)
}

pub fn base64_nopadding_test() -> Nil {
  assert_roundtrip(encoding.base64_no_padding(), <<"test":utf8>>)
}

pub fn base64_dq_test() -> Nil {
  assert_roundtrip(encoding.base64_dq(), <<"test":utf8>>)
}

pub fn base36_test() -> Nil {
  assert_roundtrip(encoding.base36(), <<"test":utf8>>)
}

pub fn base45_test() -> Nil {
  assert_roundtrip(encoding.base45(), <<"test!!":utf8>>)
}

pub fn base58_bitcoin_test() -> Nil {
  assert_roundtrip(encoding.base58_bitcoin(), <<"test":utf8>>)
}

pub fn base58_flickr_test() -> Nil {
  assert_roundtrip(encoding.base58_flickr(), <<"test":utf8>>)
}

pub fn base62_test() -> Nil {
  assert_roundtrip(encoding.base62(), <<"test":utf8>>)
}

pub fn base85_btoa_test() -> Nil {
  assert_roundtrip(encoding.base85_btoa(), <<"test1234":utf8>>)
}

pub fn base85_adobe_test() -> Nil {
  assert_roundtrip(encoding.base85_adobe(), <<"test":utf8>>)
}

pub fn base85_rfc1924_test() -> Nil {
  assert_roundtrip(encoding.base85_rfc1924(), <<1, 2, 3, 4>>)
}

pub fn base85_z85_test() -> Nil {
  assert_roundtrip(encoding.base85_z85(), <<0x86, 0x4F, 0xD2, 0x6F>>)
}

pub fn base85_z85_encode_non_aligned_error_test() -> Nil {
  assert encoding.encode(encoding.base85_z85(), <<1, 2, 3>>)
    == Error(InvalidLength(3))
}

pub fn base91_test() -> Nil {
  assert_roundtrip(encoding.base91(), <<"test":utf8>>)
}

pub fn zbase32_test() -> Nil {
  assert_roundtrip(encoding.base32_z_base32(), <<"test":utf8>>)
}

pub fn urlsafe_nopadding_test() -> Nil {
  assert_roundtrip(encoding.base64_url_safe_no_padding(), <<"test":utf8>>)
}
