import gleam/option.{None}
import gleeunit/should
import yabase

// Erlang strings are binaries, so FFI code can hand a decoder bytes that are
// not UTF-8. Decoders must report them instead of crashing or truncating.
@target(erlang)
@external(erlang, "gleam_stdlib", "identity")
fn unchecked_string(bits: BitArray) -> String

@target(erlang)
pub fn invalid_utf8_is_an_invalid_character_test() {
  yabase.decode(unchecked_string(<<"AAA", 0xFF>>), using: yabase.Base64)
  |> should.equal(Error(yabase.InvalidCharacter("", 3)))
  yabase.decode(
    unchecked_string(<<"AB", 0xFF, "C">>),
    using: yabase.Base58Bitcoin,
  )
  |> should.equal(Error(yabase.InvalidCharacter("", 2)))
  yabase.decode(unchecked_string(<<"0", 0xFF>>), using: yabase.Base16)
  |> should.equal(Error(yabase.InvalidCharacter("", 1)))
  yabase.decode_multibase(unchecked_string(<<"z", 0xFF>>))
  |> should.equal(Error(yabase.InvalidCharacter("", 1)))
  yabase.decode_bech32(unchecked_string(<<"a1", 0xFF>>))
  |> should.equal(Error(yabase.InvalidCharacter("", 2)))
  yabase.decode_base58check(unchecked_string(<<0xFF>>))
  |> should.equal(Error(yabase.InvalidCharacter("", 0)))
  yabase.decode_base64_strict(unchecked_string(<<"TQ=", 0xFF>>))
  |> should.equal(Error(yabase.InvalidCharacter("", 3)))
}

@target(erlang)
pub fn adobe_does_not_drop_bytes_after_invalid_utf8_test() {
  yabase.decode(
    unchecked_string(<<"<~9jqo^~>", 0xFF, "~>">>),
    using: yabase.AdobeAscii85,
  )
  |> should.equal(Error(yabase.InvalidCharacter("", 9)))
  yabase.decode(
    unchecked_string(<<"<~~>", 0xFF, "garbage">>),
    using: yabase.AdobeAscii85,
  )
  |> should.equal(Error(yabase.InvalidCharacter("", 4)))
}

pub fn uppercase_expected_hrp_is_an_invalid_hrp_test() {
  // encode rejects the same Encoding value; decode must agree instead of
  // reporting an HRP mismatch that can never be resolved.
  let encoding = yabase.Bech32Encoding("BC", yabase.Bech32)
  let assert Ok(wire) =
    yabase.encode(
      <<1, 2, 3>>,
      using: yabase.Bech32Encoding("bc", yabase.Bech32),
    )
  yabase.decode(wire, using: encoding)
  |> should.equal(Error(yabase.InvalidHrp("HRP must be lowercase")))
  yabase.encode(<<1, 2, 3>>, using: encoding)
  |> should.equal(Error(yabase.InvalidHrp("HRP must be lowercase")))
}

pub fn unsupported_for_int_uses_the_encoding_name_test() {
  yabase.encode_int(1, using: yabase.Base64Dq)
  |> should.equal(Error(yabase.UnsupportedForInt("base64dq")))
  yabase.decode_int("1", using: yabase.Base32Hex, up_to: None)
  |> should.equal(
    Error(yabase.UnsupportedForInt(yabase.encoding_to_string(yabase.Base32Hex))),
  )
  yabase.encode_int(1, using: yabase.Ascii85)
  |> should.equal(
    Error(yabase.UnsupportedForInt(yabase.encoding_to_string(yabase.Ascii85))),
  )
}
