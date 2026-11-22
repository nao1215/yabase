//// Decoders must stay linear in the input size and must not grow the
//// stack, on both targets. 100 KB took 28 s through base2 on Erlang and
//// overflowed the JavaScript stack at 10 KB before the shared bit-group
//// engine.

import gleam/bit_array
import gleam/list
import yabase/core/encoding.{type Encoding}

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
    let assert Ok(text) = encoding.encode(codec, data)
    assert encoding.decode_as(codec, text) == Ok(data)
  })
}

pub fn base2_round_trips_100_kb_test() -> Nil {
  round_trips([encoding.base2()], 100_000)
}

pub fn base16_round_trips_100_kb_test() -> Nil {
  round_trips([encoding.base16()], 100_000)
}

pub fn base32_family_round_trips_100_kb_test() -> Nil {
  round_trips(
    [
      encoding.base32_rfc4648(),
      encoding.base32_hex(),
      encoding.base32_clockwork(),
      encoding.base32_z_base32(),
    ],
    100_000,
  )
}

pub fn base64_family_round_trips_100_kb_test() -> Nil {
  round_trips(
    [
      encoding.base64_standard(),
      encoding.base64_url_safe(),
      encoding.base64_no_padding(),
      encoding.base64_url_safe_no_padding(),
    ],
    100_000,
  )
}

pub fn base85_family_round_trips_100_kb_test() -> Nil {
  round_trips(
    [
      encoding.base85_btoa(),
      encoding.base85_adobe(),
      encoding.base85_z85(),
      encoding.base85_rfc1924(),
    ],
    100_000,
  )
}
