import yabase/base91

pub fn encode_empty_test() {
  assert base91.encode(<<>>) == ""
}

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
