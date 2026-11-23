import gleam/list
import gleam/option.{None, Some}
import yabase as y

pub fn all_ten_integer_formats_use_literal_one_test() {
  let rows = [
    #(y.Base10, "1"),
    #(y.Base16, "01"),
    #(y.Base32Rfc4648, "AE======"),
    #(y.Base32Crockford, "1"),
    #(y.Base32CrockfordCheck, "11"),
    #(y.Base36, "1"),
    #(y.Base58Bitcoin, "2"),
    #(y.Base58Flickr, "2"),
    #(y.Base58Check(0), "18AV53K"),
    #(y.Base62, "1"),
  ]
  list.each(rows, fn(row) {
    assert y.encode_int(1, using: row.0) == Ok(row.1)
    assert y.decode_int(row.1, using: row.0, up_to: None) == Ok(1)
    assert y.decode_int(row.1, using: row.0, up_to: Some(1)) == Ok(1)
    assert y.decode_int(row.1, using: row.0, up_to: Some(0))
      == Error(y.Overflow)
    assert y.decode_int("", using: row.0, up_to: Some(-1))
      == Error(y.InvalidLength(0))
    assert y.encode_int(-1, using: row.0) == Error(y.NegativeValue(-1))
  })
}

pub fn compact_hex_keeps_both_minimal_shapes_test() {
  assert y.encode_int(0, using: y.Base16) == Ok("00")
  assert y.encode_int_base16_compact(0) == Ok("0")
  assert y.encode_int(2025, using: y.Base16) == Ok("07E9")
  assert y.encode_int_base16_compact(2025) == Ok("7E9")
  list.each(
    [
      #("0", 0),
      #("00", 0),
      #("F", 15),
      #("0F", 15),
      #("7E9", 2025),
      #("07E9", 2025),
    ],
    fn(row) {
      assert y.decode_int(row.0, using: y.Base16, up_to: None) == Ok(row.1)
    },
  )
  assert y.decode("F", using: y.Base16) == Error(y.InvalidLength(1))
  assert y.decode_int("000", using: y.Base16, up_to: None)
    == Error(y.NonCanonical)
  assert y.decode_int("f", using: y.Base16, up_to: None)
    == Error(y.NonCanonical)
}

pub fn syntax_and_canonical_precede_explicit_bound_test() {
  assert y.decode_int("12!", using: y.Base16, up_to: Some(-1))
    == Error(y.InvalidCharacter("!", 2))
  assert y.decode_int("000", using: y.Base16, up_to: Some(-1))
    == Error(y.NonCanonical)
  assert y.decode_int("F", using: y.Base16, up_to: Some(15)) == Ok(15)
  assert y.decode_int("F", using: y.Base16, up_to: Some(14))
    == Error(y.Overflow)
  assert y.decode_int("0", using: y.Base10, up_to: Some(-1))
    == Error(y.Overflow)
}

pub fn byte_aliases_do_not_become_canonical_integer_forms_test() {
  let rows = [
    #(y.Base32Rfc4648, "ae======"),
    #(y.Base32Rfc4648, "AF======"),
    #(y.Base32Crockford, "O"),
    #(y.Base32Crockford, "1-"),
    #(y.Base32CrockfordCheck, "O0"),
    #(y.Base36, "Z"),
    #(y.Base58Bitcoin, "12"),
  ]
  list.each(rows, fn(row) {
    assert y.decode_int(row.1, using: row.0, up_to: Some(-1))
      == Error(y.NonCanonical)
  })
  assert y.decode("12", using: y.Base58Bitcoin) == Ok(<<0, 1>>)
  assert y.decode("O", using: y.Base32Crockford) == Ok(<<0>>)
}

pub fn version_agnostic_integer_keeps_all_versions_test() {
  assert y.decode_int_base58check("18AV53K", up_to: None) == Ok(1)
  assert y.decode_int_base58check("26k9aD1PF", up_to: Some(1)) == Ok(1)
  assert y.decode_int_base58check("26k9aD1PF", up_to: Some(0))
    == Error(y.Overflow)
  assert y.decode_int_base58check("5rLWbXvFUx", up_to: Some(-1))
    == Error(y.NonCanonical)
  assert y.decode_int_base58check("FXjQL6s", up_to: None)
    == Error(y.NonCanonical)
  assert y.decode_int_base58check("26k9aD1PG", up_to: Some(-1))
    == Error(y.InvalidChecksum)
}

pub fn lowerhex_is_not_a_new_integer_format_test() {
  assert y.encode_int(1, using: y.Base16Lowercase)
    == Error(y.UnsupportedForInt("Base16Lowercase"))
  assert y.encode_int(-1, using: y.Base16Lowercase)
    == Error(y.UnsupportedForInt("Base16Lowercase"))
  assert y.decode_int("", using: y.Base16Lowercase, up_to: Some(-1))
    == Error(y.UnsupportedForInt("Base16Lowercase"))
}

pub fn unsupported_integer_names_and_admission_are_preserved_test() {
  let rows = [
    #(y.Base2, "Base2"),
    #(y.Base8, "Base8"),
    #(y.Base16Lowercase, "Base16Lowercase"),
    #(y.Base32Hex, "Base32(Hex)"),
    #(y.Base32Clockwork, "Base32(Clockwork)"),
    #(y.Zbase32, "Base32(ZBase32)"),
    #(y.Base45, "Base45"),
    #(y.Base64, "Base64(Standard)"),
    #(y.Base64UrlSafe, "Base64(UrlSafe)"),
    #(y.Base64NoPadding, "Base64(NoPadding)"),
    #(y.Base64UrlSafeNoPadding, "Base64(UrlSafeNoPadding)"),
    #(y.Base64Dq, "Base64(DQ)"),
    #(y.Ascii85, "Base85(Btoa)"),
    #(y.AdobeAscii85, "Base85(Adobe)"),
    #(y.Rfc1924Base85, "Base85(Rfc1924)"),
    #(y.Z85, "Base85(Z85)"),
    #(y.Base91, "Base91"),
    #(y.Bech32Encoding("", y.Bech32), "Bech32"),
    #(y.Bech32Encoding("", y.Bech32m), "Bech32"),
  ]
  list.each(rows, fn(row) {
    assert y.encode_int(-1, using: row.0) == Error(y.UnsupportedForInt(row.1))
    assert y.decode_int("", using: row.0, up_to: Some(-1))
      == Error(y.UnsupportedForInt(row.1))
  })
}

pub fn strict_hex_preserves_lenient_case_and_syntax_test() {
  assert y.decode("ff", using: y.Base16) == Ok(<<255>>)
  assert y.decode_base16_strict("FF") == Ok(<<255>>)
  assert y.decode_base16_strict("ff") == Error(y.NonCanonical)
  assert y.decode_base16_strict("X") == Error(y.InvalidLength(1))
  assert y.decode_base16_strict("0X") == Error(y.InvalidCharacter("X", 1))
}

pub fn strict_base32_preserves_lenient_pad_bits_and_missing_pad_test() {
  assert y.decode("AF======", using: y.Base32Rfc4648) == Ok(<<1>>)
  assert y.decode("AE", using: y.Base32Rfc4648) == Ok(<<1>>)
  assert y.decode_base32_strict("AE======") == Ok(<<1>>)
  assert y.decode_base32_strict("AF======") == Error(y.NonCanonical)
  assert y.decode_base32_strict("ae======") == Error(y.NonCanonical)
  assert y.decode_base32_strict("AE") == Error(y.NonCanonical)
  assert y.decode_base32_strict("!E======") == Error(y.InvalidCharacter("!", 0))
}

pub fn strict_base64_preserves_lenient_pad_bits_and_syntax_test() {
  assert y.decode("AB==", using: y.Base64) == Ok(<<0>>)
  assert y.decode_base64_strict("AA==") == Ok(<<0>>)
  assert y.decode_base64_strict("AB==") == Error(y.NonCanonical)
  assert y.decode_base64_strict("A!===") == Error(y.InvalidCharacter("!", 1))
  assert y.decode("AA==", using: y.Base64NoPadding)
    == Error(y.InvalidCharacter("=", 2))
}

pub fn shared_safe_integer_boundary_test() {
  assert y.int53_max == 9_007_199_254_740_991
  assert y.decode_int("9007199254740990", using: y.Base10, up_to: None)
    == Ok(9_007_199_254_740_990)
  assert y.decode_int("9007199254740991", using: y.Base10, up_to: None)
    == Ok(9_007_199_254_740_991)
}

@target(javascript)
pub fn javascript_overflow_precedes_noncanonical_and_explicit_bound_test() {
  assert y.int64_max == 9_007_199_254_740_991
  assert y.decode_int("9007199254740992", using: y.Base10, up_to: None)
    == Error(y.Overflow)
  assert y.decode_int("09007199254740992", using: y.Base10, up_to: Some(-1))
    == Error(y.Overflow)
}

@target(erlang)
pub fn erlang_retains_arbitrary_precision_and_int64_constant_test() {
  assert y.int64_max == 9_223_372_036_854_775_807
  assert y.decode_int("9007199254740992", using: y.Base10, up_to: None)
    == Ok(9_007_199_254_740_992)
  let text =
    "1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
  let expected =
    1_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000
  assert y.decode_int(text, using: y.Base10, up_to: None) == Ok(expected)
  assert y.encode_int(expected, using: y.Base10) == Ok(text)
  assert y.decode_int(text, using: y.Base10, up_to: Some(y.int64_max))
    == Error(y.Overflow)
}
