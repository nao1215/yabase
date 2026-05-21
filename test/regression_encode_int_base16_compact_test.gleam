//// Regression tests for #99: `intid.encode_int_base16_compact/1`
//// drops leading zero characters so the output shape matches the
//// rest of the `encode_int_*` family
//// (`encode_int_base58(1) == "2"`, `encode_int_base36(1) == "1"`,
//// `encode_int_base10(1) == "1"`). The existing
//// `encode_int_base16/1` keeps its byte-aligned (even-length)
//// contract — this test file pins both behaviours side-by-side so
//// the asymmetry follow-up cannot regress in either direction.

import yabase/intid

pub fn encode_int_base16_compact_one_test() -> Nil {
  // `encode_int_base16(1) == "01"`; the compact variant drops the
  // leading-zero pad to match `encode_int_base58(1) == "2"` /
  // `encode_int_base36(1) == "1"` / `encode_int_base10(1) == "1"`.
  assert intid.encode_int_base16_compact(1) == "1"
}

pub fn encode_int_base16_compact_2025_test() -> Nil {
  // `encode_int_base16(2025) == "07E9"`; the compact form is the
  // canonical three-nibble hex.
  assert intid.encode_int_base16_compact(2025) == "7E9"
}

pub fn encode_int_base16_compact_zero_test() -> Nil {
  // Magnitude-zero collapses to a single `"0"`, matching
  // `encode_int_base10(0) == "0"` /
  // `encode_int_base36(0) == "0"` /
  // `encode_int_base32_crockford(0) == "0"`.
  assert intid.encode_int_base16_compact(0) == "0"
}

pub fn encode_int_base16_compact_single_byte_test() -> Nil {
  // Values that already occupy a whole byte (no leading zero
  // nibble) pass through unchanged.
  assert intid.encode_int_base16_compact(255) == "FF"
}

pub fn encode_int_base16_compact_canonical_uppercase_test() -> Nil {
  // Compact output uses the same canonical RFC 4648 §8 uppercase
  // alphabet as `encode_int_base16/1`.
  assert intid.encode_int_base16_compact(0xdeadbeef) == "DEADBEEF"
}

pub fn encode_int_base16_compact_large_test() -> Nil {
  // Large value with a leading zero nibble — the compact form
  // strips exactly one `"0"` while preserving every interior digit.
  // `0x0abcdef0` -> byte-aligned "0ABCDEF0" -> compact "ABCDEF0".
  assert intid.encode_int_base16_compact(0x0abcdef0) == "ABCDEF0"
}

pub fn encode_int_base16_compact_round_trip_test() -> Nil {
  // Issue #99 pins this round-trip: `decode_int_base16` is tolerant
  // of any-length hex input, so the compact encoder's output feeds
  // back to the same `Int` without the caller having to know about
  // the byte-aligned vs compact distinction.
  let encoded = intid.encode_int_base16_compact(8_675_309)
  assert intid.decode_int_base16(encoded) == Ok(8_675_309)
}

pub fn encode_int_base16_compact_round_trip_odd_length_test() -> Nil {
  // The compact form of `1` is the odd-length `"1"`; this pins that
  // `decode_int_base16` accepts odd-length input (zero-padding to
  // the next byte boundary internally).
  assert intid.decode_int_base16(intid.encode_int_base16_compact(1)) == Ok(1)
}

pub fn encode_int_base16_compact_round_trip_zero_test() -> Nil {
  // Magnitude-zero must also round-trip — `"0"` decodes back to `0`
  // even though it is a single odd-length character.
  assert intid.decode_int_base16(intid.encode_int_base16_compact(0)) == Ok(0)
}

pub fn encode_int_base16_byte_aligned_unchanged_test() -> Nil {
  // Regression: the existing byte-aligned `encode_int_base16/1`
  // must keep its leading-zero pad — callers relying on the even-
  // length contract (DB hex columns, HTTP headers, content-
  // addressable storage) cannot tolerate a silent shape change.
  assert intid.encode_int_base16(1) == "01"
}

pub fn encode_int_base16_byte_aligned_2025_unchanged_test() -> Nil {
  // Same regression with the value the issue cited as the example
  // of the asymmetry; locks in `"07E9"` so the byte-aligned encoder
  // stays four characters wide for two-byte magnitudes.
  assert intid.encode_int_base16(2025) == "07E9"
}
