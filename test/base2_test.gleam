import codec_test_support
import yabase.{InvalidCharacter, InvalidLength}

pub fn encode_empty_test() -> Nil {
  assert codec_test_support.encode(<<>>, using: yabase.Base2) == ""
}

pub fn encode_single_byte_test() -> Nil {
  assert codec_test_support.encode(<<0x41>>, using: yabase.Base2) == "01000001"
}

pub fn encode_zero_test() -> Nil {
  assert codec_test_support.encode(<<0>>, using: yabase.Base2) == "00000000"
}

pub fn encode_ff_test() -> Nil {
  assert codec_test_support.encode(<<0xff>>, using: yabase.Base2) == "11111111"
}

pub fn encode_hello_test() -> Nil {
  // "Hi" = 0x48 0x69
  assert codec_test_support.encode(<<"Hi":utf8>>, using: yabase.Base2)
    == "0100100001101001"
}

pub fn decode_empty_test() -> Nil {
  assert yabase.decode("", using: yabase.Base2) == Ok(<<>>)
}

pub fn decode_single_byte_test() -> Nil {
  assert yabase.decode("01000001", using: yabase.Base2) == Ok(<<0x41>>)
}

pub fn decode_zero_test() -> Nil {
  assert yabase.decode("00000000", using: yabase.Base2) == Ok(<<0>>)
}

pub fn decode_ff_test() -> Nil {
  assert yabase.decode("11111111", using: yabase.Base2) == Ok(<<0xff>>)
}

pub fn decode_invalid_length_test() -> Nil {
  assert yabase.decode("0100", using: yabase.Base2) == Error(InvalidLength(4))
}

pub fn decode_invalid_char_test() -> Nil {
  assert yabase.decode("0100000X", using: yabase.Base2)
    == Error(InvalidCharacter("X", 7))
}

pub fn roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base2),
      using: yabase.Base2,
    )
    == Ok(data)
}

pub fn roundtrip_binary_data_test() -> Nil {
  let data = <<0x00, 0xff, 0x80, 0x7f, 0x01>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base2),
      using: yabase.Base2,
    )
    == Ok(data)
}
