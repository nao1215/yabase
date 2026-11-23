import yabase.{type Encoding, InvalidLength}

// Verify that each encoding roundtrips through the dispatcher.
// These are thin wiring tests, not spec-vector tests.

fn assert_roundtrip(enc: Encoding, data: BitArray) -> Nil {
  let assert Ok(encoded) = yabase.encode(data, using: enc)
  assert yabase.decode(encoded, using: enc) == Ok(data)
}

pub fn base2_test() -> Nil {
  assert_roundtrip(yabase.Base2, <<"test":utf8>>)
}

pub fn base8_test() -> Nil {
  assert_roundtrip(yabase.Base8, <<"test":utf8>>)
}

pub fn base10_test() -> Nil {
  assert_roundtrip(yabase.Base10, <<"test":utf8>>)
}

pub fn base16_test() -> Nil {
  assert_roundtrip(yabase.Base16, <<"test":utf8>>)
}

pub fn base32_rfc4648_test() -> Nil {
  assert_roundtrip(yabase.Base32Rfc4648, <<"test":utf8>>)
}

pub fn base32_hex_test() -> Nil {
  assert_roundtrip(yabase.Base32Hex, <<"test":utf8>>)
}

pub fn base32_crockford_test() -> Nil {
  assert_roundtrip(yabase.Base32Crockford, <<"test":utf8>>)
}

pub fn base32_crockford_check_test() -> Nil {
  assert_roundtrip(yabase.Base32CrockfordCheck, <<"test":utf8>>)
}

pub fn base32_clockwork_test() -> Nil {
  assert_roundtrip(yabase.Base32Clockwork, <<"test":utf8>>)
}

pub fn base64_standard_test() -> Nil {
  assert_roundtrip(yabase.Base64, <<"test":utf8>>)
}

pub fn base64_urlsafe_test() -> Nil {
  assert_roundtrip(yabase.Base64UrlSafe, <<"test":utf8>>)
}

pub fn base64_nopadding_test() -> Nil {
  assert_roundtrip(yabase.Base64NoPadding, <<"test":utf8>>)
}

pub fn base64_dq_test() -> Nil {
  assert_roundtrip(yabase.Base64Dq, <<"test":utf8>>)
}

pub fn base36_test() -> Nil {
  assert_roundtrip(yabase.Base36, <<"test":utf8>>)
}

pub fn base45_test() -> Nil {
  assert_roundtrip(yabase.Base45, <<"test!!":utf8>>)
}

pub fn base58_bitcoin_test() -> Nil {
  assert_roundtrip(yabase.Base58Bitcoin, <<"test":utf8>>)
}

pub fn base58_flickr_test() -> Nil {
  assert_roundtrip(yabase.Base58Flickr, <<"test":utf8>>)
}

pub fn base62_test() -> Nil {
  assert_roundtrip(yabase.Base62, <<"test":utf8>>)
}

pub fn base85_btoa_test() -> Nil {
  assert_roundtrip(yabase.Ascii85, <<"test1234":utf8>>)
}

pub fn base85_adobe_test() -> Nil {
  assert_roundtrip(yabase.AdobeAscii85, <<"test":utf8>>)
}

pub fn base85_rfc1924_test() -> Nil {
  assert_roundtrip(yabase.Rfc1924Base85, <<1, 2, 3, 4>>)
}

pub fn base85_z85_test() -> Nil {
  assert_roundtrip(yabase.Z85, <<0x86, 0x4F, 0xD2, 0x6F>>)
}

pub fn base85_z85_encode_non_aligned_error_test() -> Nil {
  assert yabase.encode(<<1, 2, 3>>, using: yabase.Z85)
    == Error(InvalidLength(3))
}

pub fn base91_test() -> Nil {
  assert_roundtrip(yabase.Base91, <<"test":utf8>>)
}

pub fn zbase32_test() -> Nil {
  assert_roundtrip(yabase.Zbase32, <<"test":utf8>>)
}

pub fn urlsafe_nopadding_test() -> Nil {
  assert_roundtrip(yabase.Base64UrlSafeNoPadding, <<"test":utf8>>)
}
