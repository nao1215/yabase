import yabase/base32/zbase32
import yabase/core/encoding.{InvalidCharacter}

pub fn encode_empty_test() {
  assert zbase32.encode(<<>>) == ""
}

pub fn encode_hello_test() {
  // "Hello" in z-base-32
  let encoded = zbase32.encode(<<"Hello":utf8>>)
  // Roundtrip verification
  assert zbase32.decode(encoded) == Ok(<<"Hello":utf8>>)
}

pub fn decode_empty_test() {
  assert zbase32.decode("") == Ok(<<>>)
}

pub fn decode_invalid_char_test() {
  assert case zbase32.decode("!!!!") {
    Error(InvalidCharacter(_, _)) -> True
    _ -> False
  }
}

pub fn roundtrip_test() {
  let data = <<"Hello, World!":utf8>>
  assert zbase32.decode(zbase32.encode(data)) == Ok(data)
}

pub fn roundtrip_empty_test() {
  assert zbase32.decode(zbase32.encode(<<>>)) == Ok(<<>>)
}

pub fn roundtrip_single_zero_test() {
  assert zbase32.decode(zbase32.encode(<<0>>)) == Ok(<<0>>)
}

pub fn roundtrip_high_bits_test() {
  let data = <<0xff, 0xfe, 0xfd>>
  assert zbase32.decode(zbase32.encode(data)) == Ok(data)
}

pub fn roundtrip_leading_zeros_test() {
  let data = <<0, 0, 42>>
  assert zbase32.decode(zbase32.encode(data)) == Ok(data)
}
