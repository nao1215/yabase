import yabase/base2
import yabase/core/encoding.{InvalidCharacter, InvalidLength}

pub fn encode_empty_test() {
  assert base2.encode(<<>>) == ""
}

pub fn encode_single_byte_test() {
  assert base2.encode(<<0x41>>) == "01000001"
}

pub fn encode_zero_test() {
  assert base2.encode(<<0>>) == "00000000"
}

pub fn encode_ff_test() {
  assert base2.encode(<<0xff>>) == "11111111"
}

pub fn encode_hello_test() {
  // "Hi" = 0x48 0x69
  assert base2.encode(<<"Hi":utf8>>) == "0100100001101001"
}

pub fn decode_empty_test() {
  assert base2.decode("") == Ok(<<>>)
}

pub fn decode_single_byte_test() {
  assert base2.decode("01000001") == Ok(<<0x41>>)
}

pub fn decode_zero_test() {
  assert base2.decode("00000000") == Ok(<<0>>)
}

pub fn decode_ff_test() {
  assert base2.decode("11111111") == Ok(<<0xff>>)
}

pub fn decode_invalid_length_test() {
  assert base2.decode("0100") == Error(InvalidLength(4))
}

pub fn decode_invalid_char_test() {
  assert base2.decode("0100000X") == Error(InvalidCharacter("X", 7))
}

pub fn roundtrip_test() {
  let data = <<"Hello, World!":utf8>>
  assert base2.decode(base2.encode(data)) == Ok(data)
}

pub fn roundtrip_binary_data_test() {
  let data = <<0x00, 0xff, 0x80, 0x7f, 0x01>>
  assert base2.decode(base2.encode(data)) == Ok(data)
}
