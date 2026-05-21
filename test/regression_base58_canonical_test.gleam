//// Regression tests for #101: `intid.decode_int_base58` rejected
//// non-canonical wire forms with `Error(NonCanonical)` instead of
//// accepting them as aliases for the canonical encoding.
////
//// The Bitcoin Base58 alphabet uses `"1"` as the zero character.
//// `base58_bitcoin.decode` prepends one `0x00` byte for every
//// leading `"1"` in the input; when that byte string is read back
//// as a big-endian integer the leading zero bytes vanish, so
//// `"5Q"`, `"15Q"`, `"115Q"` (and `"11" * N + "5Q"` for any N)
//// all decoded to `255`. That collapsed the bijection ID callers
//// (URL shorteners, idempotency keys, database lookups) rely on:
//// two different wire strings could name the same row, breaking
//// deduplication and cache invariants.
////
//// These tests pin down the new canonical-form contract:
////
////   - `"1"` alone is canonical (it is the encoding of `0`)
////   - any other input that starts with `"1"` is `NonCanonical`
////   - every value's canonical encoding round-trips (the strict
////     check does not regress the success path)

import yabase/core/error.{NonCanonical}
import yabase/intid

pub fn decode_int_base58_rejects_single_leading_one_test() -> Nil {
  // `"5Q"` is the canonical encoding of `255`. Prepending one `"1"`
  // is the smallest possible non-canonical input, and the one the
  // issue's repro called out by name.
  assert intid.decode_int_base58("15Q") == Error(NonCanonical)
}

pub fn decode_int_base58_rejects_multiple_leading_ones_test() -> Nil {
  // Two and three leading `"1"` characters must be rejected with
  // the same error — the previous behaviour silently accepted any
  // count, so the regression is best pinned with several lengths.
  assert intid.decode_int_base58("115Q") == Error(NonCanonical)
  assert intid.decode_int_base58("1115Q") == Error(NonCanonical)
}

pub fn decode_int_base58_accepts_canonical_zero_test() -> Nil {
  // `"1"` alone is the canonical encoding of `0`. The single
  // leading `"1"` is therefore valid; the rule is "no *extra*
  // leading `"1"`s", not "no leading `"1"` at all".
  assert intid.decode_int_base58("1") == Ok(0)
}

pub fn decode_int_base58_rejects_double_one_for_zero_test() -> Nil {
  // `"11"` would decode to `0` under the old behaviour (two
  // leading zero bytes -> integer 0). The canonical encoding of
  // `0` is `"1"`, so `"11"` and any longer all-`"1"` string is
  // now `Error(NonCanonical)`.
  assert intid.decode_int_base58("11") == Error(NonCanonical)
  assert intid.decode_int_base58("111") == Error(NonCanonical)
}

pub fn decode_int_base58_accepts_canonical_encoding_test() -> Nil {
  // The canonical encoding of `255` is `"5Q"` — no leading `"1"`,
  // no padding. The strict decoder accepts it unchanged.
  assert intid.decode_int_base58("5Q") == Ok(255)
}

pub fn decode_int_base58_round_trip_canonical_test() -> Nil {
  // The strict check must not regress the success path: every
  // value's canonical encoding still round-trips through decode.
  // The samples cover the alphabet boundary (`57` -> `"z"`), the
  // first carry (`58` -> `"21"`), and a value at the JS-safe
  // ceiling so the bounded variants do not need their own
  // round-trip suite for these constants.
  let round_trip = fn(n: Int) -> Nil {
    let assert Ok(encoded) = intid.encode_int_base58(n)
    assert intid.decode_int_base58(encoded) == Ok(n)
  }
  round_trip(0)
  round_trip(1)
  round_trip(57)
  round_trip(58)
  round_trip(255)
  round_trip(65_535)
  round_trip(1_000_000)
  round_trip(9_007_199_254_740_991)
}

pub fn decode_int_base58_bounded_rejects_leading_one_test() -> Nil {
  // The bounded variant defers to `decode_int_base58`, so the
  // canonical-form rejection must propagate through. Pinning this
  // is important because the bounded variant is the one callers
  // reach for when they care about ID uniqueness most (database
  // lookups, idempotency keys) — exactly the use case that
  // motivated #101.
  assert intid.decode_int_base58_bounded(input: "15Q", max: intid.int64_max)
    == Error(NonCanonical)
}

pub fn decode_int_base58_bounded_accepts_canonical_test() -> Nil {
  // Mirror of the above on the success path: a canonical input
  // within range still decodes through the bounded variant.
  assert intid.decode_int_base58_bounded(input: "5Q", max: intid.int64_max)
    == Ok(255)
}
