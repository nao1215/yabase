import codec_test_support
import yabase.{InvalidCharacter}

pub fn encode_empty_test() -> Nil {
  assert codec_test_support.encode(<<>>, using: yabase.Base62) == ""
}

pub fn decode_empty_test() -> Nil {
  assert yabase.decode("", using: yabase.Base62) == Ok(<<>>)
}

pub fn roundtrip_empty_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<>>, using: yabase.Base62),
      using: yabase.Base62,
    )
    == Ok(<<>>)
}

pub fn roundtrip_single_zero_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<0>>, using: yabase.Base62),
      using: yabase.Base62,
    )
    == Ok(<<0>>)
}

pub fn roundtrip_leading_zeros_test() -> Nil {
  let data = <<0, 0, 42>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base62),
      using: yabase.Base62,
    )
    == Ok(data)
}

pub fn roundtrip_all_zeros_test() -> Nil {
  let data = <<0, 0, 0, 0>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base62),
      using: yabase.Base62,
    )
    == Ok(data)
}

pub fn roundtrip_hello_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base62),
      using: yabase.Base62,
    )
    == Ok(data)
}

pub fn roundtrip_binary_test() -> Nil {
  let data = <<0xde, 0xad, 0xbe, 0xef>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base62),
      using: yabase.Base62,
    )
    == Ok(data)
}

pub fn roundtrip_high_bits_test() -> Nil {
  let data = <<0xff, 0xfe, 0xfd>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base62),
      using: yabase.Base62,
    )
    == Ok(data)
}

pub fn decode_leading_zeros_preserved_test() -> Nil {
  assert yabase.decode("001", using: yabase.Base62) == Ok(<<0, 0, 1>>)
}

pub fn decode_invalid_char_test() -> Nil {
  assert yabase.decode("!!!", using: yabase.Base62)
    == Error(InvalidCharacter("!", 0))
}
