import gleam/bit_array
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import yabase

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

fn codec(name: String) -> yabase.Encoding {
  case name {
    "base2" -> yabase.Base2
    "base8" -> yabase.Base8
    "base10" -> yabase.Base10
    "base16" -> yabase.Base16
    "base32" -> yabase.Base32Rfc4648
    "base32hex" -> yabase.Base32Hex
    "zbase32" -> yabase.Zbase32
    "clockwork" -> yabase.Base32Clockwork
    "crockford" -> yabase.Base32Crockford
    "base36" -> yabase.Base36
    "base45" -> yabase.Base45
    "base58" -> yabase.Base58Bitcoin
    "base62" -> yabase.Base62
    "base64" -> yabase.Base64
    "base64url" -> yabase.Base64UrlSafe
    "base64nopad" -> yabase.Base64NoPadding
    "dq" -> yabase.Base64Dq
    "ascii85" -> yabase.Ascii85
    "adobe" -> yabase.AdobeAscii85
    "rfc1924" -> yabase.Rfc1924Base85
    "z85" -> yabase.Z85
    _ -> yabase.Base91
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
      let assert Ok(_) = yabase.encode(data, using: encoding)
      io.println(
        case_name() <> " " <> int.to_string(now_ms() - started) <> " ms",
      )
    }
    _ -> {
      let assert Ok(text) = yabase.encode(data, using: encoding)
      let started = now_ms()
      let assert Ok(decoded) = yabase.decode(text, using: encoding)
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
