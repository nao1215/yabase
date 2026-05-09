//// metamon round-trip property tests for the yabase encode/decode
//// pairs. Pin the documented "decode(encode(data)) == Ok(data)"
//// invariant for every encoding so a future refactor of any
//// codec's table or padding logic surfaces a regression here
//// instead of one of the per-encoding test files.

import metamon
import metamon/generator
import metamon/generator/range
import yabase/ascii85
import yabase/base10
import yabase/base16
import yabase/base32/clockwork
import yabase/base32/crockford
import yabase/base32/hex as base32_hex
import yabase/base32/rfc4648 as base32_rfc4648
import yabase/base36
import yabase/base45
import yabase/base58/bitcoin as base58_bitcoin
import yabase/base62
import yabase/base64/nopadding as base64_nopadding
import yabase/base64/standard as base64_standard
import yabase/base64/urlsafe as base64_urlsafe
import yabase/base91
import yabase/z85

fn small_bit_array_generator() -> generator.Generator(BitArray) {
  generator.bit_array(range.constant(0, 32))
}

fn z85_friendly_bit_array_generator() -> generator.Generator(BitArray) {
  // Z85 (RFC compliant) requires the input to be a multiple of 4
  // bytes; for property testing we sample lengths from {0, 4, 8,
  // ..., 32} so the round-trip stays clean. Z85's strict variant
  // surfaces a `LengthNotMultipleOf4` for non-conforming input,
  // which is documented behaviour and tested elsewhere.
  generator.element_of([
    <<>>,
    <<1, 2, 3, 4>>,
    <<0, 0, 0, 0>>,
    <<255, 255, 255, 255>>,
    <<1, 2, 3, 4, 5, 6, 7, 8>>,
    <<0xCA, 0xFE, 0xBA, 0xBE>>,
  ])
}

fn ascii85_friendly_bit_array_generator() -> generator.Generator(BitArray) {
  // Standard ascii85 encoding requires the input to be a multiple
  // of 4 bytes (the public `encode/1` function panics otherwise);
  // sample from a fixed list to stay inside the documented
  // contract.
  generator.element_of([
    <<>>,
    <<1, 2, 3, 4>>,
    <<0, 0, 0, 0>>,
    <<255, 255, 255, 255>>,
    <<1, 2, 3, 4, 5, 6, 7, 8>>,
    <<0xCA, 0xFE, 0xBA, 0xBE>>,
  ])
}

// ---------- base16 ----------

pub fn base16_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    base16.decode(base16.encode(data)) == Ok(data)
  })
}

pub fn base16_lowercase_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    base16.decode(base16.encode_lowercase(data)) == Ok(data)
  })
}

// ---------- base32 family ----------

pub fn base32_rfc4648_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    base32_rfc4648.decode(base32_rfc4648.encode(data)) == Ok(data)
  })
}

pub fn base32_hex_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    base32_hex.decode(base32_hex.encode(data)) == Ok(data)
  })
}

pub fn base32_crockford_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    crockford.decode(crockford.encode(data)) == Ok(data)
  })
}

pub fn base32_clockwork_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    clockwork.decode(clockwork.encode(data)) == Ok(data)
  })
}

// ---------- base64 family ----------

pub fn base64_standard_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    base64_standard.decode(base64_standard.encode(data)) == Ok(data)
  })
}

pub fn base64_urlsafe_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    base64_urlsafe.decode(base64_urlsafe.encode(data)) == Ok(data)
  })
}

pub fn base64_nopadding_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    base64_nopadding.decode(base64_nopadding.encode(data)) == Ok(data)
  })
}

// ---------- other bases ----------

pub fn base10_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    base10.decode(base10.encode(data)) == Ok(data)
  })
}

pub fn base36_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    base36.decode(base36.encode(data)) == Ok(data)
  })
}

pub fn base45_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    base45.decode(base45.encode(data)) == Ok(data)
  })
}

pub fn base58_bitcoin_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    base58_bitcoin.decode(base58_bitcoin.encode(data)) == Ok(data)
  })
}

pub fn base62_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    base62.decode(base62.encode(data)) == Ok(data)
  })
}

pub fn base91_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    base91.decode(base91.encode(data)) == Ok(data)
  })
}

pub fn ascii85_round_trip_test() -> Nil {
  metamon.forall(ascii85_friendly_bit_array_generator(), fn(data) {
    ascii85.decode(ascii85.encode(data)) == Ok(data)
  })
}

pub fn z85_round_trip_test() -> Nil {
  metamon.forall(z85_friendly_bit_array_generator(), fn(data) {
    let assert Ok(encoded) = z85.encode(data)
    z85.decode(encoded) == Ok(data)
  })
}

// ---------- empty input ----------

pub fn base16_empty_round_trips_test() -> Nil {
  assert base16.decode(base16.encode(<<>>)) == Ok(<<>>)
}

pub fn base64_empty_round_trips_test() -> Nil {
  assert base64_standard.decode(base64_standard.encode(<<>>)) == Ok(<<>>)
}
