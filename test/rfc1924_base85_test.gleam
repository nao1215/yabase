import yabase.{InvalidLength, Overflow}

pub fn encode_empty_test() -> Nil {
  assert yabase.encode(<<>>, using: yabase.Rfc1924Base85) == Ok("")
}

pub fn encode_non_aligned_error_test() -> Nil {
  assert yabase.encode(<<1, 2, 3>>, using: yabase.Rfc1924Base85)
    == Error(InvalidLength(3))
}

pub fn decode_empty_test() -> Nil {
  assert yabase.decode("", using: yabase.Rfc1924Base85) == Ok(<<>>)
}

pub fn decode_invalid_length_test() -> Nil {
  assert yabase.decode("abc", using: yabase.Rfc1924Base85)
    == Error(InvalidLength(3))
}

pub fn decode_overflow_test() -> Nil {
  // Maximum possible: all '~' (index 84) -> 84*85^4+... > 2^32
  assert yabase.decode("~~~~~", using: yabase.Rfc1924Base85) == Error(Overflow)
}

pub fn roundtrip_4bytes_test() -> Nil {
  let data = <<0x01, 0x02, 0x03, 0x04>>
  let assert Ok(encoded) = yabase.encode(data, using: yabase.Rfc1924Base85)
  assert yabase.decode(encoded, using: yabase.Rfc1924Base85) == Ok(data)
}

pub fn roundtrip_8bytes_test() -> Nil {
  let data = <<0xde, 0xad, 0xbe, 0xef, 0xca, 0xfe, 0xba, 0xbe>>
  let assert Ok(encoded) = yabase.encode(data, using: yabase.Rfc1924Base85)
  assert yabase.decode(encoded, using: yabase.Rfc1924Base85) == Ok(data)
}

pub fn roundtrip_all_zeros_test() -> Nil {
  let data = <<0, 0, 0, 0>>
  let assert Ok(encoded) = yabase.encode(data, using: yabase.Rfc1924Base85)
  assert yabase.decode(encoded, using: yabase.Rfc1924Base85) == Ok(data)
}

pub fn roundtrip_all_ff_test() -> Nil {
  let data = <<0xff, 0xff, 0xff, 0xff>>
  let assert Ok(encoded) = yabase.encode(data, using: yabase.Rfc1924Base85)
  assert yabase.decode(encoded, using: yabase.Rfc1924Base85) == Ok(data)
}
