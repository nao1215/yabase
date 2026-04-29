//// Smoke test for the `core/encoding` smart constructors. Each
//// constructor returns the same `Encoding` value as the direct ADT
//// constructor — the test pins that equivalence so a future refactor
//// to `pub opaque type` can keep external callers on the smart
//// constructor path with no behavioural change.

import yabase/core/encoding.{
  Adobe, Base10, Base16, Base2, Base32, Base36, Base45, Base58, Base62, Base64,
  Base8, Base85, Base91, Bitcoin, Btoa, Clockwork, Crockford, CrockfordCheck, DQ,
  Flickr, Hex, NoPadding, RFC4648, Rfc1924, Standard, UrlSafe, UrlSafeNoPadding,
  Z85, ZBase32,
}

pub fn base2_smart_constructor_test() -> Nil {
  assert encoding.base2() == Base2
}

pub fn base8_smart_constructor_test() -> Nil {
  assert encoding.base8() == Base8
}

pub fn base10_smart_constructor_test() -> Nil {
  assert encoding.base10() == Base10
}

pub fn base16_smart_constructor_test() -> Nil {
  assert encoding.base16() == Base16
}

pub fn base32_rfc4648_smart_constructor_test() -> Nil {
  assert encoding.base32_rfc4648() == Base32(RFC4648)
}

pub fn base32_hex_smart_constructor_test() -> Nil {
  assert encoding.base32_hex() == Base32(Hex)
}

pub fn base32_crockford_smart_constructor_test() -> Nil {
  assert encoding.base32_crockford() == Base32(Crockford)
}

pub fn base32_crockford_check_smart_constructor_test() -> Nil {
  assert encoding.base32_crockford_check() == Base32(CrockfordCheck)
}

pub fn base32_clockwork_smart_constructor_test() -> Nil {
  assert encoding.base32_clockwork() == Base32(Clockwork)
}

pub fn base32_z_base32_smart_constructor_test() -> Nil {
  assert encoding.base32_z_base32() == Base32(ZBase32)
}

pub fn base36_smart_constructor_test() -> Nil {
  assert encoding.base36() == Base36
}

pub fn base45_smart_constructor_test() -> Nil {
  assert encoding.base45() == Base45
}

pub fn base58_bitcoin_smart_constructor_test() -> Nil {
  assert encoding.base58_bitcoin() == Base58(Bitcoin)
}

pub fn base58_flickr_smart_constructor_test() -> Nil {
  assert encoding.base58_flickr() == Base58(Flickr)
}

pub fn base62_smart_constructor_test() -> Nil {
  assert encoding.base62() == Base62
}

pub fn base64_standard_smart_constructor_test() -> Nil {
  assert encoding.base64_standard() == Base64(Standard)
}

pub fn base64_url_safe_smart_constructor_test() -> Nil {
  assert encoding.base64_url_safe() == Base64(UrlSafe)
}

pub fn base64_no_padding_smart_constructor_test() -> Nil {
  assert encoding.base64_no_padding() == Base64(NoPadding)
}

pub fn base64_url_safe_no_padding_smart_constructor_test() -> Nil {
  assert encoding.base64_url_safe_no_padding() == Base64(UrlSafeNoPadding)
}

pub fn base64_dq_smart_constructor_test() -> Nil {
  assert encoding.base64_dq() == Base64(DQ)
}

pub fn base85_btoa_smart_constructor_test() -> Nil {
  assert encoding.base85_btoa() == Base85(Btoa)
}

pub fn base85_adobe_smart_constructor_test() -> Nil {
  assert encoding.base85_adobe() == Base85(Adobe)
}

pub fn base85_rfc1924_smart_constructor_test() -> Nil {
  assert encoding.base85_rfc1924() == Base85(Rfc1924)
}

pub fn base85_z85_smart_constructor_test() -> Nil {
  assert encoding.base85_z85() == Base85(Z85)
}

pub fn base91_smart_constructor_test() -> Nil {
  assert encoding.base91() == Base91
}
