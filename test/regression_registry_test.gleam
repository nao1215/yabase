import gleam/bool
import gleam/list
import gleam/result
import gleam/string
import yabase as y

fn prefixes() -> List(#(String, y.Encoding)) {
  [
    #("0", y.Base2),
    #("7", y.Base8),
    #("9", y.Base10),
    #("f", y.Base16),
    #("F", y.Base16),
    #("c", y.Base32Rfc4648),
    #("C", y.Base32Rfc4648),
    #("b", y.Base32Rfc4648),
    #("B", y.Base32Rfc4648),
    #("t", y.Base32Hex),
    #("T", y.Base32Hex),
    #("v", y.Base32Hex),
    #("V", y.Base32Hex),
    #("k", y.Base36),
    #("K", y.Base36),
    #("R", y.Base45),
    #("z", y.Base58Bitcoin),
    #("Z", y.Base58Flickr),
    #("h", y.Zbase32),
    #("M", y.Base64),
    #("m", y.Base64NoPadding),
    #("U", y.Base64UrlSafe),
    #("u", y.Base64UrlSafeNoPadding),
  ]
}

fn check_ascii(code: Int) -> Nil {
  use <- bool.guard(when: code > 127, return: Nil)
  let assert Ok(point) = string.utf_codepoint(code)
  let prefix = string.from_utf_codepoints([point])
  let expected =
    prefixes()
    |> list.find(fn(row) { row.0 == prefix })
    |> result.map(fn(row) { row.1 })
  assert y.encoding_from_multibase_prefix(prefix) == expected
  check_ascii(code + 1)
}

pub fn registry_accepts_exactly_twenty_three_ascii_prefixes_test() {
  check_ascii(0)
  list.each(["", "ff", "F\u{0301}", "é", "m "], fn(prefix) {
    assert y.encoding_from_multibase_prefix(prefix) == Error(Nil)
  })
}

pub fn canonical_prefix_table_keeps_all_fifteen_prefixes_test() {
  let rows = [
    #(y.Base2, "0"),
    #(y.Base8, "7"),
    #(y.Base10, "9"),
    #(y.Base16, "f"),
    #(y.Base16Lowercase, "f"),
    #(y.Base32Rfc4648, "c"),
    #(y.Base32Hex, "t"),
    #(y.Zbase32, "h"),
    #(y.Base36, "k"),
    #(y.Base45, "R"),
    #(y.Base58Bitcoin, "z"),
    #(y.Base58Flickr, "Z"),
    #(y.Base64, "M"),
    #(y.Base64NoPadding, "m"),
    #(y.Base64UrlSafe, "U"),
    #(y.Base64UrlSafeNoPadding, "u"),
  ]
  list.each(rows, fn(row) {
    assert y.multibase_prefix(row.0) == Ok(row.1)
  })
  list.each(
    [
      y.Base32Crockford,
      y.Base32CrockfordCheck,
      y.Base32Clockwork,
      y.Base58Check(-1),
      y.Base62,
      y.Base64Dq,
      y.Ascii85,
      y.AdobeAscii85,
      y.Rfc1924Base85,
      y.Z85,
      y.Base91,
      y.Bech32Encoding("", y.Bech32),
      y.Bech32Encoding("", y.Bech32m),
    ],
    fn(encoding) {
      assert y.multibase_prefix(encoding) == Error(Nil)
    },
  )
}

pub fn all_twenty_nine_selection_names_are_stable_test() {
  let rows = [
    #(y.Base2, "base2"),
    #(y.Base8, "base8"),
    #(y.Base10, "base10"),
    #(y.Base16, "base16"),
    #(y.Base16Lowercase, "base16lower"),
    #(y.Base32Rfc4648, "base32pad"),
    #(y.Base32Hex, "base32hexpad"),
    #(y.Base32Crockford, "base32crockford"),
    #(y.Base32CrockfordCheck, "base32crockford-check"),
    #(y.Base32Clockwork, "base32clockwork"),
    #(y.Zbase32, "base32z"),
    #(y.Base36, "base36"),
    #(y.Base45, "base45"),
    #(y.Base58Bitcoin, "base58btc"),
    #(y.Base58Flickr, "base58flickr"),
    #(y.Base58Check(-1), "base58check"),
    #(y.Base62, "base62"),
    #(y.Base64, "base64pad"),
    #(y.Base64UrlSafe, "base64urlpad"),
    #(y.Base64NoPadding, "base64"),
    #(y.Base64UrlSafeNoPadding, "base64url"),
    #(y.Base64Dq, "base64dq"),
    #(y.Ascii85, "ascii85"),
    #(y.AdobeAscii85, "adobe-ascii85"),
    #(y.Rfc1924Base85, "rfc1924-base85"),
    #(y.Z85, "z85"),
    #(y.Base91, "base91"),
    #(y.Bech32Encoding("", y.Bech32), "bech32"),
    #(y.Bech32Encoding("", y.Bech32m), "bech32m"),
  ]
  list.each(rows, fn(row) {
    assert y.encoding_to_string(row.0) == row.1
  })
}

pub fn lowerhex_byte_capability_and_multibase_metadata_are_preserved_test() {
  assert y.encode(<<0, 255>>, using: y.Base16Lowercase) == Ok("00ff")
  assert y.decode("00FF", using: y.Base16Lowercase) == Ok(<<0, 255>>)
  assert y.decode("00ff", using: y.Base16Lowercase) == Ok(<<0, 255>>)
  assert y.encode_multibase(<<0, 255>>, using: y.Base16) == Ok("f00ff")
  assert y.encode_multibase(<<0, 255>>, using: y.Base16Lowercase) == Ok("f00ff")
  assert y.decode_multibase("F00FF") == Ok(y.Decoded(y.Base16, <<0, 255>>))
  assert y.decode_multibase("f00ff") == Ok(y.Decoded(y.Base16, <<0, 255>>))
  assert y.decode_multibase("mQQ") == Ok(y.Decoded(y.Base64NoPadding, <<65>>))
  assert y.decode_multibase("MQQ==") == Ok(y.Decoded(y.Base64, <<65>>))
}

pub fn numeric_and_bit_packed_formats_remain_distinct_test() {
  assert y.encode(<<1>>, using: y.Base8) == Ok("1")
  assert y.encode_multibase(<<1>>, using: y.Base8) == Ok("7002")
  assert y.decode_multibase("7002") == Ok(y.Decoded(y.Base8, <<1>>))
  assert y.encode(<<1>>, using: y.Base32Crockford) == Ok("1")
  assert y.encode(<<1>>, using: y.Base32Clockwork) == Ok("04")
  assert y.encode(<<10>>, using: y.Base58Bitcoin) == Ok("B")
  assert y.encode(<<10>>, using: y.Base58Flickr) == Ok("b")
  assert y.encode(<<10>>, using: y.Base62) == Ok("A")
  assert y.encode(<<32, 32, 32, 32>>, using: y.Ascii85) == Ok("y")
  assert y.encode(<<32, 32, 32, 32>>, using: y.AdobeAscii85) == Ok("<~+<VdL~>")
  assert y.decode("<~y~>", using: y.AdobeAscii85)
    == Error(y.InvalidCharacter("y", 2))
}
