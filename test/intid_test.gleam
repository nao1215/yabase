import gleam/string
import yabase/core/encoding
import yabase/core/error.{
  InvalidCharacter, InvalidChecksum, InvalidLength, NegativeValue, Overflow,
  UnsupportedForInt,
}
import yabase/intid

// === Base32 (RFC 4648) ===

pub fn encode_int_base32_rfc4648_zero_test() -> Nil {
  assert intid.encode_int_base32_rfc4648(0) == Ok("AA======")
}

pub fn encode_int_base32_rfc4648_one_test() -> Nil {
  assert intid.encode_int_base32_rfc4648(1) == Ok("AE======")
}

pub fn encode_int_base32_rfc4648_max_byte_test() -> Nil {
  assert intid.encode_int_base32_rfc4648(255) == Ok("74======")
}

pub fn decode_int_base32_rfc4648_empty_test() -> Nil {
  assert intid.decode_int_base32_rfc4648("") == Error(InvalidLength(0))
}

pub fn decode_int_base32_rfc4648_roundtrip_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base32_rfc4648(1_234_567)
  assert intid.decode_int_base32_rfc4648(encoded) == Ok(1_234_567)
}

pub fn decode_int_base32_rfc4648_invalid_char_test() -> Nil {
  assert intid.decode_int_base32_rfc4648("!!!!!!!!")
    == Error(InvalidCharacter("!", 0))
}

// === Base32 (Crockford) ===

pub fn encode_int_base32_crockford_zero_test() -> Nil {
  assert intid.encode_int_base32_crockford(0) == Ok("0")
}

pub fn encode_int_base32_crockford_alphabet_max_test() -> Nil {
  assert intid.encode_int_base32_crockford(31) == Ok("Z")
}

pub fn encode_int_base32_crockford_carry_test() -> Nil {
  assert intid.encode_int_base32_crockford(32) == Ok("10")
}

pub fn encode_int_base32_crockford_two_digit_max_test() -> Nil {
  assert intid.encode_int_base32_crockford(1023) == Ok("ZZ")
}

pub fn decode_int_base32_crockford_empty_test() -> Nil {
  assert intid.decode_int_base32_crockford("") == Error(InvalidLength(0))
}

pub fn decode_int_base32_crockford_leading_zero_tolerant_test() -> Nil {
  assert intid.decode_int_base32_crockford("0042")
    == intid.decode_int_base32_crockford("42")
}

pub fn decode_int_base32_crockford_roundtrip_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base32_crockford(987_654)
  assert intid.decode_int_base32_crockford(encoded) == Ok(987_654)
}

// === encoding.base10() (#78) ===

pub fn encode_int_base10_zero_test() -> Nil {
  assert intid.encode_int_base10(0) == Ok("0")
}

pub fn encode_int_base10_single_digit_test() -> Nil {
  assert intid.encode_int_base10(7) == Ok("7")
}

pub fn encode_int_base10_carry_test() -> Nil {
  assert intid.encode_int_base10(10) == Ok("10")
}

pub fn encode_int_base10_large_test() -> Nil {
  assert intid.encode_int_base10(1_000_000_000) == Ok("1000000000")
}

pub fn decode_int_base10_empty_test() -> Nil {
  assert intid.decode_int_base10("") == Error(InvalidLength(0))
}

pub fn decode_int_base10_round_trip_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base10(8_675_309)
  assert intid.decode_int_base10(encoded) == Ok(8_675_309)
}

pub fn decode_int_base10_leading_zero_tolerant_test() -> Nil {
  // The byte-roundtrip path treats leading zero characters as
  // leading 0x00 bytes, which still decode to the same integer
  // value — matching the behaviour of `decode_int_base36` for
  // `"0042"` vs `"42"`.
  assert intid.decode_int_base10("0042") == intid.decode_int_base10("42")
}

pub fn decode_int_base10_invalid_char_test() -> Nil {
  assert intid.decode_int_base10("12a3") == Error(InvalidCharacter("a", 2))
}

pub fn decode_int_base10_bounded_within_max_test() -> Nil {
  assert intid.decode_int_base10_bounded(input: "100", max: 1000) == Ok(100)
}

pub fn decode_int_base10_bounded_at_max_test() -> Nil {
  assert intid.decode_int_base10_bounded(input: "1000", max: 1000) == Ok(1000)
}

pub fn decode_int_base10_bounded_overflow_test() -> Nil {
  assert intid.decode_int_base10_bounded(input: "1001", max: 1000)
    == Error(Overflow)
}

// === encoding.base16() (#85) ===

pub fn encode_int_base16_zero_test() -> Nil {
  assert intid.encode_int_base16(0) == Ok("00")
}

pub fn encode_int_base16_single_byte_test() -> Nil {
  assert intid.encode_int_base16(255) == Ok("FF")
}

pub fn encode_int_base16_canonical_uppercase_test() -> Nil {
  // Uses RFC 4648 §8 canonical uppercase, matching base16.encode.
  assert intid.encode_int_base16(0xdeadbeef) == Ok("DEADBEEF")
}

pub fn decode_int_base16_empty_test() -> Nil {
  assert intid.decode_int_base16("") == Error(InvalidLength(0))
}

pub fn decode_int_base16_round_trip_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base16(8_675_309)
  assert intid.decode_int_base16(encoded) == Ok(8_675_309)
}

pub fn decode_int_base16_case_insensitive_test() -> Nil {
  // base16.decode accepts both cases; intid surfaces the same
  // lenient read behaviour.
  assert intid.decode_int_base16("DEADBEEF")
    == intid.decode_int_base16("deadbeef")
}

pub fn decode_int_base16_invalid_char_test() -> Nil {
  assert intid.decode_int_base16("12Z3") == Error(InvalidCharacter("z", 2))
}

pub fn decode_int_base16_bounded_within_max_test() -> Nil {
  assert intid.decode_int_base16_bounded(input: "FF", max: 1000) == Ok(255)
}

pub fn decode_int_base16_bounded_at_max_test() -> Nil {
  // Hex requires even-length input; "00FF" zero-pads to 4 chars.
  assert intid.decode_int_base16_bounded(input: "00FF", max: 255) == Ok(255)
}

pub fn decode_int_base16_bounded_overflow_test() -> Nil {
  assert intid.decode_int_base16_bounded(input: "FFFF", max: 255)
    == Error(Overflow)
}

// === encoding.base36() ===

pub fn encode_int_base36_zero_test() -> Nil {
  assert intid.encode_int_base36(0) == Ok("0")
}

pub fn encode_int_base36_alphabet_max_test() -> Nil {
  assert intid.encode_int_base36(35) == Ok("z")
}

pub fn encode_int_base36_carry_test() -> Nil {
  assert intid.encode_int_base36(36) == Ok("10")
}

pub fn encode_int_base36_two_digit_max_test() -> Nil {
  assert intid.encode_int_base36(1295) == Ok("zz")
}

pub fn decode_int_base36_empty_test() -> Nil {
  assert intid.decode_int_base36("") == Error(InvalidLength(0))
}

pub fn decode_int_base36_leading_zero_tolerant_test() -> Nil {
  assert intid.decode_int_base36("0042") == intid.decode_int_base36("42")
}

pub fn decode_int_base36_roundtrip_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base36(8_675_309)
  assert intid.decode_int_base36(encoded) == Ok(8_675_309)
}

pub fn decode_int_base36_invalid_char_test() -> Nil {
  assert intid.decode_int_base36("!") == Error(InvalidCharacter("!", 0))
}

// === Base58 (Bitcoin) ===

pub fn encode_int_base58_zero_test() -> Nil {
  assert intid.encode_int_base58(0) == Ok("1")
}

pub fn encode_int_base58_small_test() -> Nil {
  assert intid.encode_int_base58(42) == Ok("j")
}

pub fn encode_int_base58_alphabet_max_test() -> Nil {
  assert intid.encode_int_base58(57) == Ok("z")
}

pub fn encode_int_base58_carry_test() -> Nil {
  assert intid.encode_int_base58(58) == Ok("21")
}

pub fn encode_int_base58_two_digit_test() -> Nil {
  assert intid.encode_int_base58(1234) == Ok("NH")
}

pub fn decode_int_base58_empty_test() -> Nil {
  assert intid.decode_int_base58("") == Error(InvalidLength(0))
}

pub fn decode_int_base58_leading_zero_tolerant_test() -> Nil {
  assert intid.decode_int_base58("11NH") == intid.decode_int_base58("NH")
}

pub fn decode_int_base58_roundtrip_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base58(9_999_999_999)
  assert intid.decode_int_base58(encoded) == Ok(9_999_999_999)
}

pub fn decode_int_base58_invalid_char_test() -> Nil {
  assert intid.decode_int_base58("0") == Error(InvalidCharacter("0", 0))
}

// === Base58 (Flickr) ===

pub fn encode_int_base58_flickr_zero_test() -> Nil {
  assert intid.encode_int_base58_flickr(0) == Ok("1")
}

pub fn encode_int_base58_flickr_small_test() -> Nil {
  assert intid.encode_int_base58_flickr(42) == Ok("J")
}

pub fn decode_int_base58_flickr_roundtrip_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base58_flickr(1_234_567)
  assert intid.decode_int_base58_flickr(encoded) == Ok(1_234_567)
}

pub fn decode_int_base58_flickr_empty_test() -> Nil {
  assert intid.decode_int_base58_flickr("") == Error(InvalidLength(0))
}

// === encoding.base62() ===

pub fn encode_int_base62_zero_test() -> Nil {
  assert intid.encode_int_base62(0) == Ok("0")
}

pub fn encode_int_base62_alphabet_max_test() -> Nil {
  assert intid.encode_int_base62(61) == Ok("z")
}

pub fn encode_int_base62_carry_test() -> Nil {
  assert intid.encode_int_base62(62) == Ok("10")
}

pub fn encode_int_base62_large_test() -> Nil {
  assert intid.encode_int_base62(1_234_567_890) == Ok("1LY7VK")
}

pub fn decode_int_base62_empty_test() -> Nil {
  assert intid.decode_int_base62("") == Error(InvalidLength(0))
}

pub fn decode_int_base62_roundtrip_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base62(2_147_483_647)
  assert intid.decode_int_base62(encoded) == Ok(2_147_483_647)
}

pub fn decode_int_base62_leading_zero_tolerant_test() -> Nil {
  assert intid.decode_int_base62("00abc") == intid.decode_int_base62("abc")
}

// === Cross-cutting: negative inputs return Error(NegativeValue(_)) (#100) ===

pub fn encode_int_base58_negative_returns_error_test() -> Nil {
  assert intid.encode_int_base58(-42) == Error(NegativeValue(-42))
}

pub fn encode_int_base62_negative_returns_error_test() -> Nil {
  assert intid.encode_int_base62(-1) == Error(NegativeValue(-1))
}

pub fn encode_int_base10_negative_returns_error_test() -> Nil {
  assert intid.encode_int_base10(-1) == Error(NegativeValue(-1))
}

pub fn encode_int_base16_negative_returns_error_test() -> Nil {
  assert intid.encode_int_base16(-42) == Error(NegativeValue(-42))
}

pub fn encode_int_base16_compact_negative_returns_error_test() -> Nil {
  assert intid.encode_int_base16_compact(-1) == Error(NegativeValue(-1))
}

pub fn encode_int_base36_negative_returns_error_test() -> Nil {
  assert intid.encode_int_base36(-1_000_000) == Error(NegativeValue(-1_000_000))
}

pub fn encode_int_base32_rfc4648_negative_returns_error_test() -> Nil {
  assert intid.encode_int_base32_rfc4648(-7) == Error(NegativeValue(-7))
}

pub fn encode_int_base32_crockford_negative_returns_error_test() -> Nil {
  assert intid.encode_int_base32_crockford(-7) == Error(NegativeValue(-7))
}

pub fn encode_int_base32_crockford_check_negative_returns_error_test() -> Nil {
  assert intid.encode_int_base32_crockford_check(-1) == Error(NegativeValue(-1))
}

pub fn encode_int_base58_flickr_negative_returns_error_test() -> Nil {
  assert intid.encode_int_base58_flickr(-42) == Error(NegativeValue(-42))
}

pub fn encode_int_base58check_negative_returns_error_test() -> Nil {
  assert intid.encode_int_base58check(-1) == Error(NegativeValue(-1))
}

pub fn encode_int_facade_negative_returns_error_test() -> Nil {
  // The facade routes negatives through the same `int_to_bytes_be`
  // guard, so the surfaced error is identical for every codec.
  assert intid.encode_int(encoding: encoding.base58_bitcoin(), value: -42)
    == Error(NegativeValue(-42))
}

pub fn encode_int_facade_base58check_negative_returns_error_test() -> Nil {
  // Base58Check goes through a separate code path (it concatenates a
  // version byte before encoding), so pin its negative behaviour too.
  assert intid.encode_int(encoding: encoding.base58_check(0), value: -1)
    == Error(NegativeValue(-1))
}

// === Bounded decode: cap constants ===

pub fn int64_max_constant_test() -> Nil {
  // 2^63 - 1
  assert intid.int64_max == 9_223_372_036_854_775_807
}

pub fn int53_max_constant_test() -> Nil {
  // 2^53 - 1, JavaScript Number.MAX_SAFE_INTEGER
  assert intid.int53_max == 9_007_199_254_740_991
}

// === Bounded decode: Base58 (Bitcoin) ===

pub fn decode_int_base58_bounded_within_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base58(42)
  assert intid.decode_int_base58_bounded(input: encoded, max: intid.int64_max)
    == Ok(42)
}

pub fn decode_int_base58_bounded_at_cap_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base58(intid.int64_max)
  assert intid.decode_int_base58_bounded(input: encoded, max: intid.int64_max)
    == Ok(intid.int64_max)
}

pub fn decode_int_base58_bounded_above_cap_test() -> Nil {
  // 58^12 - 1 = "zzzzzzzzzzzz" (12 z's) ≈ 1.5e21, well above int64_max.
  // This is the exact reproduction case from the issue: an attacker
  // (or honest user typing a wrong URL) supplies 12 z's and the
  // unbounded decoder would return a bignum that crashes int64-bound
  // sinks (sqlite/postgres bigserial/mysql bigint).
  assert intid.decode_int_base58_bounded(
      input: "zzzzzzzzzzzz",
      max: intid.int64_max,
    )
    == Error(Overflow)
}

@target(erlang)
pub fn decode_int_base58_bounded_just_above_cap_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base58(intid.int64_max + 1)
  assert intid.decode_int_base58_bounded(input: encoded, max: intid.int64_max)
    == Error(Overflow)
}

pub fn decode_int_base58_bounded_int53_cap_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base58(intid.int53_max + 1)
  assert intid.decode_int_base58_bounded(input: encoded, max: intid.int53_max)
    == Error(Overflow)
}

pub fn decode_int_base58_bounded_empty_test() -> Nil {
  // Bounded variant defers empty-input rejection to the underlying
  // decoder so the error contract is identical.
  assert intid.decode_int_base58_bounded(input: "", max: intid.int64_max)
    == Error(InvalidLength(0))
}

pub fn decode_int_base58_bounded_invalid_char_test() -> Nil {
  // Decoder errors propagate through the bounded variant unchanged.
  assert intid.decode_int_base58_bounded(input: "0", max: intid.int64_max)
    == Error(InvalidCharacter("0", 0))
}

// === Bounded decode: Base58 (Flickr) ===

pub fn decode_int_base58_flickr_bounded_within_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base58_flickr(1234)
  assert intid.decode_int_base58_flickr_bounded(
      input: encoded,
      max: intid.int64_max,
    )
    == Ok(1234)
}

@target(erlang)
pub fn decode_int_base58_flickr_bounded_above_cap_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base58_flickr(intid.int64_max + 1)
  assert intid.decode_int_base58_flickr_bounded(
      input: encoded,
      max: intid.int64_max,
    )
    == Error(Overflow)
}

// === Bounded decode: encoding.base62() ===

pub fn decode_int_base62_bounded_within_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base62(2_147_483_647)
  assert intid.decode_int_base62_bounded(input: encoded, max: intid.int64_max)
    == Ok(2_147_483_647)
}

@target(erlang)
pub fn decode_int_base62_bounded_above_cap_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base62(intid.int64_max + 1)
  assert intid.decode_int_base62_bounded(input: encoded, max: intid.int64_max)
    == Error(Overflow)
}

pub fn decode_int_base62_bounded_int53_within_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base62(intid.int53_max)
  assert intid.decode_int_base62_bounded(input: encoded, max: intid.int53_max)
    == Ok(intid.int53_max)
}

// === Bounded decode: encoding.base36() ===

pub fn decode_int_base36_bounded_within_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base36(8_675_309)
  assert intid.decode_int_base36_bounded(input: encoded, max: intid.int64_max)
    == Ok(8_675_309)
}

@target(erlang)
pub fn decode_int_base36_bounded_above_cap_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base36(intid.int64_max + 1)
  assert intid.decode_int_base36_bounded(input: encoded, max: intid.int64_max)
    == Error(Overflow)
}

// === Bounded decode: Base32 (RFC 4648) ===

pub fn decode_int_base32_rfc4648_bounded_within_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base32_rfc4648(1_234_567)
  assert intid.decode_int_base32_rfc4648_bounded(
      input: encoded,
      max: intid.int64_max,
    )
    == Ok(1_234_567)
}

@target(erlang)
pub fn decode_int_base32_rfc4648_bounded_above_cap_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base32_rfc4648(intid.int64_max + 1)
  assert intid.decode_int_base32_rfc4648_bounded(
      input: encoded,
      max: intid.int64_max,
    )
    == Error(Overflow)
}

// === Bounded decode: Base32 (Crockford) ===

pub fn decode_int_base32_crockford_bounded_within_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base32_crockford(987_654)
  assert intid.decode_int_base32_crockford_bounded(
      input: encoded,
      max: intid.int64_max,
    )
    == Ok(987_654)
}

@target(erlang)
pub fn decode_int_base32_crockford_bounded_above_cap_test() -> Nil {
  let assert Ok(encoded) =
    intid.encode_int_base32_crockford(intid.int64_max + 1)
  assert intid.decode_int_base32_crockford_bounded(
      input: encoded,
      max: intid.int64_max,
    )
    == Error(Overflow)
}

// === Issue #73: Crockford Base32 with check symbol ===

pub fn encode_int_base32_crockford_check_zero_test() -> Nil {
  // 0 encoded as Crockford "0" then check digit for 0 mod 37 == "0".
  assert intid.encode_int_base32_crockford_check(0) == Ok("00")
}

pub fn decode_int_base32_crockford_check_roundtrip_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base32_crockford_check(987_654)
  assert intid.decode_int_base32_crockford_check(encoded) == Ok(987_654)
}

pub fn decode_int_base32_crockford_check_empty_test() -> Nil {
  assert intid.decode_int_base32_crockford_check("") == Error(InvalidLength(0))
}

pub fn decode_int_base32_crockford_check_detects_typo_test() -> Nil {
  // Take a valid checksummed encoding and mutate one body character.
  // The decoder must reject the typo via InvalidChecksum, which is the
  // whole reason callers reach for the `_check` variant.
  let assert Ok(encoded) = intid.encode_int_base32_crockford_check(123_456)
  let body = string_drop_last(encoded)
  let check = string_take_last(encoded)
  let mutated = mutate_first_body_char(body) <> check
  assert intid.decode_int_base32_crockford_check(mutated)
    == Error(InvalidChecksum)
}

pub fn decode_int_base32_crockford_check_bounded_within_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base32_crockford_check(42)
  assert intid.decode_int_base32_crockford_check_bounded(
      input: encoded,
      max: intid.int64_max,
    )
    == Ok(42)
}

@target(erlang)
pub fn decode_int_base32_crockford_check_bounded_above_cap_test() -> Nil {
  let assert Ok(encoded) =
    intid.encode_int_base32_crockford_check(intid.int64_max + 1)
  assert intid.decode_int_base32_crockford_check_bounded(
      input: encoded,
      max: intid.int64_max,
    )
    == Error(Overflow)
}

// === Issue #73: Base58Check ===
//
// The Base58Check round-trip tests below are `@target(erlang)` because
// `yabase/base58check`'s round-trip is itself only exercised on Erlang
// in this repo (see `test/base58check_test.gleam`); the JS-side
// SHA-256 divergence is pre-existing scope and tracked separately. The
// `decode_int_base58check_empty_test` runs on both targets because
// empty-input rejection short-circuits before any hashing.

@target(erlang)
pub fn encode_int_base58check_zero_roundtrips_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base58check(0)
  assert intid.decode_int_base58check(encoded) == Ok(0)
}

@target(erlang)
pub fn decode_int_base58check_roundtrip_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base58check(9_999_999_999)
  assert intid.decode_int_base58check(encoded) == Ok(9_999_999_999)
}

pub fn decode_int_base58check_empty_test() -> Nil {
  assert intid.decode_int_base58check("") == Error(InvalidLength(0))
}

@target(erlang)
pub fn decode_int_base58check_detects_typo_test() -> Nil {
  // Mutate the first checksum-bearing position. Base58Check's 4-byte
  // SHA-256 suffix means this *must* fail — that is the property the
  // helper exists to guarantee for callers.
  let assert Ok(encoded) = intid.encode_int_base58check(424_242)
  let mutated = mutate_first_body_char(encoded)
  assert intid.decode_int_base58check(mutated) == Error(InvalidChecksum)
}

@target(erlang)
pub fn decode_int_base58check_bounded_within_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base58check(1234)
  assert intid.decode_int_base58check_bounded(
      input: encoded,
      max: intid.int64_max,
    )
    == Ok(1234)
}

@target(erlang)
pub fn decode_int_base58check_bounded_above_cap_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base58check(intid.int64_max + 1)
  assert intid.decode_int_base58check_bounded(
      input: encoded,
      max: intid.int64_max,
    )
    == Error(Overflow)
}

// Helpers for the typo-detection tests above. Kept in the test module so
// the production API stays focused on Int↔string.
fn string_drop_last(s: String) -> String {
  let len = string.length(s)
  string.slice(s, 0, len - 1)
}

fn string_take_last(s: String) -> String {
  let len = string.length(s)
  string.slice(s, len - 1, 1)
}

fn mutate_first_body_char(s: String) -> String {
  // Flip the first character to a different valid Crockford / Base58
  // character. Both alphabets contain "1" and "2", so swapping between
  // them produces a syntactically valid but checksum-invalid string.
  let head = string.slice(s, 0, 1)
  let tail = string.slice(s, 1, string.length(s) - 1)
  let replacement = case head {
    "1" -> "2"
    _ -> "1"
  }
  replacement <> tail
}

// Issue #74: a wrapper that only `import yabase/intid` must be able to
// type-annotate the error returned by `decode_int_*` without reaching
// into `yabase/core/error`. This test pins down that the re-exported
// `intid.CodecError` works as a type annotation and that values of the
// underlying error type round-trip through the alias unchanged.
pub fn intid_codec_error_alias_round_trips_test() -> Nil {
  // The alias is the literal type the decoder returns, so values match
  // by structural equality. `InvalidLength` is one of the existing
  // variants from `yabase/core/error`.
  let result: Result(Int, intid.CodecError) =
    intid.decode_int_base58_bounded(input: "", max: intid.int53_max)
  assert result == Error(InvalidLength(0))
}

pub fn intid_codec_error_alias_propagates_through_wrapper_test() -> Nil {
  // Demonstrates the wrapper shape from Issue #74's reproduction: a
  // user function that takes only `yabase/intid` as an import and
  // returns the codec error through a custom name.
  let result = decode_job_id("0OIl")
  // base58 alphabet excludes 0 / O / I / l → InvalidCharacter on the
  // first offending position.
  let assert Error(_) = result
  Nil
}

fn decode_job_id(s: String) -> Result(Int, intid.CodecError) {
  intid.decode_int_base58_bounded(input: s, max: intid.int53_max)
}

// === Issue #93: generic encode_int / decode_int facade ===

pub fn encode_int_facade_matches_per_base_base58_test() -> Nil {
  let direct = intid.encode_int_base58(42)
  assert intid.encode_int(encoding: encoding.base58_bitcoin(), value: 42)
    == direct
}

pub fn encode_int_facade_matches_per_base_base32_crockford_test() -> Nil {
  let direct = intid.encode_int_base32_crockford(31)
  assert intid.encode_int(encoding: encoding.base32_crockford(), value: 31)
    == direct
}

pub fn encode_int_facade_matches_per_base_base62_test() -> Nil {
  let direct = intid.encode_int_base62(123_456)
  assert intid.encode_int(encoding: encoding.base62(), value: 123_456) == direct
}

pub fn encode_int_facade_matches_per_base_base16_test() -> Nil {
  let direct = intid.encode_int_base16(255)
  assert intid.encode_int(encoding: encoding.base16(), value: 255) == direct
}

pub fn encode_int_facade_unsupported_base64_test() -> Nil {
  // Base64 has no integer codec. The facade must surface
  // UnsupportedForInt rather than fall back to byte encoding.
  let result = intid.encode_int(encoding: encoding.base64_standard(), value: 42)
  assert result == Error(UnsupportedForInt("Base64(Standard)"))
}

pub fn encode_int_facade_unsupported_bech32_test() -> Nil {
  let result = intid.encode_int(encoding: encoding.bech32("bc"), value: 42)
  assert result == Error(UnsupportedForInt("Bech32"))
}

pub fn decode_int_facade_matches_per_base_base58_test() -> Nil {
  let assert Ok(encoded) = intid.encode_int_base58(42)
  assert intid.decode_int(encoding: encoding.base58_bitcoin(), value: encoded)
    == Ok(42)
}

pub fn decode_int_facade_rejects_empty_input_test() -> Nil {
  // Same contract as the per-base decoders: empty input is
  // InvalidLength(0), not the integer zero.
  assert intid.decode_int(encoding: encoding.base58_bitcoin(), value: "")
    == Error(InvalidLength(0))
}

pub fn decode_int_facade_unsupported_test() -> Nil {
  assert intid.decode_int(encoding: encoding.base85_z85(), value: "abc")
    == Error(UnsupportedForInt("Base85(Z85)"))
}

pub fn encode_int_then_decode_int_round_trip_test() -> Nil {
  let enc = encoding.base58_bitcoin()
  let assert Ok(encoded) = intid.encode_int(encoding: enc, value: 1_234_567)
  assert intid.decode_int(encoding: enc, value: encoded) == Ok(1_234_567)
}

pub fn decode_int_bounded_facade_overflow_test() -> Nil {
  let enc = encoding.base58_bitcoin()
  let assert Ok(encoded) = intid.encode_int(encoding: enc, value: 1_000_000)
  // The encoded value (1_000_000) exceeds max=10, so the bounded
  // facade returns Overflow — same shape as decode_int_*_bounded.
  let result = intid.decode_int_bounded(encoding: enc, value: encoded, max: 10)
  assert result == Error(Overflow)
}

pub fn decode_int_bounded_facade_within_range_test() -> Nil {
  let enc = encoding.base32_crockford()
  let assert Ok(encoded) = intid.encode_int(encoding: enc, value: 100)
  let result =
    intid.decode_int_bounded(encoding: enc, value: encoded, max: 1000)
  assert result == Ok(100)
}

pub fn encode_int_facade_base58check_test() -> Nil {
  // The version goes through the IntBase58Check carrier so a
  // non-default version reaches the underlying codec.
  let assert Ok(s) =
    intid.encode_int(encoding: encoding.base58_check(5), value: 42)
  // The decoded round trip is verified against the same version.
  assert intid.decode_int(encoding: encoding.base58_check(5), value: s)
    == Ok(42)
}

pub fn decode_int_facade_base58check_version_mismatch_test() -> Nil {
  // Encode with version 5, decode with version 0 → InvalidChecksum,
  // matching what `yabase.decode` does for Base58Check at the byte
  // layer.
  let assert Ok(s) =
    intid.encode_int(encoding: encoding.base58_check(5), value: 42)
  assert intid.decode_int(encoding: encoding.base58_check(0), value: s)
    == Error(InvalidChecksum)
}
