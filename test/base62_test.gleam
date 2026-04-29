import yabase/base62
import yabase/core/error.{InvalidCharacter}

pub fn encode_empty_test() -> Nil {
  assert base62.encode(<<>>) == ""
}

pub fn decode_empty_test() -> Nil {
  assert base62.decode("") == Ok(<<>>)
}

pub fn roundtrip_empty_test() -> Nil {
  assert base62.decode(base62.encode(<<>>)) == Ok(<<>>)
}

pub fn roundtrip_single_zero_test() -> Nil {
  assert base62.decode(base62.encode(<<0>>)) == Ok(<<0>>)
}

pub fn roundtrip_leading_zeros_test() -> Nil {
  let data = <<0, 0, 42>>
  assert base62.decode(base62.encode(data)) == Ok(data)
}

pub fn roundtrip_all_zeros_test() -> Nil {
  let data = <<0, 0, 0, 0>>
  assert base62.decode(base62.encode(data)) == Ok(data)
}

pub fn roundtrip_hello_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert base62.decode(base62.encode(data)) == Ok(data)
}

pub fn roundtrip_binary_test() -> Nil {
  let data = <<0xde, 0xad, 0xbe, 0xef>>
  assert base62.decode(base62.encode(data)) == Ok(data)
}

pub fn roundtrip_high_bits_test() -> Nil {
  let data = <<0xff, 0xfe, 0xfd>>
  assert base62.decode(base62.encode(data)) == Ok(data)
}

pub fn decode_leading_zeros_preserved_test() -> Nil {
  assert base62.decode("001") == Ok(<<0, 0, 1>>)
}

pub fn decode_invalid_char_test() -> Nil {
  assert base62.decode("!!!") == Error(InvalidCharacter("!", 0))
}
