import yabase/base8
import yabase/core/encoding.{InvalidCharacter}

pub fn encode_empty_test() -> Nil {
  assert base8.encode(<<>>) == ""
}

pub fn encode_single_byte_test() -> Nil {
  // 0x41 = 65 = octal 101
  assert base8.encode(<<0x41>>) == "101"
}

pub fn encode_zero_test() -> Nil {
  assert base8.encode(<<0>>) == "0"
}

pub fn encode_ff_test() -> Nil {
  // 0xff = 255 = octal 377
  assert base8.encode(<<0xff>>) == "377"
}

pub fn encode_leading_zeros_test() -> Nil {
  assert base8.encode(<<0, 0, 1>>) == "001"
}

pub fn decode_empty_test() -> Nil {
  assert base8.decode("") == Ok(<<>>)
}

pub fn decode_single_byte_test() -> Nil {
  assert base8.decode("101") == Ok(<<0x41>>)
}

pub fn decode_invalid_char_test() -> Nil {
  assert base8.decode("8") == Error(InvalidCharacter("8", 0))
}

pub fn decode_invalid_char_letter_test() -> Nil {
  assert base8.decode("12a") == Error(InvalidCharacter("a", 2))
}

pub fn roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert base8.decode(base8.encode(data)) == Ok(data)
}

pub fn roundtrip_binary_test() -> Nil {
  let data = <<0x00, 0xff, 0x80, 0x01>>
  assert base8.decode(base8.encode(data)) == Ok(data)
}

pub fn roundtrip_leading_zeros_test() -> Nil {
  let data = <<0, 0, 0, 42>>
  assert base8.decode(base8.encode(data)) == Ok(data)
}

// Leading zero chars in decode produce leading 0x00 bytes (API contract)
pub fn decode_leading_zeros_preserved_test() -> Nil {
  assert base8.decode("001") == Ok(<<0, 0, 1>>)
}
