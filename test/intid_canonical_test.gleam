import gleam/list
import gleam/string
import yabase/base58check
import yabase/core/encoding
import yabase/core/error.{NonCanonical, Overflow}
import yabase/intid

pub fn integer_zero_padding_is_rejected_test() -> Nil {
  [
    #(encoding.base10(), "00"),
    #(encoding.base16(), "0000"),
    #(encoding.base32_rfc4648(), "AAAA===="),
    #(encoding.base32_crockford(), "00"),
    #(encoding.base32_crockford_check(), "000"),
    #(encoding.base36(), "00"),
    #(encoding.base58_bitcoin(), "11"),
    #(encoding.base58_flickr(), "11"),
    #(encoding.base62(), "00"),
  ]
  |> list.each(fn(entry) {
    assert intid.decode_int(encoding: entry.0, value: entry.1)
      == Error(NonCanonical)
    assert intid.decode_int_bounded(encoding: entry.0, value: entry.1, max: 100)
      == Error(NonCanonical)
  })
}

pub fn integer_case_and_crockford_aliases_are_not_canonical_test() -> Nil {
  assert intid.decode_int_base16("ff") == Error(NonCanonical)
  assert intid.decode_int_base32_rfc4648("ae======") == Error(NonCanonical)
  assert intid.decode_int_base32_rfc4648("AF======") == Error(NonCanonical)
  assert intid.decode_int_base32_crockford("O") == Error(NonCanonical)
  assert intid.decode_int_base32_crockford_check("O0") == Error(NonCanonical)
  assert intid.decode_int_base36("Z") == Error(NonCanonical)
}

pub fn integer_canonical_forms_round_trip_test() -> Nil {
  [
    encoding.base10(),
    encoding.base16(),
    encoding.base32_rfc4648(),
    encoding.base32_crockford(),
    encoding.base32_crockford_check(),
    encoding.base36(),
    encoding.base58_bitcoin(),
    encoding.base58_flickr(),
    encoding.base58_check(0),
    encoding.base58_check(128),
    encoding.base62(),
  ]
  |> list.each(fn(codec) {
    [0, 1, 255, 256, 2025, intid.int53_max]
    |> list.each(fn(value) {
      let assert Ok(text) = intid.encode_int(encoding: codec, value: value)
      assert intid.decode_int(encoding: codec, value: text) == Ok(value)
    })
  })
  assert intid.decode_int_base16("0") == Ok(0)
  assert intid.decode_int_base16("00") == Ok(0)
  assert intid.decode_int_base16("7E9") == Ok(2025)
  assert intid.decode_int_base16("07E9") == Ok(2025)
  assert intid.decode_int_base16("007E9") == Error(NonCanonical)
}

pub fn integer_base58check_requires_minimal_payload_test() -> Nil {
  let assert Ok(padded) = base58check.encode(128, <<0, 1>>)
  assert intid.decode_int_base58check(padded) == Error(NonCanonical)
  assert intid.decode_int(encoding: encoding.base58_check(128), value: padded)
    == Error(NonCanonical)
  let assert Ok(empty) = base58check.encode(0, <<>>)
  assert intid.decode_int_base58check(empty) == Error(NonCanonical)
  let assert Ok(canonical) = base58check.encode(128, <<1>>)
  assert intid.decode_int_base58check(canonical) == Ok(1)
}

@target(javascript)
pub fn integer_javascript_overflow_is_rejected_test() -> Nil {
  assert intid.decode_int_base10("9007199254740992") == Error(Overflow)
  assert intid.decode_int_base10(string.repeat("9", 400)) == Error(Overflow)
  assert intid.decode_int_base58(string.repeat("z", 300)) == Error(Overflow)
  assert intid.encode_int_base10(intid.int53_max + 1) == Error(Overflow)
}

@target(erlang)
pub fn integer_erlang_remains_arbitrary_precision_test() -> Nil {
  let text = string.repeat("9", 400)
  let assert Ok(value) = intid.decode_int_base10(text)
  assert intid.encode_int_base10(value) == Ok(text)
  assert intid.decode_int_base10_bounded(input: text, max: intid.int64_max)
    == Error(Overflow)
}
