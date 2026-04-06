import yabase/core/dispatcher
import yabase/core/encoding.{
  AdobeAscii85, Ascii85, Base16, Base32, Base36, Base45, Base58, Base62, Base64,
  Base91, Clockwork, Crockford, DQ, Hex, InvalidLength, NoPadding, RFC4648,
  Rfc1924Base85, Standard, UrlSafe, UrlSafeNoPadding, Z85, ZBase32,
}

// Verify that each encoding roundtrips through the dispatcher.
// These are thin wiring tests, not spec-vector tests.

fn assert_roundtrip(enc, data) {
  let assert Ok(encoded) = dispatcher.encode(enc, data)
  assert dispatcher.decode_as(enc, encoded) == Ok(data)
}

pub fn base16_test() {
  assert_roundtrip(Base16, <<"test":utf8>>)
}

pub fn base32_rfc4648_test() {
  assert_roundtrip(Base32(RFC4648), <<"test":utf8>>)
}

pub fn base32_hex_test() {
  assert_roundtrip(Base32(Hex), <<"test":utf8>>)
}

pub fn base32_crockford_test() {
  assert_roundtrip(Base32(Crockford), <<"test":utf8>>)
}

pub fn base32_clockwork_test() {
  assert_roundtrip(Base32(Clockwork), <<"test":utf8>>)
}

pub fn base64_standard_test() {
  assert_roundtrip(Base64(Standard), <<"test":utf8>>)
}

pub fn base64_urlsafe_test() {
  assert_roundtrip(Base64(UrlSafe), <<"test":utf8>>)
}

pub fn base64_nopadding_test() {
  assert_roundtrip(Base64(NoPadding), <<"test":utf8>>)
}

pub fn base64_dq_test() {
  assert_roundtrip(Base64(DQ), <<"test":utf8>>)
}

pub fn base36_test() {
  assert_roundtrip(Base36, <<"test":utf8>>)
}

pub fn base45_test() {
  assert_roundtrip(Base45, <<"test!!":utf8>>)
}

pub fn base58_test() {
  assert_roundtrip(Base58, <<"test":utf8>>)
}

pub fn base62_test() {
  assert_roundtrip(Base62, <<"test":utf8>>)
}

pub fn base91_test() {
  assert_roundtrip(Base91, <<"test":utf8>>)
}

pub fn ascii85_test() {
  assert_roundtrip(Ascii85, <<"test1234":utf8>>)
}

pub fn z85_test() {
  // Z85 requires 4-byte aligned input
  assert_roundtrip(Z85, <<0x86, 0x4F, 0xD2, 0x6F>>)
}

pub fn z85_encode_non_aligned_error_test() {
  assert dispatcher.encode(Z85, <<1, 2, 3>>) == Error(InvalidLength(3))
}

pub fn zbase32_test() {
  assert_roundtrip(Base32(ZBase32), <<"test":utf8>>)
}

pub fn adobe_ascii85_test() {
  assert_roundtrip(AdobeAscii85, <<"test":utf8>>)
}

pub fn rfc1924_base85_test() {
  assert_roundtrip(Rfc1924Base85, <<1, 2, 3, 4>>)
}

pub fn urlsafe_nopadding_test() {
  assert_roundtrip(Base64(UrlSafeNoPadding), <<"test":utf8>>)
}
