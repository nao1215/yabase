import codec_test_support
import yabase.{InvalidCharacter}

pub fn encode_empty_test() -> Nil {
  assert codec_test_support.encode(<<>>, using: yabase.Base10) == ""
}

pub fn encode_single_byte_test() -> Nil {
  // 0x41 = 65
  assert codec_test_support.encode(<<0x41>>, using: yabase.Base10) == "65"
}

pub fn encode_zero_test() -> Nil {
  assert codec_test_support.encode(<<0>>, using: yabase.Base10) == "0"
}

pub fn encode_ff_test() -> Nil {
  assert codec_test_support.encode(<<0xff>>, using: yabase.Base10) == "255"
}

pub fn encode_two_bytes_test() -> Nil {
  // 0x01 0x00 = 256
  assert codec_test_support.encode(<<1, 0>>, using: yabase.Base10) == "256"
}

pub fn encode_leading_zeros_test() -> Nil {
  assert codec_test_support.encode(<<0, 0, 1>>, using: yabase.Base10) == "001"
}

pub fn decode_empty_test() -> Nil {
  assert yabase.decode("", using: yabase.Base10) == Ok(<<>>)
}

pub fn decode_single_byte_test() -> Nil {
  assert yabase.decode("65", using: yabase.Base10) == Ok(<<0x41>>)
}

pub fn decode_invalid_char_test() -> Nil {
  assert yabase.decode("12a", using: yabase.Base10)
    == Error(InvalidCharacter("a", 2))
}

pub fn roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base10),
      using: yabase.Base10,
    )
    == Ok(data)
}

pub fn roundtrip_binary_test() -> Nil {
  let data = <<0x00, 0xff, 0x80, 0x01>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base10),
      using: yabase.Base10,
    )
    == Ok(data)
}

pub fn roundtrip_leading_zeros_test() -> Nil {
  let data = <<0, 0, 0, 42>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base10),
      using: yabase.Base10,
    )
    == Ok(data)
}

pub fn decode_leading_zeros_preserved_test() -> Nil {
  assert yabase.decode("001", using: yabase.Base10) == Ok(<<0, 0, 1>>)
}
