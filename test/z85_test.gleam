import yabase.{InvalidLength, Overflow}

pub fn encode_empty_test() -> Nil {
  assert yabase.encode(<<>>, using: yabase.Z85) == Ok("")
}

pub fn encode_known_value_test() -> Nil {
  // 4 bytes -> 5 Z85 characters
  assert yabase.encode(<<0x86, 0x4F, 0xD2, 0x6F>>, using: yabase.Z85)
    == Ok("Hello")
}

pub fn encode_non_4byte_error_test() -> Nil {
  // 3 bytes is not a multiple of 4
  assert yabase.encode(<<1, 2, 3>>, using: yabase.Z85)
    == Error(InvalidLength(3))
}

pub fn encode_5byte_error_test() -> Nil {
  assert yabase.encode(<<1, 2, 3, 4, 5>>, using: yabase.Z85)
    == Error(InvalidLength(5))
}

pub fn decode_invalid_length_test() -> Nil {
  // 3 chars is not a multiple of 5
  assert yabase.decode("abc", using: yabase.Z85) == Error(InvalidLength(3))
}

pub fn decode_empty_test() -> Nil {
  assert yabase.decode("", using: yabase.Z85) == Ok(<<>>)
}

// --- Overflow (85^5 > 2^32) ---

pub fn decode_overflow_max_z85_group_test() -> Nil {
  // "#####" = all index 84 -> 84*85^4 + 84*85^3 + 84*85^2 + 84*85 + 84
  // = 84 * (85^4 + 85^3 + 85^2 + 85 + 1) = 84 * 52_200_625 + ... > 2^32
  assert yabase.decode("#####", using: yabase.Z85) == Error(Overflow)
}

pub fn decode_overflow_boundary_test() -> Nil {
  // The maximum valid Z85 value is %nSc0 = 0xFFFFFFFF = 4,294,967,295
  // %nSc1 (last char incremented) would be 4,294,967,296 = overflow
  // Instead test with a clearly overflowing group
  assert yabase.decode("$$$$$", using: yabase.Z85) == Error(Overflow)
}

// --- Roundtrip ---

pub fn roundtrip_4bytes_test() -> Nil {
  let data = <<0x86, 0x4F, 0xD2, 0x6F>>
  let assert Ok(encoded) = yabase.encode(data, using: yabase.Z85)
  assert yabase.decode(encoded, using: yabase.Z85) == Ok(data)
}

pub fn roundtrip_8bytes_test() -> Nil {
  let data = <<0x86, 0x4F, 0xD2, 0x6F, 0xB5, 0x59, 0xF7, 0x5B>>
  let assert Ok(encoded) = yabase.encode(data, using: yabase.Z85)
  assert yabase.decode(encoded, using: yabase.Z85) == Ok(data)
}

pub fn roundtrip_all_zeros_test() -> Nil {
  let data = <<0, 0, 0, 0>>
  let assert Ok(encoded) = yabase.encode(data, using: yabase.Z85)
  assert yabase.decode(encoded, using: yabase.Z85) == Ok(data)
}

pub fn roundtrip_high_bits_test() -> Nil {
  let data = <<0xff, 0xff, 0xff, 0xff>>
  let assert Ok(encoded) = yabase.encode(data, using: yabase.Z85)
  assert yabase.decode(encoded, using: yabase.Z85) == Ok(data)
}
