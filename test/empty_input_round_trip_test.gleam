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

import gleeunit/should
import yabase/facade

// --- Total encode (returns String) ---

pub fn empty_round_trip_base2_test() {
  facade.decode_base2(facade.encode_base2(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base8_test() {
  facade.decode_base8(facade.encode_base8(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base10_test() {
  facade.decode_base10(facade.encode_base10(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base16_test() {
  facade.decode_base16(facade.encode_base16(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base16_lowercase_test() {
  facade.decode_base16(facade.encode_base16_lowercase(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base32_test() {
  facade.decode_base32(facade.encode_base32(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base32_strict_test() {
  facade.decode_base32_strict(facade.encode_base32(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base32_hex_test() {
  facade.decode_base32_hex(facade.encode_base32_hex(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base32_crockford_test() {
  facade.decode_base32_crockford(facade.encode_base32_crockford(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base32_crockford_check_test() {
  facade.decode_base32_crockford_check(
    facade.encode_base32_crockford_check(<<>>),
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base32_clockwork_test() {
  facade.decode_base32_clockwork(facade.encode_base32_clockwork(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_zbase32_test() {
  facade.decode_zbase32(facade.encode_zbase32(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base36_test() {
  facade.decode_base36(facade.encode_base36(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base45_test() {
  facade.decode_base45(facade.encode_base45(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base58_test() {
  facade.decode_base58(facade.encode_base58(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base58_flickr_test() {
  facade.decode_base58_flickr(facade.encode_base58_flickr(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base62_test() {
  facade.decode_base62(facade.encode_base62(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base64_test() {
  facade.decode_base64(facade.encode_base64(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base64_strict_test() {
  facade.decode_base64_strict(facade.encode_base64(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base64_urlsafe_test() {
  facade.decode_base64_urlsafe(facade.encode_base64_urlsafe(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base64_urlsafe_nopadding_test() {
  facade.decode_base64_urlsafe_nopadding(
    facade.encode_base64_urlsafe_nopadding(<<>>),
  )
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base64_nopadding_test() {
  facade.decode_base64_nopadding(facade.encode_base64_nopadding(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base64_dq_test() {
  facade.decode_base64_dq(facade.encode_base64_dq(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_base91_test() {
  facade.decode_base91(facade.encode_base91(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_ascii85_test() {
  facade.decode_ascii85(facade.encode_ascii85(<<>>))
  |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_adobe_ascii85_test() {
  facade.decode_adobe_ascii85(facade.encode_adobe_ascii85(<<>>))
  |> should.equal(Ok(<<>>))
}

// --- encode_* returns Result (Z85, RFC 1924 Base85) ---
//
// Z85 and RFC 1924 Base85 require the input length to be a multiple of
// 4 bytes. `<<>>` has length 0 which trivially satisfies that, so the
// encode call must succeed and the round-trip must hold.

pub fn empty_round_trip_z85_test() {
  let assert Ok(encoded) = facade.encode_z85(<<>>)
  facade.decode_z85(encoded) |> should.equal(Ok(<<>>))
}

pub fn empty_round_trip_rfc1924_base85_test() {
  let assert Ok(encoded) = facade.encode_rfc1924_base85(<<>>)
  facade.decode_rfc1924_base85(encoded) |> should.equal(Ok(<<>>))
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
  facade.decode_base16("") |> should.equal(Ok(<<>>))
}

pub fn decode_empty_string_base32_test() {
  facade.decode_base32("") |> should.equal(Ok(<<>>))
}

pub fn decode_empty_string_base32_hex_test() {
  facade.decode_base32_hex("") |> should.equal(Ok(<<>>))
}

pub fn decode_empty_string_base64_test() {
  facade.decode_base64("") |> should.equal(Ok(<<>>))
}

pub fn decode_empty_string_base64_urlsafe_test() {
  facade.decode_base64_urlsafe("") |> should.equal(Ok(<<>>))
}

pub fn decode_empty_string_base64_nopadding_test() {
  facade.decode_base64_nopadding("") |> should.equal(Ok(<<>>))
}

pub fn decode_empty_string_base64_urlsafe_nopadding_test() {
  facade.decode_base64_urlsafe_nopadding("") |> should.equal(Ok(<<>>))
}
