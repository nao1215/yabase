//// Decoders must stay linear in the input size and must not grow the
//// stack, on both targets. 100 KB took 28 s through base2 on Erlang and
//// overflowed the JavaScript stack at 10 KB before the shared bit-group
//// engine.

import yabase.{type Encoding}

import gleam/bit_array
import gleam/list

fn pattern_bytes(count: Int) -> BitArray {
  pattern_loop(count, [])
}

fn pattern_loop(count: Int, acc: List(BitArray)) -> BitArray {
  case count {
    0 -> bit_array.concat(acc)
    _ -> pattern_loop(count - 1, [<<{ { count * 31 + 7 } % 256 }>>, ..acc])
  }
}

fn round_trips(codecs: List(Encoding), size: Int) -> Nil {
  let data = pattern_bytes(size)
  list.each(codecs, fn(codec) {
    let assert Ok(text) = yabase.encode(data, using: codec)
    assert yabase.decode(text, using: codec) == Ok(data)
  })
}

pub fn base2_round_trips_100_kb_test() -> Nil {
  round_trips([yabase.Base2], 100_000)
}

pub fn base16_round_trips_100_kb_test() -> Nil {
  round_trips([yabase.Base16], 100_000)
}

pub fn base32_family_round_trips_100_kb_test() -> Nil {
  round_trips(
    [
      yabase.Base32Rfc4648,
      yabase.Base32Hex,
      yabase.Base32Clockwork,
      yabase.Zbase32,
    ],
    100_000,
  )
}

pub fn base64_family_round_trips_100_kb_test() -> Nil {
  round_trips(
    [
      yabase.Base64,
      yabase.Base64UrlSafe,
      yabase.Base64NoPadding,
      yabase.Base64UrlSafeNoPadding,
    ],
    100_000,
  )
}

pub fn base85_family_round_trips_100_kb_test() -> Nil {
  round_trips(
    [
      yabase.Ascii85,
      yabase.AdobeAscii85,
      yabase.Z85,
      yabase.Rfc1924Base85,
    ],
    100_000,
  )
}

pub fn other_codecs_round_trip_100_kb_test() -> Nil {
  round_trips([yabase.Base45, yabase.Base91, yabase.Base64Dq], 100_000)
}
