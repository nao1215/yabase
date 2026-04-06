import yabase/base58
import yabase/core/encoding.{InvalidCharacter}

pub fn encode_empty_test() {
  assert base58.encode(<<>>) == ""
}

pub fn encode_hello_test() {
  assert base58.encode(<<"Hello World":utf8>>) == "JxF12TrwUP45BMd"
}

pub fn encode_leading_zeros_test() {
  assert base58.encode(<<0, 0, 1>>) == "112"
}

pub fn decode_empty_test() {
  assert base58.decode("") == Ok(<<>>)
}

pub fn decode_hello_test() {
  assert base58.decode("JxF12TrwUP45BMd") == Ok(<<"Hello World":utf8>>)
}

pub fn decode_leading_ones_test() {
  assert base58.decode("112") == Ok(<<0, 0, 1>>)
}

// --- Decode errors ---

pub fn decode_invalid_char_zero_test() {
  // '0' is not in the Base58 alphabet
  assert base58.decode("0") == Error(InvalidCharacter("0", 0))
}

pub fn decode_invalid_char_upper_o_test() {
  assert base58.decode("O") == Error(InvalidCharacter("O", 0))
}

pub fn decode_invalid_char_upper_i_test() {
  assert base58.decode("I") == Error(InvalidCharacter("I", 0))
}

pub fn decode_invalid_char_l_test() {
  assert base58.decode("l") == Error(InvalidCharacter("l", 0))
}

// --- Roundtrip corpus ---

pub fn roundtrip_test() {
  let data = <<"Hello, World!":utf8>>
  assert base58.decode(base58.encode(data)) == Ok(data)
}

pub fn roundtrip_empty_test() {
  assert base58.decode(base58.encode(<<>>)) == Ok(<<>>)
}

pub fn roundtrip_single_zero_test() {
  assert base58.decode(base58.encode(<<0>>)) == Ok(<<0>>)
}

pub fn roundtrip_leading_zeros_test() {
  let data = <<0, 0, 0, 42>>
  assert base58.decode(base58.encode(data)) == Ok(data)
}

pub fn roundtrip_high_bits_test() {
  let data = <<0xff, 0xfe, 0xfd>>
  assert base58.decode(base58.encode(data)) == Ok(data)
}
