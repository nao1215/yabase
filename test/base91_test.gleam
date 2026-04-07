import yabase/base91
import yabase/core/encoding.{InvalidCharacter}

pub fn encode_empty_test() {
  assert base91.encode(<<>>) == ""
}

pub fn decode_empty_test() {
  assert base91.decode("") == Ok(<<>>)
}

// --- Fixed vectors (cross-checked with reference implementation) ---

pub fn encode_test_test() {
  assert base91.encode(<<"test":utf8>>) == "fPNKd"
}

pub fn decode_test_test() {
  assert base91.decode("fPNKd") == Ok(<<"test":utf8>>)
}

pub fn encode_hello_world_test() {
  assert base91.encode(<<"Hello World":utf8>>) == ">OwJh>Io0Tv!lE"
}

pub fn decode_hello_world_test() {
  assert base91.decode(">OwJh>Io0Tv!lE") == Ok(<<"Hello World":utf8>>)
}

// --- Roundtrip corpus ---

pub fn roundtrip_hello_test() {
  let data = <<"Hello World":utf8>>
  assert base91.decode(base91.encode(data)) == Ok(data)
}

pub fn roundtrip_binary_test() {
  let data = <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10>>
  assert base91.decode(base91.encode(data)) == Ok(data)
}

pub fn roundtrip_empty_test() {
  assert base91.decode(base91.encode(<<>>)) == Ok(<<>>)
}

pub fn roundtrip_single_zero_test() {
  assert base91.decode(base91.encode(<<0>>)) == Ok(<<0>>)
}

pub fn roundtrip_high_bits_test() {
  let data = <<0xff, 0xfe, 0xfd, 0xfc>>
  assert base91.decode(base91.encode(data)) == Ok(data)
}

pub fn roundtrip_varied_bytes_test() {
  let data = <<1, 2, 3, 4, 5, 6, 7, 8>>
  assert base91.decode(base91.encode(data)) == Ok(data)
}

pub fn roundtrip_single_byte_test() {
  assert base91.decode(base91.encode(<<42>>)) == Ok(<<42>>)
}

pub fn roundtrip_255_test() {
  assert base91.decode(base91.encode(<<255>>)) == Ok(<<255>>)
}

// --- Longer input roundtrip ---

pub fn roundtrip_16_bytes_test() {
  let data = <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15>>
  assert base91.decode(base91.encode(data)) == Ok(data)
}

pub fn roundtrip_32_bytes_test() {
  let data = <<
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
    22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
  >>
  assert base91.decode(base91.encode(data)) == Ok(data)
}

// --- Error cases ---

pub fn decode_invalid_char_space_test() {
  assert case base91.decode(" ") {
    Error(InvalidCharacter(" ", 0)) -> True
    _ -> False
  }
}

pub fn decode_invalid_char_dash_test() {
  assert case base91.decode("-") {
    Error(InvalidCharacter("-", 0)) -> True
    _ -> False
  }
}

pub fn decode_invalid_char_embedded_test() {
  // Valid chars around an invalid one
  assert case base91.decode("fP KNd") {
    Error(InvalidCharacter(" ", _)) -> True
    _ -> False
  }
}
