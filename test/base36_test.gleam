import gleam/string
import yabase/base36
import yabase/core/error.{InvalidCharacter}

pub fn encode_empty_test() -> Nil {
  assert base36.encode(<<>>) == ""
}

pub fn decode_empty_test() -> Nil {
  assert base36.decode("") == Ok(<<>>)
}

pub fn roundtrip_empty_test() -> Nil {
  assert base36.decode(base36.encode(<<>>)) == Ok(<<>>)
}

pub fn roundtrip_single_zero_test() -> Nil {
  assert base36.decode(base36.encode(<<0>>)) == Ok(<<0>>)
}

pub fn roundtrip_leading_zeros_test() -> Nil {
  let data = <<0, 0, 42>>
  assert base36.decode(base36.encode(data)) == Ok(data)
}

pub fn roundtrip_all_zeros_test() -> Nil {
  let data = <<0, 0, 0, 0>>
  assert base36.decode(base36.encode(data)) == Ok(data)
}

pub fn roundtrip_hello_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert base36.decode(base36.encode(data)) == Ok(data)
}

pub fn roundtrip_high_bits_test() -> Nil {
  let data = <<0xff, 0x80, 0x7f>>
  assert base36.decode(base36.encode(data)) == Ok(data)
}

pub fn decode_case_insensitive_test() -> Nil {
  let data = <<"test":utf8>>
  let encoded = base36.encode(data)
  let upper = string.uppercase(encoded)
  assert base36.decode(upper) == Ok(data)
}

pub fn decode_leading_zeros_preserved_test() -> Nil {
  assert base36.decode("001") == Ok(<<0, 0, 1>>)
}

pub fn decode_invalid_char_test() -> Nil {
  assert base36.decode("!!!") == Error(InvalidCharacter("!", 0))
}
