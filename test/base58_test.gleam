import codec_test_support
import yabase.{InvalidCharacter}

// === Bitcoin alphabet ===

pub fn bitcoin_encode_empty_test() -> Nil {
  assert codec_test_support.encode(<<>>, using: yabase.Base58Bitcoin) == ""
}

pub fn bitcoin_encode_hello_test() -> Nil {
  assert codec_test_support.encode(
      <<"Hello World":utf8>>,
      using: yabase.Base58Bitcoin,
    )
    == "JxF12TrwUP45BMd"
}

pub fn bitcoin_encode_leading_zeros_test() -> Nil {
  assert codec_test_support.encode(<<0, 0, 1>>, using: yabase.Base58Bitcoin)
    == "112"
}

pub fn bitcoin_decode_empty_test() -> Nil {
  assert yabase.decode("", using: yabase.Base58Bitcoin) == Ok(<<>>)
}

pub fn bitcoin_decode_hello_test() -> Nil {
  assert yabase.decode("JxF12TrwUP45BMd", using: yabase.Base58Bitcoin)
    == Ok(<<"Hello World":utf8>>)
}

pub fn bitcoin_decode_leading_ones_test() -> Nil {
  assert yabase.decode("112", using: yabase.Base58Bitcoin) == Ok(<<0, 0, 1>>)
}

pub fn bitcoin_decode_invalid_char_zero_test() -> Nil {
  assert yabase.decode("0", using: yabase.Base58Bitcoin)
    == Error(InvalidCharacter("0", 0))
}

pub fn bitcoin_decode_invalid_char_upper_o_test() -> Nil {
  assert yabase.decode("O", using: yabase.Base58Bitcoin)
    == Error(InvalidCharacter("O", 0))
}

pub fn bitcoin_decode_invalid_char_upper_i_test() -> Nil {
  assert yabase.decode("I", using: yabase.Base58Bitcoin)
    == Error(InvalidCharacter("I", 0))
}

pub fn bitcoin_decode_invalid_char_l_test() -> Nil {
  assert yabase.decode("l", using: yabase.Base58Bitcoin)
    == Error(InvalidCharacter("l", 0))
}

pub fn bitcoin_roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base58Bitcoin),
      using: yabase.Base58Bitcoin,
    )
    == Ok(data)
}

pub fn bitcoin_roundtrip_empty_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<>>, using: yabase.Base58Bitcoin),
      using: yabase.Base58Bitcoin,
    )
    == Ok(<<>>)
}

pub fn bitcoin_roundtrip_single_zero_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<0>>, using: yabase.Base58Bitcoin),
      using: yabase.Base58Bitcoin,
    )
    == Ok(<<0>>)
}

pub fn bitcoin_roundtrip_leading_zeros_test() -> Nil {
  let data = <<0, 0, 0, 42>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base58Bitcoin),
      using: yabase.Base58Bitcoin,
    )
    == Ok(data)
}

pub fn bitcoin_roundtrip_high_bits_test() -> Nil {
  let data = <<0xff, 0xfe, 0xfd>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base58Bitcoin),
      using: yabase.Base58Bitcoin,
    )
    == Ok(data)
}

// === Flickr alphabet ===

pub fn flickr_encode_empty_test() -> Nil {
  assert codec_test_support.encode(<<>>, using: yabase.Base58Flickr) == ""
}

pub fn flickr_encode_hello_test() -> Nil {
  let encoded =
    codec_test_support.encode(
      <<"Hello World":utf8>>,
      using: yabase.Base58Flickr,
    )
  // Flickr swaps upper/lowercase relative to Bitcoin
  assert encoded == "iXf12sRWto45bmC"
}

pub fn flickr_decode_hello_test() -> Nil {
  assert yabase.decode("iXf12sRWto45bmC", using: yabase.Base58Flickr)
    == Ok(<<"Hello World":utf8>>)
}

pub fn flickr_decode_invalid_char_zero_test() -> Nil {
  assert yabase.decode("0", using: yabase.Base58Flickr)
    == Error(InvalidCharacter("0", 0))
}

pub fn flickr_roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base58Flickr),
      using: yabase.Base58Flickr,
    )
    == Ok(data)
}

pub fn flickr_roundtrip_empty_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<>>, using: yabase.Base58Flickr),
      using: yabase.Base58Flickr,
    )
    == Ok(<<>>)
}

pub fn flickr_roundtrip_single_zero_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<0>>, using: yabase.Base58Flickr),
      using: yabase.Base58Flickr,
    )
    == Ok(<<0>>)
}

pub fn flickr_roundtrip_leading_zeros_test() -> Nil {
  let data = <<0, 0, 0, 42>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base58Flickr),
      using: yabase.Base58Flickr,
    )
    == Ok(data)
}

pub fn flickr_roundtrip_high_bits_test() -> Nil {
  let data = <<0xff, 0xfe, 0xfd>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base58Flickr),
      using: yabase.Base58Flickr,
    )
    == Ok(data)
}

// === Cross-alphabet: same data, different output ===

pub fn bitcoin_flickr_different_output_test() -> Nil {
  let data = <<"test":utf8>>
  assert codec_test_support.encode(data, using: yabase.Base58Bitcoin)
    != codec_test_support.encode(data, using: yabase.Base58Flickr)
}

pub fn bitcoin_flickr_same_data_test() -> Nil {
  let data = <<"test":utf8>>
  let assert Ok(d1) =
    yabase.decode(
      codec_test_support.encode(data, using: yabase.Base58Bitcoin),
      using: yabase.Base58Bitcoin,
    )
  let assert Ok(d2) =
    yabase.decode(
      codec_test_support.encode(data, using: yabase.Base58Flickr),
      using: yabase.Base58Flickr,
    )
  assert d1 == d2
}

// === Cross-reference vectors (paulmillr/scure-base) ===

pub fn scure_hello_world_test() -> Nil {
  assert codec_test_support.encode(
      <<"hello world":utf8>>,
      using: yabase.Base58Bitcoin,
    )
    == "StV1DL6CwTryKyV"
  assert yabase.decode("StV1DL6CwTryKyV", using: yabase.Base58Bitcoin)
    == Ok(<<"hello world":utf8>>)
}

pub fn scure_hello_world_excl_test() -> Nil {
  assert codec_test_support.encode(
      <<"Hello World!":utf8>>,
      using: yabase.Base58Bitcoin,
    )
    == "2NEpo7TZRRrLZSi2U"
  assert yabase.decode("2NEpo7TZRRrLZSi2U", using: yabase.Base58Bitcoin)
    == Ok(<<"Hello World!":utf8>>)
}

pub fn scure_leading_zeros_test() -> Nil {
  assert codec_test_support.encode(
      <<0, 0, 0x28, 0x7f, 0xb4, 0xcd>>,
      using: yabase.Base58Bitcoin,
    )
    == "11233QC4"
  assert yabase.decode("11233QC4", using: yabase.Base58Bitcoin)
    == Ok(<<0, 0, 0x28, 0x7f, 0xb4, 0xcd>>)
}

pub fn scure_quick_brown_fox_test() -> Nil {
  let data = <<"The quick brown fox jumps over the lazy dog.":utf8>>
  assert codec_test_support.encode(data, using: yabase.Base58Bitcoin)
    == "USm3fpXnKG5EUBx2ndxBDMPVciP5hGey2Jh4NDv6gmeo1LkMeiKrLJUUBk6Z"
}

pub fn scure_short_bytes_test() -> Nil {
  assert codec_test_support.encode(
      <<0x51, 0x6b, 0x6f, 0xcd, 0x0f>>,
      using: yabase.Base58Bitcoin,
    )
    == "ABnLTmg"
  assert yabase.decode("ABnLTmg", using: yabase.Base58Bitcoin)
    == Ok(<<0x51, 0x6b, 0x6f, 0xcd, 0x0f>>)
}

pub fn scure_leading_zeros_hello_test() -> Nil {
  assert codec_test_support.encode(
      <<0, 0, "hello world":utf8>>,
      using: yabase.Base58Bitcoin,
    )
    == "11StV1DL6CwTryKyV"
  assert yabase.decode("11StV1DL6CwTryKyV", using: yabase.Base58Bitcoin)
    == Ok(<<0, 0, "hello world":utf8>>)
}
