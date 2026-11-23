import codec_test_support
import yabase.{InvalidCharacter}

pub fn encode_empty_test() -> Nil {
  assert codec_test_support.encode(<<>>, using: yabase.Base8) == ""
}

pub fn encode_single_byte_test() -> Nil {
  // 0x41 = 65 = octal 101
  assert codec_test_support.encode(<<0x41>>, using: yabase.Base8) == "101"
}

pub fn encode_zero_test() -> Nil {
  assert codec_test_support.encode(<<0>>, using: yabase.Base8) == "0"
}

pub fn encode_ff_test() -> Nil {
  // 0xff = 255 = octal 377
  assert codec_test_support.encode(<<0xff>>, using: yabase.Base8) == "377"
}

pub fn encode_leading_zeros_test() -> Nil {
  assert codec_test_support.encode(<<0, 0, 1>>, using: yabase.Base8) == "001"
}

pub fn decode_empty_test() -> Nil {
  assert yabase.decode("", using: yabase.Base8) == Ok(<<>>)
}

pub fn decode_single_byte_test() -> Nil {
  assert yabase.decode("101", using: yabase.Base8) == Ok(<<0x41>>)
}

pub fn decode_invalid_char_test() -> Nil {
  assert yabase.decode("8", using: yabase.Base8)
    == Error(InvalidCharacter("8", 0))
}

pub fn decode_invalid_char_letter_test() -> Nil {
  assert yabase.decode("12a", using: yabase.Base8)
    == Error(InvalidCharacter("a", 2))
}

pub fn roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base8),
      using: yabase.Base8,
    )
    == Ok(data)
}

pub fn roundtrip_binary_test() -> Nil {
  let data = <<0x00, 0xff, 0x80, 0x01>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base8),
      using: yabase.Base8,
    )
    == Ok(data)
}

pub fn roundtrip_leading_zeros_test() -> Nil {
  let data = <<0, 0, 0, 42>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base8),
      using: yabase.Base8,
    )
    == Ok(data)
}

// Leading zero chars in decode produce leading 0x00 bytes (API contract)
pub fn decode_leading_zeros_preserved_test() -> Nil {
  assert yabase.decode("001", using: yabase.Base8) == Ok(<<0, 0, 1>>)
}
