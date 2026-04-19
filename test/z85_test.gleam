import yabase/core/encoding.{InvalidLength, Overflow}
import yabase/z85

pub fn encode_empty_test() -> Nil {
  assert z85.encode(<<>>) == Ok("")
}

pub fn encode_known_value_test() -> Nil {
  // 4 bytes -> 5 Z85 characters
  assert z85.encode(<<0x86, 0x4F, 0xD2, 0x6F>>) == Ok("Hello")
}

pub fn encode_non_4byte_error_test() -> Nil {
  // 3 bytes is not a multiple of 4
  assert z85.encode(<<1, 2, 3>>) == Error(InvalidLength(3))
}

pub fn encode_5byte_error_test() -> Nil {
  assert z85.encode(<<1, 2, 3, 4, 5>>) == Error(InvalidLength(5))
}

pub fn decode_invalid_length_test() -> Nil {
  // 3 chars is not a multiple of 5
  assert z85.decode("abc") == Error(InvalidLength(3))
}

pub fn decode_empty_test() -> Nil {
  assert z85.decode("") == Ok(<<>>)
}

// --- Overflow (85^5 > 2^32) ---

pub fn decode_overflow_max_z85_group_test() -> Nil {
  // "#####" = all index 84 -> 84*85^4 + 84*85^3 + 84*85^2 + 84*85 + 84
  // = 84 * (85^4 + 85^3 + 85^2 + 85 + 1) = 84 * 52_200_625 + ... > 2^32
  assert z85.decode("#####") == Error(Overflow)
}

pub fn decode_overflow_boundary_test() -> Nil {
  // The maximum valid Z85 value is %nSc0 = 0xFFFFFFFF = 4,294,967,295
  // %nSc1 (last char incremented) would be 4,294,967,296 = overflow
  // Instead test with a clearly overflowing group
  assert z85.decode("$$$$$") == Error(Overflow)
}

// --- Roundtrip ---

pub fn roundtrip_4bytes_test() -> Nil {
  let data = <<0x86, 0x4F, 0xD2, 0x6F>>
  let assert Ok(encoded) = z85.encode(data)
  assert z85.decode(encoded) == Ok(data)
}

pub fn roundtrip_8bytes_test() -> Nil {
  let data = <<0x86, 0x4F, 0xD2, 0x6F, 0xB5, 0x59, 0xF7, 0x5B>>
  let assert Ok(encoded) = z85.encode(data)
  assert z85.decode(encoded) == Ok(data)
}

pub fn roundtrip_all_zeros_test() -> Nil {
  let data = <<0, 0, 0, 0>>
  let assert Ok(encoded) = z85.encode(data)
  assert z85.decode(encoded) == Ok(data)
}

pub fn roundtrip_high_bits_test() -> Nil {
  let data = <<0xff, 0xff, 0xff, 0xff>>
  let assert Ok(encoded) = z85.encode(data)
  assert z85.decode(encoded) == Ok(data)
}
