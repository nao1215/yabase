import yabase/base10
import yabase/core/encoding.{InvalidCharacter}

pub fn encode_empty_test() {
  assert base10.encode(<<>>) == ""
}

pub fn encode_single_byte_test() {
  // 0x41 = 65
  assert base10.encode(<<0x41>>) == "65"
}

pub fn encode_zero_test() {
  assert base10.encode(<<0>>) == "0"
}

pub fn encode_ff_test() {
  assert base10.encode(<<0xff>>) == "255"
}

pub fn encode_two_bytes_test() {
  // 0x01 0x00 = 256
  assert base10.encode(<<1, 0>>) == "256"
}

pub fn encode_leading_zeros_test() {
  assert base10.encode(<<0, 0, 1>>) == "001"
}

pub fn decode_empty_test() {
  assert base10.decode("") == Ok(<<>>)
}

pub fn decode_single_byte_test() {
  assert base10.decode("65") == Ok(<<0x41>>)
}

pub fn decode_invalid_char_test() {
  assert base10.decode("12a") == Error(InvalidCharacter("a", 2))
}

pub fn roundtrip_test() {
  let data = <<"Hello":utf8>>
  assert base10.decode(base10.encode(data)) == Ok(data)
}

pub fn roundtrip_binary_test() {
  let data = <<0x00, 0xff, 0x80, 0x01>>
  assert base10.decode(base10.encode(data)) == Ok(data)
}

pub fn roundtrip_leading_zeros_test() {
  let data = <<0, 0, 0, 42>>
  assert base10.decode(base10.encode(data)) == Ok(data)
}
