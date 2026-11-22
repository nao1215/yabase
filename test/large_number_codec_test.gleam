//// The radix codecs (Base8, Base10, Base36, Base58, Base62, Crockford,
//// Base58Check) must give the same answer on Erlang and JavaScript for
//// inputs of any size. These vectors come from Bitcoin Core
//// (`base58_encode_decode.json`), the Bitcoin wiki Base58Check example and
//// multibase `basic.csv`; the 200-byte strings were computed with Python's
//// arbitrary-precision integers.

import gleam/bit_array
import gleam/list
import gleam/string
import yabase/base10
import yabase/base32/crockford
import yabase/base36
import yabase/base58/bitcoin
import yabase/base58/flickr
import yabase/base58check
import yabase/base62
import yabase/base8
import yabase/core/encoding
import yabase/core/multibase

fn ff_bytes(count: Int) -> BitArray {
  bit_array.concat(list.repeat(<<0xFF>>, count))
}

fn hex(text: String) -> BitArray {
  let assert Ok(bytes) = bit_array.base16_decode(text)
  bytes
}

fn pattern_bytes(count: Int) -> BitArray {
  pattern_loop(count, [])
}

fn pattern_loop(count: Int, acc: List(BitArray)) -> BitArray {
  case count {
    0 -> bit_array.concat(acc)
    _ -> pattern_loop(count - 1, [<<{ { count * 37 + 11 } % 256 }>>, ..acc])
  }
}

pub fn base58_bitcoin_25_byte_address_test() -> Nil {
  let address = hex("00EB15231DFCEB60925886B67D065299925915AEB172C06647")
  assert bitcoin.encode(address) == "1NS17iag9jJgTHD1VXjvLCEnZuQ3rJDE9L"
  assert bitcoin.decode("1NS17iag9jJgTHD1VXjvLCEnZuQ3rJDE9L") == Ok(address)
}

pub fn base58_bitcoin_core_alphabet_vector_test() -> Nil {
  let data =
    hex(
      "000111D38E5FC9071FFCD20B4A763CC9AE4F252BB4E48FD66A835E252ADA93FF480D6DD43DC62A641155A5",
    )
  let text = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
  assert bitcoin.encode(data) == text
  assert bitcoin.decode(text) == Ok(data)
}

pub fn base58check_wiki_address_test() -> Nil {
  let payload = hex("F54A5851E9372B87810A8E60CDD2E7CFD80B6E31")
  assert base58check.encode(0, payload)
    == Ok("1PMycacnJaSqwwJqjawXBErnLsZ7RkXUAs")
  let assert Ok(decoded) =
    base58check.decode("1PMycacnJaSqwwJqjawXBErnLsZ7RkXUAs")
  assert decoded.version == 0
  assert decoded.payload == payload
}

pub fn base58_200_bytes_test() -> Nil {
  let data = ff_bytes(200)
  let text =
    "2hzFmVcABxeCt1Q8k2J3aXUwjnTAHwNkHbeR9VkkBkKqoGMf5bmJCAS6kGXWNCb8DQqECKJ8UenKJv4tb8L5q1qFww7ftEvrDt5LE6F97doj3TVFHfsWgNJSWUWWGeEPUHdd7mEftPFxXZJakCnb4w29ZdFEP9XwjSHrPNThkQSxpKF8RxQM59P1Mp2nyPAskNbNGxMgHCiezK7dVSgh1vY8CS1tPeBnhrQhuF7RuvKRank4KNm7U3X2HmyEALuEqw1x5cgJ5GTQf5zNsG"
  assert bitcoin.encode(data) == text
  assert bitcoin.decode(text) == Ok(data)
}

pub fn base58_flickr_200_bytes_test() -> Nil {
  let data = ff_bytes(200)
  let text =
    "2GZfLuBabXDcT1p8K2i3zwtWJMsahWnKhADq9uKKbKjQNgmE5ALicar6KgwvncA8dpQecji8tDMjiV4TA8k5Q1QfWW7ETeVRdT5ke6f97CNJ3sufhESvFnirvtvvgDeothCC7LeETofXwyizKcMA4W29yCfeo9wWJrhRonsGKprXPjf8qXpm59o1mP2MYoaSKnAngXmFhcHDZj7CurFG1Vx8cr1ToDbMGRpGUf7qUVjqzMK4jnL7t3w2hLYeakUeQW1X5BFi5gspE5ZnSg"
  assert flickr.encode(data) == text
  assert flickr.decode(text) == Ok(data)
}

pub fn base10_200_bytes_test() -> Nil {
  let data = ff_bytes(200)
  let text =
    "44462416477094044620016814065517364315819234512137839319418223093753683069769152238984782576173969417485953521141049383745107056455283979316385016701612810119562585078620415976730705698345087039035930761275083827265405596065418173652685035788898113991627042329246850314029877161622487411877779578892097029690461532001915311366862468942148892205997883828265721290296220249202674740669814705818564765009960300389641843321936008416473775144511929246788246559538970957296160626364645375"
  assert base10.encode(data) == text
  assert base10.decode(text) == Ok(data)
}

pub fn base10_decode_400_digits_test() -> Nil {
  assert base10.decode(string.repeat("9", 400))
    == Ok(hex(
      "01B4EC7F91973FF3CB1CCF26FBC177C38DB6E54582DE258FF5190B8BC150AFADB38030E5D0B7BF50120E5C0E6AD18E629853CE9946A0B2ECCF6CFDE0AF8634BF8DC5A427FE4236CE5959BAA0E776CDB47C4813E1E0C75CA271E1D059E08E4996AA4193A48AD3A24633EBDB32E9F0B824377E2FA9C0FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
    ))
}

pub fn base8_200_bytes_test() -> Nil {
  let data = ff_bytes(200)
  let text = "1" <> string.repeat("7", 533)
  assert base8.encode(data) == text
  assert base8.decode(text) == Ok(data)
}

pub fn base36_200_bytes_test() -> Nil {
  let data = ff_bytes(200)
  let text =
    "5moohur20ccbzfm8m1xl9dtq8n22gzq0ceau61njfyj665e0pt9zvcoez9p6c1bumpj7auhhy5j88u7kow2ufxltyqkoq5qlp4nuc9fdyd0uvk26qgyjghd9fjdketh9ji6ycaxih8a6hh456bf6evwm2fsdjrqh9vac9lm55d08r6q4zhjuap3e2ro5mklnfi7ksqvh8lxru0zqnq124vfmvmwbwxwxt6f05u0kz60g9yjqri7sfnl7llpgdkuqsbgqzynv76d3ekytkdw39kcahlqovfv4i6demvfssfn6rj3ql5l3wf"
  assert base36.encode(data) == text
  assert base36.decode(string.uppercase(text)) == Ok(data)
}

pub fn base62_200_bytes_test() -> Nil {
  let data = ff_bytes(200)
  let text =
    "JMdXDLkZ7ldIUOooqTcANrkr0LG2fiCc4mV4u07bOhXM5sQjb8yW3NI81KyfoEGLQs7jMJCGW5yKoxt1bDJIfEBjdu31qzBYLNRuRhEyyDzuxWZHGKjLL7ZJFe9CLkDNxvlnkXDwY93sNXAkINY7u5yfZScWsNG3V84JuqRQwqkyVT00DUkcAwK7XSLAeooySsSKLw29HAwmOyX5Jg1JCY8I5xOe7owJnzo5vXFPSeoTkd2o17ScgYg3SuWviy4guIbzs4SumzyKV"
  assert base62.encode(data) == text
  assert base62.decode(text) == Ok(data)
}

pub fn crockford_200_bytes_test() -> Nil {
  let data = ff_bytes(200)
  let text = string.repeat("Z", 320)
  assert crockford.encode(data) == text
  assert crockford.decode(text) == Ok(data)
  // 2^1600 - 1 mod 37 is 8, so the check symbol is "8".
  assert crockford.encode_check(data) == text <> "8"
  assert crockford.decode_check(text <> "8") == Ok(data)
}

pub fn multibase_base36_upper_spec_vector_test() -> Nil {
  let assert Ok(bytes) = multibase.decode_bytes("K2LCPZO5YIKIDYNFL")
  assert bytes == <<"yes mani !":utf8>>
}

/// 1000 bytes is far past 2^1024, where a JavaScript float turns into
/// Infinity. Every radix codec must still round-trip, and finish.
pub fn radix_codecs_round_trip_1000_bytes_test() -> Nil {
  let data = pattern_bytes(1000)
  [
    encoding.base8(),
    encoding.base10(),
    encoding.base32_crockford(),
    encoding.base32_crockford_check(),
    encoding.base36(),
    encoding.base58_bitcoin(),
    encoding.base58_flickr(),
    encoding.base62(),
    encoding.base58_check(0),
  ]
  |> list.each(fn(codec) {
    let assert Ok(text) = encoding.encode(codec, data)
    assert encoding.decode_as(codec, text) == Ok(data)
  })
}
