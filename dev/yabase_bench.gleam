import gleam/bit_array
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import yabase/core/encoding

@external(erlang, "yabase_bench_ffi", "now_ms")
@external(javascript, "./yabase_bench_ffi.mjs", "now_ms")
fn now_ms() -> Int

@external(erlang, "yabase_bench_ffi", "case_name")
@external(javascript, "./yabase_bench_ffi.mjs", "case_name")
fn case_name() -> String

fn pattern_bytes(count: Int) -> BitArray {
  pattern_loop(0, count, [])
}

fn pattern_loop(index: Int, count: Int, chunks: List(BitArray)) -> BitArray {
  case index >= count {
    True -> bit_array.concat(list.reverse(chunks))
    False ->
      pattern_loop(index + 1, count, [
        <<{ { index * 31 + 7 } % 256 }:8>>,
        ..chunks
      ])
  }
}

fn codec(name: String) -> encoding.Encoding {
  case name {
    "base2" -> encoding.base2()
    "base8" -> encoding.base8()
    "base10" -> encoding.base10()
    "base16" -> encoding.base16()
    "base32" -> encoding.base32_rfc4648()
    "base32hex" -> encoding.base32_hex()
    "zbase32" -> encoding.base32_z_base32()
    "clockwork" -> encoding.base32_clockwork()
    "crockford" -> encoding.base32_crockford()
    "base36" -> encoding.base36()
    "base45" -> encoding.base45()
    "base58" -> encoding.base58_bitcoin()
    "base62" -> encoding.base62()
    "base64" -> encoding.base64_standard()
    "base64url" -> encoding.base64_url_safe()
    "base64nopad" -> encoding.base64_no_padding()
    "dq" -> encoding.base64_dq()
    "ascii85" -> encoding.base85_btoa()
    "adobe" -> encoding.base85_adobe()
    "rfc1924" -> encoding.base85_rfc1924()
    "z85" -> encoding.base85_z85()
    _ -> encoding.base91()
  }
}

pub fn main() -> Nil {
  let assert [name, operation, size] = string.split(case_name(), "-")
  let assert Ok(count) = int.parse(size)
  let encoding = codec(name)
  let data = pattern_bytes(count)
  case operation {
    "encoding" -> {
      let started = now_ms()
      let assert Ok(_) = encoding.encode(encoding, data)
      io.println(
        case_name() <> " " <> int.to_string(now_ms() - started) <> " ms",
      )
    }
    _ -> {
      let assert Ok(text) = encoding.encode(encoding, data)
      let started = now_ms()
      let assert Ok(decoded) = encoding.decode_as(encoding, text)
      let elapsed = now_ms() - started
      let status = case decoded == data {
        True -> "ok"
        False -> "MISMATCH"
      }
      io.println(
        case_name() <> " " <> int.to_string(elapsed) <> " ms " <> status,
      )
    }
  }
}
