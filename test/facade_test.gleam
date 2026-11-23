import codec_test_support
import yabase.{InvalidLength, NonCanonical}

// Thin wiring tests: verify each facade function delegates correctly.
// Spec-vector tests belong in the individual codec test files.

// --- Roundtrip tests for each facade pair ---

pub fn base2_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base2),
      using: yabase.Base2,
    )
    == Ok(data)
}

pub fn base8_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base8),
      using: yabase.Base8,
    )
    == Ok(data)
}

pub fn base10_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base10),
      using: yabase.Base10,
    )
    == Ok(data)
}

pub fn base16_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base16),
      using: yabase.Base16,
    )
    == Ok(data)
}

// Issue #19: `encode_base16` emits canonical uppercase per RFC 4648
// §8; `encode_base16_lowercase` is the opt-in lowercase variant. The
// decoder is case-insensitive so both round-trip cleanly.
pub fn base16_uppercase_canonical_test() -> Nil {
  assert codec_test_support.encode(
      <<0xde, 0xad, 0xbe, 0xef>>,
      using: yabase.Base16,
    )
    == "DEADBEEF"
}

pub fn base16_lowercase_round_trip_test() -> Nil {
  let data = <<"Hello":utf8>>
  let lowercase = codec_test_support.encode(data, using: yabase.Base16Lowercase)
  assert lowercase == "48656c6c6f"
  assert yabase.decode(lowercase, using: yabase.Base16) == Ok(data)
}

pub fn base32_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base32Rfc4648),
      using: yabase.Base32Rfc4648,
    )
    == Ok(data)
}

pub fn base32_hex_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base32Hex),
      using: yabase.Base32Hex,
    )
    == Ok(data)
}

pub fn base32_crockford_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base32Crockford),
      using: yabase.Base32Crockford,
    )
    == Ok(data)
}

pub fn base32_crockford_check_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base32CrockfordCheck),
      using: yabase.Base32CrockfordCheck,
    )
    == Ok(data)
}

pub fn base32_clockwork_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base32Clockwork),
      using: yabase.Base32Clockwork,
    )
    == Ok(data)
}

pub fn base36_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base36),
      using: yabase.Base36,
    )
    == Ok(data)
}

pub fn base45_roundtrip_test() -> Nil {
  let data = <<"Hello!":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base45),
      using: yabase.Base45,
    )
    == Ok(data)
}

pub fn base58_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base58Bitcoin),
      using: yabase.Base58Bitcoin,
    )
    == Ok(data)
}

pub fn base58_flickr_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base58Flickr),
      using: yabase.Base58Flickr,
    )
    == Ok(data)
}

pub fn base62_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base62),
      using: yabase.Base62,
    )
    == Ok(data)
}

pub fn base64_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base64),
      using: yabase.Base64,
    )
    == Ok(data)
}

pub fn base64_urlsafe_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base64UrlSafe),
      using: yabase.Base64UrlSafe,
    )
    == Ok(data)
}

pub fn base64_nopadding_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base64NoPadding),
      using: yabase.Base64NoPadding,
    )
    == Ok(data)
}

pub fn base64_dq_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base64Dq),
      using: yabase.Base64Dq,
    )
    == Ok(data)
}

pub fn base91_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base91),
      using: yabase.Base91,
    )
    == Ok(data)
}

pub fn ascii85_roundtrip_test() -> Nil {
  let data = <<"test":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Ascii85),
      using: yabase.Ascii85,
    )
    == Ok(data)
}

pub fn z85_roundtrip_test() -> Nil {
  let data = <<0x86, 0x4F, 0xD2, 0x6F>>
  let assert Ok(encoded) = yabase.encode(data, using: yabase.Z85)
  assert yabase.decode(encoded, using: yabase.Z85) == Ok(data)
}

pub fn z85_encode_non_aligned_error_test() -> Nil {
  assert yabase.encode(<<1, 2, 3>>, using: yabase.Z85)
    == Error(InvalidLength(3))
}

pub fn zbase32_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Zbase32),
      using: yabase.Zbase32,
    )
    == Ok(data)
}

pub fn base64_urlsafe_nopadding_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base64UrlSafeNoPadding),
      using: yabase.Base64UrlSafeNoPadding,
    )
    == Ok(data)
}

pub fn adobe_ascii85_roundtrip_test() -> Nil {
  let data = <<"test":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.AdobeAscii85),
      using: yabase.AdobeAscii85,
    )
    == Ok(data)
}

pub fn rfc1924_base85_roundtrip_test() -> Nil {
  let data = <<1, 2, 3, 4>>
  let assert Ok(encoded) = yabase.encode(data, using: yabase.Rfc1924Base85)
  assert yabase.decode(encoded, using: yabase.Rfc1924Base85) == Ok(data)
}

// --- decode_strict facade wiring ---

pub fn decode_base64_strict_canonical_test() -> Nil {
  // Canonical encoding of "f" — passes strict.
  assert yabase.decode_base64_strict("Zg==") == Ok(<<"f":utf8>>)
}

pub fn decode_base64_strict_non_canonical_test() -> Nil {
  // Non-canonical (pad bits non-zero) — rejected by strict.
  assert yabase.decode_base64_strict("Zh==") == Error(NonCanonical)
}

pub fn decode_base32_strict_canonical_test() -> Nil {
  assert yabase.decode_base32_strict("MY======") == Ok(<<"f":utf8>>)
}

pub fn decode_base32_strict_non_canonical_test() -> Nil {
  assert yabase.decode_base32_strict("MB======") == Error(NonCanonical)
}
