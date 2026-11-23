//// Empty-input round-trip pinned across every facade codec (#70).
////
//// The contract for total `encode_*` functions: `encode(<<>>)` is some
//// canonical string `s` such that `decode(s) == Ok(<<>>)`. For codecs
//// whose `encode` itself returns `Result` (Z85, RFC 1924 Base85), the
//// contract is `encode(<<>>) == Ok(s)` and the same round-trip
//// property holds on `s`.
////
//// The empty case is the smallest, simplest test case — a codec that
//// fails on it almost certainly has a more general bug. Pinning every
//// facade pair in one file means a future refactor that changes the
//// rule for one codec surfaces here as a single test diff. Companion
//// to yabase#63 (return type unification), #64 (sub-byte truncation),
//// and #65 (facade contract).

import codec_test_support
import yabase

import gleeunit/should

// --- Total encode (returns String) ---

pub fn empty_round_trip_base2_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Base2),
    using: yabase.Base2,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base8_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Base8),
    using: yabase.Base8,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base10_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Base10),
    using: yabase.Base10,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base16_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Base16),
    using: yabase.Base16,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base16_lowercase_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Base16Lowercase),
    using: yabase.Base16,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base32_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Base32Rfc4648),
    using: yabase.Base32Rfc4648,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base32_strict_test() {
  yabase.decode_base32_strict(codec_test_support.encode(
    <<>>,
    using: yabase.Base32Rfc4648,
  ))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base32_hex_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Base32Hex),
    using: yabase.Base32Hex,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base32_crockford_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Base32Crockford),
    using: yabase.Base32Crockford,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base32_crockford_check_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Base32CrockfordCheck),
    using: yabase.Base32CrockfordCheck,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base32_clockwork_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Base32Clockwork),
    using: yabase.Base32Clockwork,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_zbase32_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Zbase32),
    using: yabase.Zbase32,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base36_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Base36),
    using: yabase.Base36,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base45_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Base45),
    using: yabase.Base45,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base58_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Base58Bitcoin),
    using: yabase.Base58Bitcoin,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base58_flickr_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Base58Flickr),
    using: yabase.Base58Flickr,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base62_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Base62),
    using: yabase.Base62,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base64_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Base64),
    using: yabase.Base64,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base64_strict_test() {
  yabase.decode_base64_strict(codec_test_support.encode(
    <<>>,
    using: yabase.Base64,
  ))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base64_urlsafe_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Base64UrlSafe),
    using: yabase.Base64UrlSafe,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base64_urlsafe_nopadding_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Base64UrlSafeNoPadding),
    using: yabase.Base64UrlSafeNoPadding,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base64_nopadding_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Base64NoPadding),
    using: yabase.Base64NoPadding,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base64_dq_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Base64Dq),
    using: yabase.Base64Dq,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base91_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Base91),
    using: yabase.Base91,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_ascii85_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.Ascii85),
    using: yabase.Ascii85,
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_adobe_ascii85_test() {
  yabase.decode(
    codec_test_support.encode(<<>>, using: yabase.AdobeAscii85),
    using: yabase.AdobeAscii85,
  )
  |> should.equal(Ok(<<>>))
}

// --- encode_* returns Result (Z85, RFC 1924 Base85) ---
//
// Z85 and RFC 1924 Base85 require the input length to be a multiple of
// 4 bytes. `<<>>` has length 0 which trivially satisfies that, so the
// encode call must succeed and the round-trip must hold.

pub fn empty_round_trip_z85_test() {
  let assert Ok(encoded) = yabase.encode(<<>>, using: yabase.Z85)
  yabase.decode(encoded, using: yabase.Z85) |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_rfc1924_base85_test() {
  let assert Ok(encoded) = yabase.encode(<<>>, using: yabase.Rfc1924Base85)
  yabase.decode(encoded, using: yabase.Rfc1924Base85) |> should.equal(Ok(<<>>))
}

// --- decode_* on the canonical empty string `""` ---
//
// The RFC 4648 family (Base16, Base32, Base32hex, Base64, Base64url and
// their variants) defines `encode(<<>>) == ""` directly. Pin that the
// decoder accepts `""` for these — non-RFC-4648 codecs may have their
// own empty-string conventions (e.g. Bech32 has no notion of an empty
// HRP), so we don't try to make `decode("")` a uniform contract beyond
// the RFC 4648 family.

pub fn decode_empty_string_base16_test() {
  yabase.decode("", using: yabase.Base16) |> should.equal(Ok(<<>>))
}

pub fn decode_empty_string_base32_test() {
  yabase.decode("", using: yabase.Base32Rfc4648) |> should.equal(Ok(<<>>))
}

pub fn decode_empty_string_base32_hex_test() {
  yabase.decode("", using: yabase.Base32Hex) |> should.equal(Ok(<<>>))
}

pub fn decode_empty_string_base64_test() {
  yabase.decode("", using: yabase.Base64) |> should.equal(Ok(<<>>))
}

pub fn decode_empty_string_base64_urlsafe_test() {
  yabase.decode("", using: yabase.Base64UrlSafe) |> should.equal(Ok(<<>>))
}

pub fn decode_empty_string_base64_nopadding_test() {
  yabase.decode("", using: yabase.Base64NoPadding) |> should.equal(Ok(<<>>))
}

pub fn decode_empty_string_base64_urlsafe_nopadding_test() {
  yabase.decode("", using: yabase.Base64UrlSafeNoPadding)
  |> should.equal(Ok(<<>>))
}
