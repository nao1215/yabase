import yabase/base45
import yabase/core/encoding.{InvalidCharacter, InvalidLength, Overflow}

pub fn encode_empty_test() {
  assert base45.encode(<<>>) == ""
}

pub fn encode_ab_test() {
  assert base45.encode(<<"AB":utf8>>) == "BB8"
}

pub fn encode_hello_test() {
  assert base45.encode(<<"Hello!!":utf8>>) == "%69 VD92EX0"
}

pub fn decode_empty_test() {
  assert base45.decode("") == Ok(<<>>)
}

pub fn decode_ab_test() {
  assert base45.decode("BB8") == Ok(<<"AB":utf8>>)
}

// --- Decode errors ---

pub fn decode_invalid_length_1_test() {
  assert base45.decode("A") == Error(InvalidLength(1))
}

pub fn decode_invalid_length_4_test() {
  assert base45.decode("ABCD") == Error(InvalidLength(4))
}

pub fn decode_invalid_char_test() {
  assert base45.decode("@@") == Error(InvalidCharacter("@", 0))
}

// --- RFC 9285 test vectors ---

pub fn rfc9285_example1_encode_test() {
  // Example 1: "AB" -> "BB8"
  assert base45.encode(<<"AB":utf8>>) == "BB8"
}

pub fn rfc9285_example2_encode_test() {
  // Example 2: "Hello!!" -> "%69 VD92EX0"
  assert base45.encode(<<"Hello!!":utf8>>) == "%69 VD92EX0"
}

pub fn rfc9285_example3_encode_test() {
  // Example 3: "base-45" -> "UJCLQE7W581"
  assert base45.encode(<<"base-45":utf8>>) == "UJCLQE7W581"
}

pub fn rfc9285_example3_decode_test() {
  assert base45.decode("UJCLQE7W581") == Ok(<<"base-45":utf8>>)
}

// --- Cross-reference vectors (shogo82148/base45) ---

pub fn rfc9285_ietf_encode_test() {
  assert base45.encode(<<"ietf!":utf8>>) == "QED8WEX0"
}

pub fn rfc9285_ietf_decode_test() {
  assert base45.decode("QED8WEX0") == Ok(<<"ietf!":utf8>>)
}

pub fn encode_hello_world_test() {
  assert base45.encode(<<"Hello, world!":utf8>>) == "%69 VDK2EV4404ESVDX0"
}

pub fn decode_hello_world_test() {
  assert base45.decode("%69 VDK2EV4404ESVDX0") == Ok(<<"Hello, world!":utf8>>)
}

pub fn encode_with_null_byte_test() {
  // "some data with \x00 and \ufeff"
  let data = <<"some data with ":utf8, 0x00, " and ":utf8, 0xEF, 0xBB, 0xBF>>
  assert base45.encode(data) == "VQEF$DC44IECOCCE4FAWE2249440/DG743XN"
}

pub fn decode_with_null_byte_test() {
  let expected = <<
    "some data with ":utf8, 0x00, " and ":utf8, 0xEF, 0xBB, 0xBF,
  >>
  assert base45.decode("VQEF$DC44IECOCCE4FAWE2249440/DG743XN") == Ok(expected)
}

// --- Overflow rejection ---

pub fn decode_overflow_3char_group_test() {
  // "GGW" -> G=16, W=32 -> 16 + 32*45 + ... check if > 65535
  // Maximum valid 3-char group is value 65535
  // ":::" -> ':'=44 -> 44 + 44*45 + 44*45*45 = 44 + 1980 + 89100 = 91124 > 65535
  assert base45.decode(":::") == Error(Overflow)
}

pub fn decode_overflow_2char_group_test() {
  // Maximum valid 2-char value is 255
  // "::" -> 44 + 44*45 = 44 + 1980 = 2024 > 255
  assert base45.decode("::") == Error(Overflow)
}

// --- Roundtrip corpus ---

pub fn roundtrip_test() {
  let data = <<"Hello, World!":utf8>>
  assert base45.decode(base45.encode(data)) == Ok(data)
}

pub fn roundtrip_empty_test() {
  assert base45.decode(base45.encode(<<>>)) == Ok(<<>>)
}

pub fn roundtrip_single_byte_test() {
  assert base45.decode(base45.encode(<<42>>)) == Ok(<<42>>)
}

pub fn roundtrip_high_bits_test() {
  let data = <<0xff, 0xfe>>
  assert base45.decode(base45.encode(data)) == Ok(data)
}
