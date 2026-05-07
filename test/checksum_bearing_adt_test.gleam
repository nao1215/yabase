/// Round-trip tests for the new checksum-bearing variants on the
/// `Encoding` ADT — `base58_check(version)`, `bech32(hrp)`, and
/// `bech32m(hrp)` — added to close #65.
///
/// The unified `yabase.encode` / `yabase.decode_as` family now
/// dispatches Base58Check and Bech32 / Bech32m alongside the plain
/// codecs. Property-test tooling that consumes `Encoding` can drive
/// these variants without forking by codec module.
import gleeunit/should
import yabase
import yabase/core/encoding

// Base58Check is bignum-backed via Base58, so it is not
// JavaScript-safe under the documented `Number.MAX_SAFE_INTEGER`
// constraint. Pin these tests to the Erlang target — the dispatch
// itself is exhaustive on both targets, but only the BEAM executes
// the bignum hot path. `is_javascript_safe(Base58Check(_))` returns
// `False`, so callers picking codecs at runtime can route around
// this on the JS target.

@target(erlang)
pub fn base58_check_round_trip_test() {
  let encoding = encoding.base58_check(0)
  let payload = <<"hello":utf8>>
  let assert Ok(encoded) = yabase.encode(encoding, payload)
  let assert Ok(decoded) = yabase.decode(encoding, encoded)
  decoded |> should.equal(payload)
}

@target(erlang)
pub fn base58_check_rejects_mismatched_version_test() {
  // Encode with version 0, attempt to decode with version 5 — the
  // version byte is part of the checksummed payload, so a mismatch
  // surfaces as a checksum-class failure.
  let encode_enc = encoding.base58_check(0)
  let decode_enc = encoding.base58_check(5)
  let assert Ok(encoded) = yabase.encode(encode_enc, <<"hello":utf8>>)
  let assert Error(_) = yabase.decode(decode_enc, encoded)
}

pub fn bech32_round_trip_test() {
  let encoding = encoding.bech32("bc")
  let payload = <<0xDE, 0xAD, 0xBE, 0xEF>>
  let assert Ok(encoded) = yabase.encode(encoding, payload)
  let assert Ok(decoded) = yabase.decode(encoding, encoded)
  decoded |> should.equal(payload)
}

pub fn bech32m_round_trip_test() {
  let encoding = encoding.bech32m("npub")
  let payload = <<0xCA, 0xFE, 0xBA, 0xBE>>
  let assert Ok(encoded) = yabase.encode(encoding, payload)
  let assert Ok(decoded) = yabase.decode(encoding, encoded)
  decoded |> should.equal(payload)
}

pub fn bech32_rejects_mismatched_hrp_test() {
  // Encode with HRP "bc"; attempt to decode while declaring HRP
  // "tb" — the embedded HRP doesn't match the caller's expectation,
  // so the decode rejects the wire.
  let encode_enc = encoding.bech32("bc")
  let decode_enc = encoding.bech32("tb")
  let assert Ok(encoded) = yabase.encode(encode_enc, <<0xDE, 0xAD, 0xBE, 0xEF>>)
  let assert Error(_) = yabase.decode(decode_enc, encoded)
}

pub fn bech32_rejects_mismatched_variant_test() {
  // Encode with Bech32 (BIP 173); attempt to decode with Bech32m
  // (BIP 350). The variants have different checksum constants, so
  // the wire signature does not match the caller's declared variant.
  let encode_enc = encoding.bech32("bc")
  let decode_enc = encoding.bech32m("bc")
  let assert Ok(encoded) = yabase.encode(encode_enc, <<0xDE, 0xAD, 0xBE, 0xEF>>)
  let assert Error(_) = yabase.decode(decode_enc, encoded)
}
