import yabase/ascii85
import yabase/core/encoding.{InvalidCharacter, InvalidLength, Overflow}

pub fn encode_empty_test() -> Nil {
  assert ascii85.encode(<<>>) == ""
}

pub fn encode_zeros_test() -> Nil {
  assert ascii85.encode(<<0, 0, 0, 0>>) == "z"
}

pub fn encode_man_test() -> Nil {
  assert ascii85.encode(<<"Man ":utf8>>) == "9jqo^"
}

pub fn decode_empty_test() -> Nil {
  assert ascii85.decode("") == Ok(<<>>)
}

pub fn decode_zeros_test() -> Nil {
  assert ascii85.decode("z") == Ok(<<0, 0, 0, 0>>)
}

pub fn encode_spaces_y_test() -> Nil {
  // btoa abbreviation: 4 spaces -> 'y'
  assert ascii85.encode(<<0x20, 0x20, 0x20, 0x20>>) == "y"
}

pub fn encode_eight_spaces_test() -> Nil {
  assert ascii85.encode(<<0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20>>)
    == "yy"
}

pub fn decode_y_test() -> Nil {
  assert ascii85.decode("y") == Ok(<<0x20, 0x20, 0x20, 0x20>>)
}

pub fn decode_yy_test() -> Nil {
  assert ascii85.decode("yy")
    == Ok(<<0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20>>)
}

pub fn roundtrip_spaces_test() -> Nil {
  let data = <<0x20, 0x20, 0x20, 0x20>>
  assert ascii85.decode(ascii85.encode(data)) == Ok(data)
}

pub fn encode_mixed_z_y_test() -> Nil {
  // zeros + spaces
  let data = <<0, 0, 0, 0, 0x20, 0x20, 0x20, 0x20>>
  assert ascii85.encode(data) == "zy"
}

pub fn decode_invalid_char_test() -> Nil {
  // Characters outside '!' (33) to 'u' (117) are invalid (except 'z')
  assert case ascii85.decode("\u{01}") {
    Error(InvalidCharacter(_, _)) -> True
    _ -> False
  }
}

// --- Decode edge cases ---

pub fn decode_single_char_invalid_length_test() -> Nil {
  // 1 char is too short to form a group (need at least 2)
  assert case ascii85.decode("!") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

pub fn decode_5_max_chars_overflow_test() -> Nil {
  // "uuuuu" -> 84*85^4 + 84*85^3 + 84*85^2 + 84*85 + 84 = 4294967295 (max u32, OK)
  // "s8W-!" is the encoding of <<0xff, 0xff, 0xff, 0xff>>
  let assert Ok(_) = ascii85.decode("s8W-!")
  Nil
}

pub fn decode_overflow_test() -> Nil {
  // Values that decode above u32 max must return Overflow
  // "s8W-\"" = one past max for full 5-char group
  assert ascii85.decode("s8W-\"") == Error(Overflow)
}

pub fn decode_2_char_group_test() -> Nil {
  // 2-char partial group -> 1 output byte
  let assert Ok(data) = ascii85.decode("!!")
  assert data == <<0>>
}

pub fn decode_3_char_group_test() -> Nil {
  // 3-char partial group -> 2 output bytes
  let assert Ok(data) = ascii85.decode("!!!")
  assert data == <<0, 0>>
}

pub fn decode_4_char_group_test() -> Nil {
  // 4-char partial group -> 3 output bytes
  let assert Ok(data) = ascii85.decode("!!!!")
  assert data == <<0, 0, 0>>
}

// --- Roundtrip corpus ---

pub fn roundtrip_aligned_test() -> Nil {
  let data = <<"Hello, World!!!!":utf8>>
  assert ascii85.decode(ascii85.encode(data)) == Ok(data)
}

pub fn roundtrip_short_test() -> Nil {
  let data = <<"Hi":utf8>>
  assert ascii85.decode(ascii85.encode(data)) == Ok(data)
}

pub fn roundtrip_empty_test() -> Nil {
  assert ascii85.decode(ascii85.encode(<<>>)) == Ok(<<>>)
}

pub fn roundtrip_single_byte_test() -> Nil {
  assert ascii85.decode(ascii85.encode(<<42>>)) == Ok(<<42>>)
}

pub fn roundtrip_all_zeros_test() -> Nil {
  let data = <<0, 0, 0, 0, 0, 0, 0, 0>>
  assert ascii85.decode(ascii85.encode(data)) == Ok(data)
}

pub fn roundtrip_high_bits_test() -> Nil {
  let data = <<0xff, 0xfe, 0xfd, 0xfc>>
  assert ascii85.decode(ascii85.encode(data)) == Ok(data)
}
