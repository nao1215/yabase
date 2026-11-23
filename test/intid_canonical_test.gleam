import gleam/list
import gleam/option
import gleam/string
import yabase.{NonCanonical, Overflow}

pub fn integer_zero_padding_is_rejected_test() -> Nil {
  [
    #(yabase.Base10, "00"),
    #(yabase.Base16, "0000"),
    #(yabase.Base32Rfc4648, "AAAA===="),
    #(yabase.Base32Crockford, "00"),
    #(yabase.Base32CrockfordCheck, "000"),
    #(yabase.Base36, "00"),
    #(yabase.Base58Bitcoin, "11"),
    #(yabase.Base58Flickr, "11"),
    #(yabase.Base62, "00"),
  ]
  |> list.each(fn(entry) {
    assert yabase.decode_int(entry.1, using: entry.0, up_to: option.None)
      == Error(NonCanonical)
    assert yabase.decode_int(entry.1, using: entry.0, up_to: option.Some(100))
      == Error(NonCanonical)
  })
}

pub fn integer_case_and_crockford_aliases_are_not_canonical_test() -> Nil {
  assert yabase.decode_int("ff", using: yabase.Base16, up_to: option.None)
    == Error(NonCanonical)
  assert yabase.decode_int(
      "ae======",
      using: yabase.Base32Rfc4648,
      up_to: option.None,
    )
    == Error(NonCanonical)
  assert yabase.decode_int(
      "AF======",
      using: yabase.Base32Rfc4648,
      up_to: option.None,
    )
    == Error(NonCanonical)
  assert yabase.decode_int(
      "O",
      using: yabase.Base32Crockford,
      up_to: option.None,
    )
    == Error(NonCanonical)
  assert yabase.decode_int(
      "O0",
      using: yabase.Base32CrockfordCheck,
      up_to: option.None,
    )
    == Error(NonCanonical)
  assert yabase.decode_int("Z", using: yabase.Base36, up_to: option.None)
    == Error(NonCanonical)
}

pub fn integer_canonical_forms_round_trip_test() -> Nil {
  [
    yabase.Base10,
    yabase.Base16,
    yabase.Base32Rfc4648,
    yabase.Base32Crockford,
    yabase.Base32CrockfordCheck,
    yabase.Base36,
    yabase.Base58Bitcoin,
    yabase.Base58Flickr,
    yabase.Base58Check(0),
    yabase.Base58Check(128),
    yabase.Base62,
  ]
  |> list.each(fn(codec) {
    [0, 1, 255, 256, 2025, yabase.int53_max]
    |> list.each(fn(value) {
      let assert Ok(text) = yabase.encode_int(value, using: codec)
      assert yabase.decode_int(text, using: codec, up_to: option.None)
        == Ok(value)
    })
  })
  assert yabase.decode_int("0", using: yabase.Base16, up_to: option.None)
    == Ok(0)
  assert yabase.decode_int("00", using: yabase.Base16, up_to: option.None)
    == Ok(0)
  assert yabase.decode_int("7E9", using: yabase.Base16, up_to: option.None)
    == Ok(2025)
  assert yabase.decode_int("07E9", using: yabase.Base16, up_to: option.None)
    == Ok(2025)
  assert yabase.decode_int("007E9", using: yabase.Base16, up_to: option.None)
    == Error(NonCanonical)
}

pub fn integer_base58check_requires_minimal_payload_test() -> Nil {
  let assert Ok(padded) =
    yabase.encode(<<0, 1>>, using: yabase.Base58Check(128))
  assert yabase.decode_int_base58check(padded, up_to: option.None)
    == Error(NonCanonical)
  assert yabase.decode_int(
      padded,
      using: yabase.Base58Check(128),
      up_to: option.None,
    )
    == Error(NonCanonical)
  let assert Ok(empty) = yabase.encode(<<>>, using: yabase.Base58Check(0))
  assert yabase.decode_int_base58check(empty, up_to: option.None)
    == Error(NonCanonical)
  let assert Ok(canonical) =
    yabase.encode(<<1>>, using: yabase.Base58Check(128))
  assert yabase.decode_int_base58check(canonical, up_to: option.None) == Ok(1)
}

@target(javascript)
pub fn integer_javascript_overflow_is_rejected_test() -> Nil {
  assert yabase.decode_int(
      "9007199254740992",
      using: yabase.Base10,
      up_to: option.None,
    )
    == Error(Overflow)
  assert yabase.decode_int(
      string.repeat("9", 400),
      using: yabase.Base10,
      up_to: option.None,
    )
    == Error(Overflow)
  assert yabase.decode_int(
      string.repeat("z", 300),
      using: yabase.Base58Bitcoin,
      up_to: option.None,
    )
    == Error(Overflow)
  assert yabase.encode_int(yabase.int53_max + 1, using: yabase.Base10)
    == Error(Overflow)
}

@target(erlang)
pub fn integer_erlang_remains_arbitrary_precision_test() -> Nil {
  let text = string.repeat("9", 400)
  let assert Ok(value) =
    yabase.decode_int(text, using: yabase.Base10, up_to: option.None)
  assert yabase.encode_int(value, using: yabase.Base10) == Ok(text)
  assert yabase.decode_int(
      text,
      using: yabase.Base10,
      up_to: option.Some(yabase.int64_max),
    )
    == Error(Overflow)
}
