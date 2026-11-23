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

pub fn base58_check_round_trip_test() {
  let encoding = yabase.Base58Check(0)
  let payload = <<"hello":utf8>>
  let assert Ok(encoded) = yabase.encode(payload, using: encoding)
  let assert Ok(decoded) = yabase.decode(encoded, using: encoding)
  decoded |> should.equal(payload)
}

pub fn base58_check_rejects_mismatched_version_test() {
  // Encode with version 0, attempt to decode with version 5 — the
  // version byte is part of the checksummed payload, so a mismatch
  // surfaces as a checksum-class failure.
  let encode_enc = yabase.Base58Check(0)
  let decode_enc = yabase.Base58Check(5)
  let assert Ok(encoded) = yabase.encode(<<"hello":utf8>>, using: encode_enc)
  let assert Error(_) = yabase.decode(encoded, using: decode_enc)
}

pub fn bech32_round_trip_test() {
  let encoding = yabase.Bech32Encoding("bc", yabase.Bech32)
  let payload = <<0xDE, 0xAD, 0xBE, 0xEF>>
  let assert Ok(encoded) = yabase.encode(payload, using: encoding)
  let assert Ok(decoded) = yabase.decode(encoded, using: encoding)
  decoded |> should.equal(payload)
}

pub fn bech32m_round_trip_test() {
  let encoding = yabase.Bech32Encoding("npub", yabase.Bech32m)
  let payload = <<0xCA, 0xFE, 0xBA, 0xBE>>
  let assert Ok(encoded) = yabase.encode(payload, using: encoding)
  let assert Ok(decoded) = yabase.decode(encoded, using: encoding)
  decoded |> should.equal(payload)
}

pub fn bech32_rejects_mismatched_hrp_test() {
  // Encode with HRP "bc"; attempt to decode while declaring HRP
  // "tb" — the embedded HRP doesn't match the caller's expectation,
  // so the decode rejects the wire.
  let encode_enc = yabase.Bech32Encoding("bc", yabase.Bech32)
  let decode_enc = yabase.Bech32Encoding("tb", yabase.Bech32)
  let assert Ok(encoded) =
    yabase.encode(<<0xDE, 0xAD, 0xBE, 0xEF>>, using: encode_enc)
  let assert Error(_) = yabase.decode(encoded, using: decode_enc)
}

pub fn bech32_rejects_mismatched_variant_test() {
  // Encode with Bech32 (BIP 173); attempt to decode with Bech32m
  // (BIP 350). The variants have different checksum constants, so
  // the wire signature does not match the caller's declared variant.
  let encode_enc = yabase.Bech32Encoding("bc", yabase.Bech32)
  let decode_enc = yabase.Bech32Encoding("bc", yabase.Bech32m)
  let assert Ok(encoded) =
    yabase.encode(<<0xDE, 0xAD, 0xBE, 0xEF>>, using: encode_enc)
  let assert Error(_) = yabase.decode(encoded, using: decode_enc)
}
