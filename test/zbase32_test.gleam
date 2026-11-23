import codec_test_support
import yabase.{InvalidCharacter}

pub fn encode_empty_test() -> Nil {
  assert codec_test_support.encode(<<>>, using: yabase.Zbase32) == ""
}

pub fn encode_hello_test() -> Nil {
  // "Hello" in z-base-32
  let encoded =
    codec_test_support.encode(<<"Hello":utf8>>, using: yabase.Zbase32)
  // Roundtrip verification
  assert yabase.decode(encoded, using: yabase.Zbase32) == Ok(<<"Hello":utf8>>)
}

pub fn decode_empty_test() -> Nil {
  assert yabase.decode("", using: yabase.Zbase32) == Ok(<<>>)
}

pub fn decode_invalid_char_test() -> Nil {
  assert case yabase.decode("!!!!", using: yabase.Zbase32) {
    Error(InvalidCharacter(_, _)) -> True
    _ -> False
  }
}

pub fn roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Zbase32),
      using: yabase.Zbase32,
    )
    == Ok(data)
}

pub fn roundtrip_empty_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<>>, using: yabase.Zbase32),
      using: yabase.Zbase32,
    )
    == Ok(<<>>)
}

pub fn roundtrip_single_zero_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<0>>, using: yabase.Zbase32),
      using: yabase.Zbase32,
    )
    == Ok(<<0>>)
}

pub fn roundtrip_high_bits_test() -> Nil {
  let data = <<0xff, 0xfe, 0xfd>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Zbase32),
      using: yabase.Zbase32,
    )
    == Ok(data)
}

pub fn roundtrip_leading_zeros_test() -> Nil {
  let data = <<0, 0, 42>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Zbase32),
      using: yabase.Zbase32,
    )
    == Ok(data)
}
