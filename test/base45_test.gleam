import codec_test_support
import yabase.{InvalidCharacter, InvalidLength, Overflow}

pub fn encode_empty_test() -> Nil {
  assert codec_test_support.encode(<<>>, using: yabase.Base45) == ""
}

pub fn encode_ab_test() -> Nil {
  assert codec_test_support.encode(<<"AB":utf8>>, using: yabase.Base45) == "BB8"
}

pub fn encode_hello_test() -> Nil {
  assert codec_test_support.encode(<<"Hello!!":utf8>>, using: yabase.Base45)
    == "%69 VD92EX0"
}

pub fn decode_empty_test() -> Nil {
  assert yabase.decode("", using: yabase.Base45) == Ok(<<>>)
}

pub fn decode_ab_test() -> Nil {
  assert yabase.decode("BB8", using: yabase.Base45) == Ok(<<"AB":utf8>>)
}

// --- Decode errors ---

pub fn decode_invalid_length_1_test() -> Nil {
  assert yabase.decode("A", using: yabase.Base45) == Error(InvalidLength(1))
}

pub fn decode_invalid_length_4_test() -> Nil {
  assert yabase.decode("ABCD", using: yabase.Base45) == Error(InvalidLength(4))
}

pub fn decode_invalid_char_test() -> Nil {
  assert yabase.decode("@@", using: yabase.Base45)
    == Error(InvalidCharacter("@", 0))
}

// --- RFC 9285 test vectors ---

pub fn rfc9285_example1_encode_test() -> Nil {
  // Example 1: "AB" -> "BB8"
  assert codec_test_support.encode(<<"AB":utf8>>, using: yabase.Base45) == "BB8"
}

pub fn rfc9285_example2_encode_test() -> Nil {
  // Example 2: "Hello!!" -> "%69 VD92EX0"
  assert codec_test_support.encode(<<"Hello!!":utf8>>, using: yabase.Base45)
    == "%69 VD92EX0"
}

pub fn rfc9285_example3_encode_test() -> Nil {
  // Example 3: "base-45" -> "UJCLQE7W581"
  assert codec_test_support.encode(<<"base-45":utf8>>, using: yabase.Base45)
    == "UJCLQE7W581"
}

pub fn rfc9285_example3_decode_test() -> Nil {
  assert yabase.decode("UJCLQE7W581", using: yabase.Base45)
    == Ok(<<"base-45":utf8>>)
}

// --- Cross-reference vectors (shogo82148/base45) ---

pub fn rfc9285_ietf_encode_test() -> Nil {
  assert codec_test_support.encode(<<"ietf!":utf8>>, using: yabase.Base45)
    == "QED8WEX0"
}

pub fn rfc9285_ietf_decode_test() -> Nil {
  assert yabase.decode("QED8WEX0", using: yabase.Base45) == Ok(<<"ietf!":utf8>>)
}

pub fn encode_hello_world_test() -> Nil {
  assert codec_test_support.encode(
      <<"Hello, world!":utf8>>,
      using: yabase.Base45,
    )
    == "%69 VDK2EV4404ESVDX0"
}

pub fn decode_hello_world_test() -> Nil {
  assert yabase.decode("%69 VDK2EV4404ESVDX0", using: yabase.Base45)
    == Ok(<<"Hello, world!":utf8>>)
}

pub fn encode_with_null_byte_test() -> Nil {
  // "some data with \x00 and \ufeff"
  let data = <<"some data with ":utf8, 0x00, " and ":utf8, 0xEF, 0xBB, 0xBF>>
  assert codec_test_support.encode(data, using: yabase.Base45)
    == "VQEF$DC44IECOCCE4FAWE2249440/DG743XN"
}

pub fn decode_with_null_byte_test() -> Nil {
  let expected = <<
    "some data with ":utf8, 0x00, " and ":utf8, 0xEF, 0xBB, 0xBF,
  >>
  assert yabase.decode(
      "VQEF$DC44IECOCCE4FAWE2249440/DG743XN",
      using: yabase.Base45,
    )
    == Ok(expected)
}

// --- Overflow rejection ---

pub fn decode_overflow_3char_group_test() -> Nil {
  // "GGW" -> G=16, W=32 -> 16 + 32*45 + ... check if > 65535
  // Maximum valid 3-char group is value 65535
  // ":::" -> ':'=44 -> 44 + 44*45 + 44*45*45 = 44 + 1980 + 89100 = 91124 > 65535
  assert yabase.decode(":::", using: yabase.Base45) == Error(Overflow)
}

pub fn decode_overflow_2char_group_test() -> Nil {
  // Maximum valid 2-char value is 255
  // "::" -> 44 + 44*45 = 44 + 1980 = 2024 > 255
  assert yabase.decode("::", using: yabase.Base45) == Error(Overflow)
}

// --- Roundtrip corpus ---

pub fn roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base45),
      using: yabase.Base45,
    )
    == Ok(data)
}

pub fn roundtrip_empty_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<>>, using: yabase.Base45),
      using: yabase.Base45,
    )
    == Ok(<<>>)
}

pub fn roundtrip_single_byte_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<42>>, using: yabase.Base45),
      using: yabase.Base45,
    )
    == Ok(<<42>>)
}

pub fn roundtrip_high_bits_test() -> Nil {
  let data = <<0xff, 0xfe>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base45),
      using: yabase.Base45,
    )
    == Ok(data)
}

pub fn decode_largest_groups_test() -> Nil {
  assert yabase.decode("FGW", using: yabase.Base45) == Ok(<<255, 255>>)
  assert yabase.decode("GGW", using: yabase.Base45) == Error(Overflow)
  assert yabase.decode("U5", using: yabase.Base45) == Ok(<<255>>)
  assert yabase.decode("V5", using: yabase.Base45) == Error(Overflow)
}
