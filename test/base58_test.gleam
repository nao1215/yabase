import yabase/base58/bitcoin
import yabase/base58/flickr
import yabase/core/error.{InvalidCharacter}

// === Bitcoin alphabet ===

pub fn bitcoin_encode_empty_test() -> Nil {
  assert bitcoin.encode(<<>>) == ""
}

pub fn bitcoin_encode_hello_test() -> Nil {
  assert bitcoin.encode(<<"Hello World":utf8>>) == "JxF12TrwUP45BMd"
}

pub fn bitcoin_encode_leading_zeros_test() -> Nil {
  assert bitcoin.encode(<<0, 0, 1>>) == "112"
}

pub fn bitcoin_decode_empty_test() -> Nil {
  assert bitcoin.decode("") == Ok(<<>>)
}

pub fn bitcoin_decode_hello_test() -> Nil {
  assert bitcoin.decode("JxF12TrwUP45BMd") == Ok(<<"Hello World":utf8>>)
}

pub fn bitcoin_decode_leading_ones_test() -> Nil {
  assert bitcoin.decode("112") == Ok(<<0, 0, 1>>)
}

pub fn bitcoin_decode_invalid_char_zero_test() -> Nil {
  assert bitcoin.decode("0") == Error(InvalidCharacter("0", 0))
}

pub fn bitcoin_decode_invalid_char_upper_o_test() -> Nil {
  assert bitcoin.decode("O") == Error(InvalidCharacter("O", 0))
}

pub fn bitcoin_decode_invalid_char_upper_i_test() -> Nil {
  assert bitcoin.decode("I") == Error(InvalidCharacter("I", 0))
}

pub fn bitcoin_decode_invalid_char_l_test() -> Nil {
  assert bitcoin.decode("l") == Error(InvalidCharacter("l", 0))
}

pub fn bitcoin_roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert bitcoin.decode(bitcoin.encode(data)) == Ok(data)
}

pub fn bitcoin_roundtrip_empty_test() -> Nil {
  assert bitcoin.decode(bitcoin.encode(<<>>)) == Ok(<<>>)
}

pub fn bitcoin_roundtrip_single_zero_test() -> Nil {
  assert bitcoin.decode(bitcoin.encode(<<0>>)) == Ok(<<0>>)
}

pub fn bitcoin_roundtrip_leading_zeros_test() -> Nil {
  let data = <<0, 0, 0, 42>>
  assert bitcoin.decode(bitcoin.encode(data)) == Ok(data)
}

pub fn bitcoin_roundtrip_high_bits_test() -> Nil {
  let data = <<0xff, 0xfe, 0xfd>>
  assert bitcoin.decode(bitcoin.encode(data)) == Ok(data)
}

// === Flickr alphabet ===

pub fn flickr_encode_empty_test() -> Nil {
  assert flickr.encode(<<>>) == ""
}

pub fn flickr_encode_hello_test() -> Nil {
  let encoded = flickr.encode(<<"Hello World":utf8>>)
  // Flickr swaps upper/lowercase relative to Bitcoin
  assert encoded == "iXf12sRWto45bmC"
}

pub fn flickr_decode_hello_test() -> Nil {
  assert flickr.decode("iXf12sRWto45bmC") == Ok(<<"Hello World":utf8>>)
}

pub fn flickr_decode_invalid_char_zero_test() -> Nil {
  assert flickr.decode("0") == Error(InvalidCharacter("0", 0))
}

pub fn flickr_roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert flickr.decode(flickr.encode(data)) == Ok(data)
}

pub fn flickr_roundtrip_empty_test() -> Nil {
  assert flickr.decode(flickr.encode(<<>>)) == Ok(<<>>)
}

pub fn flickr_roundtrip_single_zero_test() -> Nil {
  assert flickr.decode(flickr.encode(<<0>>)) == Ok(<<0>>)
}

pub fn flickr_roundtrip_leading_zeros_test() -> Nil {
  let data = <<0, 0, 0, 42>>
  assert flickr.decode(flickr.encode(data)) == Ok(data)
}

pub fn flickr_roundtrip_high_bits_test() -> Nil {
  let data = <<0xff, 0xfe, 0xfd>>
  assert flickr.decode(flickr.encode(data)) == Ok(data)
}

// === Cross-alphabet: same data, different output ===

pub fn bitcoin_flickr_different_output_test() -> Nil {
  let data = <<"test":utf8>>
  assert bitcoin.encode(data) != flickr.encode(data)
}

pub fn bitcoin_flickr_same_data_test() -> Nil {
  let data = <<"test":utf8>>
  let assert Ok(d1) = bitcoin.decode(bitcoin.encode(data))
  let assert Ok(d2) = flickr.decode(flickr.encode(data))
  assert d1 == d2
}

// === Cross-reference vectors (paulmillr/scure-base) ===

pub fn scure_hello_world_test() -> Nil {
  assert bitcoin.encode(<<"hello world":utf8>>) == "StV1DL6CwTryKyV"
  assert bitcoin.decode("StV1DL6CwTryKyV") == Ok(<<"hello world":utf8>>)
}

pub fn scure_hello_world_excl_test() -> Nil {
  assert bitcoin.encode(<<"Hello World!":utf8>>) == "2NEpo7TZRRrLZSi2U"
  assert bitcoin.decode("2NEpo7TZRRrLZSi2U") == Ok(<<"Hello World!":utf8>>)
}

pub fn scure_leading_zeros_test() -> Nil {
  assert bitcoin.encode(<<0, 0, 0x28, 0x7f, 0xb4, 0xcd>>) == "11233QC4"
  assert bitcoin.decode("11233QC4") == Ok(<<0, 0, 0x28, 0x7f, 0xb4, 0xcd>>)
}

pub fn scure_quick_brown_fox_test() -> Nil {
  let data = <<"The quick brown fox jumps over the lazy dog.":utf8>>
  assert bitcoin.encode(data)
    == "USm3fpXnKG5EUBx2ndxBDMPVciP5hGey2Jh4NDv6gmeo1LkMeiKrLJUUBk6Z"
}

pub fn scure_short_bytes_test() -> Nil {
  assert bitcoin.encode(<<0x51, 0x6b, 0x6f, 0xcd, 0x0f>>) == "ABnLTmg"
  assert bitcoin.decode("ABnLTmg") == Ok(<<0x51, 0x6b, 0x6f, 0xcd, 0x0f>>)
}

pub fn scure_leading_zeros_hello_test() -> Nil {
  assert bitcoin.encode(<<0, 0, "hello world":utf8>>) == "11StV1DL6CwTryKyV"
  assert bitcoin.decode("11StV1DL6CwTryKyV") == Ok(<<0, 0, "hello world":utf8>>)
}
