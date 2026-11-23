//// metamon round-trip property tests for the yabase encode/decode
//// pairs. Pin the documented "decode(encode(data)) == Ok(data)"
//// invariant for every encoding so a future refactor of any
//// codec's table or padding logic surfaces a regression here
//// instead of one of the per-encoding test files.

import codec_test_support
import yabase

import metamon
import metamon/generator
import metamon/generator/range

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
    yabase.decode(
      codec_test_support.encode(data, using: yabase.Base16),
      using: yabase.Base16,
    )
    == Ok(data)
  })
}

pub fn base16_lowercase_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    yabase.decode(
      codec_test_support.encode(data, using: yabase.Base16Lowercase),
      using: yabase.Base16,
    )
    == Ok(data)
  })
}

// ---------- base32 family ----------

pub fn base32_rfc4648_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    yabase.decode(
      codec_test_support.encode(data, using: yabase.Base32Rfc4648),
      using: yabase.Base32Rfc4648,
    )
    == Ok(data)
  })
}

pub fn base32_hex_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    yabase.decode(
      codec_test_support.encode(data, using: yabase.Base32Hex),
      using: yabase.Base32Hex,
    )
    == Ok(data)
  })
}

pub fn base32_crockford_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    yabase.decode(
      codec_test_support.encode(data, using: yabase.Base32Crockford),
      using: yabase.Base32Crockford,
    )
    == Ok(data)
  })
}

pub fn base32_clockwork_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    yabase.decode(
      codec_test_support.encode(data, using: yabase.Base32Clockwork),
      using: yabase.Base32Clockwork,
    )
    == Ok(data)
  })
}

// ---------- base64 family ----------

pub fn base64_standard_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    yabase.decode(
      codec_test_support.encode(data, using: yabase.Base64),
      using: yabase.Base64,
    )
    == Ok(data)
  })
}

pub fn base64_urlsafe_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    yabase.decode(
      codec_test_support.encode(data, using: yabase.Base64UrlSafe),
      using: yabase.Base64UrlSafe,
    )
    == Ok(data)
  })
}

pub fn base64_nopadding_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    yabase.decode(
      codec_test_support.encode(data, using: yabase.Base64NoPadding),
      using: yabase.Base64NoPadding,
    )
    == Ok(data)
  })
}

// ---------- other bases ----------

pub fn base10_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    yabase.decode(
      codec_test_support.encode(data, using: yabase.Base10),
      using: yabase.Base10,
    )
    == Ok(data)
  })
}

pub fn base36_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    yabase.decode(
      codec_test_support.encode(data, using: yabase.Base36),
      using: yabase.Base36,
    )
    == Ok(data)
  })
}

pub fn base45_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    yabase.decode(
      codec_test_support.encode(data, using: yabase.Base45),
      using: yabase.Base45,
    )
    == Ok(data)
  })
}

pub fn base58_bitcoin_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    yabase.decode(
      codec_test_support.encode(data, using: yabase.Base58Bitcoin),
      using: yabase.Base58Bitcoin,
    )
    == Ok(data)
  })
}

pub fn base62_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    yabase.decode(
      codec_test_support.encode(data, using: yabase.Base62),
      using: yabase.Base62,
    )
    == Ok(data)
  })
}

pub fn base91_round_trip_test() -> Nil {
  metamon.forall(small_bit_array_generator(), fn(data) {
    yabase.decode(
      codec_test_support.encode(data, using: yabase.Base91),
      using: yabase.Base91,
    )
    == Ok(data)
  })
}

pub fn ascii85_round_trip_test() -> Nil {
  metamon.forall(ascii85_friendly_bit_array_generator(), fn(data) {
    yabase.decode(
      codec_test_support.encode(data, using: yabase.Ascii85),
      using: yabase.Ascii85,
    )
    == Ok(data)
  })
}

pub fn z85_round_trip_test() -> Nil {
  metamon.forall(z85_friendly_bit_array_generator(), fn(data) {
    let assert Ok(encoded) = yabase.encode(data, using: yabase.Z85)
    yabase.decode(encoded, using: yabase.Z85) == Ok(data)
  })
}

// ---------- empty input ----------

pub fn base16_empty_round_trips_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<>>, using: yabase.Base16),
      using: yabase.Base16,
    )
    == Ok(<<>>)
}

pub fn base64_empty_round_trips_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<>>, using: yabase.Base64),
      using: yabase.Base64,
    )
    == Ok(<<>>)
}
