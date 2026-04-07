import gleam/string
import yabase/base36
import yabase/core/encoding.{InvalidCharacter}

pub fn encode_empty_test() {
  assert base36.encode(<<>>) == ""
}

pub fn decode_empty_test() {
  assert base36.decode("") == Ok(<<>>)
}

pub fn roundtrip_empty_test() {
  assert base36.decode(base36.encode(<<>>)) == Ok(<<>>)
}

pub fn roundtrip_single_zero_test() {
  assert base36.decode(base36.encode(<<0>>)) == Ok(<<0>>)
}

pub fn roundtrip_leading_zeros_test() {
  let data = <<0, 0, 42>>
  assert base36.decode(base36.encode(data)) == Ok(data)
}

pub fn roundtrip_all_zeros_test() {
  let data = <<0, 0, 0, 0>>
  assert base36.decode(base36.encode(data)) == Ok(data)
}

pub fn roundtrip_hello_test() {
  let data = <<"Hello":utf8>>
  assert base36.decode(base36.encode(data)) == Ok(data)
}

pub fn roundtrip_high_bits_test() {
  let data = <<0xff, 0x80, 0x7f>>
  assert base36.decode(base36.encode(data)) == Ok(data)
}

pub fn decode_case_insensitive_test() {
  let data = <<"test":utf8>>
  let encoded = base36.encode(data)
  let upper = string.uppercase(encoded)
  assert base36.decode(upper) == Ok(data)
}

pub fn decode_leading_zeros_preserved_test() {
  assert base36.decode("001") == Ok(<<0, 0, 1>>)
}

pub fn decode_invalid_char_test() {
  assert base36.decode("!!!") == Error(InvalidCharacter("!", 0))
}
