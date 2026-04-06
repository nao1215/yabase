import yabase/ascii85
import yabase/core/encoding.{InvalidCharacter}

pub fn encode_empty_test() {
  assert ascii85.encode(<<>>) == ""
}

pub fn encode_zeros_test() {
  assert ascii85.encode(<<0, 0, 0, 0>>) == "z"
}

pub fn encode_man_test() {
  assert ascii85.encode(<<"Man ":utf8>>) == "9jqo^"
}

pub fn decode_empty_test() {
  assert ascii85.decode("") == Ok(<<>>)
}

pub fn decode_zeros_test() {
  assert ascii85.decode("z") == Ok(<<0, 0, 0, 0>>)
}

pub fn decode_invalid_char_test() {
  // Characters outside '!' (33) to 'u' (117) are invalid (except 'z')
  assert case ascii85.decode("\u{01}") {
    Error(InvalidCharacter(_, _)) -> True
    _ -> False
  }
}

// --- Roundtrip corpus ---

pub fn roundtrip_aligned_test() {
  let data = <<"Hello, World!!!!":utf8>>
  assert ascii85.decode(ascii85.encode(data)) == Ok(data)
}

pub fn roundtrip_short_test() {
  let data = <<"Hi":utf8>>
  assert ascii85.decode(ascii85.encode(data)) == Ok(data)
}

pub fn roundtrip_empty_test() {
  assert ascii85.decode(ascii85.encode(<<>>)) == Ok(<<>>)
}

pub fn roundtrip_single_byte_test() {
  assert ascii85.decode(ascii85.encode(<<42>>)) == Ok(<<42>>)
}

pub fn roundtrip_all_zeros_test() {
  let data = <<0, 0, 0, 0, 0, 0, 0, 0>>
  assert ascii85.decode(ascii85.encode(data)) == Ok(data)
}

pub fn roundtrip_high_bits_test() {
  let data = <<0xff, 0xfe, 0xfd, 0xfc>>
  assert ascii85.decode(ascii85.encode(data)) == Ok(data)
}
