import codec_test_support
import yabase.{InvalidCharacter}

pub fn encode_empty_test() -> Nil {
  assert codec_test_support.encode(<<>>, using: yabase.Base91) == ""
}

pub fn decode_empty_test() -> Nil {
  assert yabase.decode("", using: yabase.Base91) == Ok(<<>>)
}

// --- Fixed vectors (cross-checked with reference implementation) ---

pub fn encode_test_test() -> Nil {
  assert codec_test_support.encode(<<"test":utf8>>, using: yabase.Base91)
    == "fPNKd"
}

pub fn decode_test_test() -> Nil {
  assert yabase.decode("fPNKd", using: yabase.Base91) == Ok(<<"test":utf8>>)
}

pub fn encode_hello_world_test() -> Nil {
  assert codec_test_support.encode(<<"Hello World":utf8>>, using: yabase.Base91)
    == ">OwJh>Io0Tv!lE"
}

pub fn decode_hello_world_test() -> Nil {
  assert yabase.decode(">OwJh>Io0Tv!lE", using: yabase.Base91)
    == Ok(<<"Hello World":utf8>>)
}

// --- Roundtrip corpus ---

pub fn roundtrip_hello_test() -> Nil {
  let data = <<"Hello World":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base91),
      using: yabase.Base91,
    )
    == Ok(data)
}

pub fn roundtrip_binary_test() -> Nil {
  let data = <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base91),
      using: yabase.Base91,
    )
    == Ok(data)
}

pub fn roundtrip_empty_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<>>, using: yabase.Base91),
      using: yabase.Base91,
    )
    == Ok(<<>>)
}

pub fn roundtrip_single_zero_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<0>>, using: yabase.Base91),
      using: yabase.Base91,
    )
    == Ok(<<0>>)
}

pub fn roundtrip_high_bits_test() -> Nil {
  let data = <<0xff, 0xfe, 0xfd, 0xfc>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base91),
      using: yabase.Base91,
    )
    == Ok(data)
}

pub fn roundtrip_varied_bytes_test() -> Nil {
  let data = <<1, 2, 3, 4, 5, 6, 7, 8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base91),
      using: yabase.Base91,
    )
    == Ok(data)
}

pub fn roundtrip_single_byte_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<42>>, using: yabase.Base91),
      using: yabase.Base91,
    )
    == Ok(<<42>>)
}

pub fn roundtrip_255_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<255>>, using: yabase.Base91),
      using: yabase.Base91,
    )
    == Ok(<<255>>)
}

// --- Longer input roundtrip ---

pub fn roundtrip_16_bytes_test() -> Nil {
  let data = <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base91),
      using: yabase.Base91,
    )
    == Ok(data)
}

pub fn roundtrip_32_bytes_test() -> Nil {
  let data = <<
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
    22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
  >>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base91),
      using: yabase.Base91,
    )
    == Ok(data)
}

pub fn roundtrip_48_bytes_test() -> Nil {
  let data = <<
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
    22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47,
  >>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base91),
      using: yabase.Base91,
    )
    == Ok(data)
}

pub fn roundtrip_64_bytes_test() -> Nil {
  let data = <<
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
    22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
    60, 61, 62, 63,
  >>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base91),
      using: yabase.Base91,
    )
    == Ok(data)
}

pub fn roundtrip_all_ff_32_test() -> Nil {
  let data = <<
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255,
  >>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base91),
      using: yabase.Base91,
    )
    == Ok(data)
}

// --- Error cases ---

pub fn decode_only_space_is_empty_test() -> Nil {
  // basE91 reference treats whitespace as ignorable. A whitespace-
  // only input therefore decodes to the empty bit array, not an
  // InvalidCharacter error. (#60)
  assert yabase.decode(" ", using: yabase.Base91) == Ok(<<>>)
}

pub fn decode_invalid_char_dash_test() -> Nil {
  assert case yabase.decode("-", using: yabase.Base91) {
    Error(InvalidCharacter("-", 0)) -> True
    _ -> False
  }
}

pub fn decode_invalid_char_embedded_test() -> Nil {
  // Valid chars around an invalid (non-alphabet, non-whitespace) one
  assert case yabase.decode("fP\u{0007}KNd", using: yabase.Base91) {
    Error(InvalidCharacter(_, _)) -> True
    _ -> False
  }
}

// --- Whitespace tolerance (#60) ---

pub fn decode_skips_space_test() -> Nil {
  // basE91 reference: "the decoder simply ignores characters not in
  // the alphabet". The reference encoder also wraps long output at
  // 76 chars, so wrapped text must round-trip.
  assert yabase.decode("fP NKd", using: yabase.Base91) == Ok(<<"test":utf8>>)
}

pub fn decode_skips_newline_test() -> Nil {
  assert yabase.decode("fPNKd\n", using: yabase.Base91) == Ok(<<"test":utf8>>)
}

pub fn decode_skips_carriage_return_test() -> Nil {
  assert yabase.decode("fPNKd\r\n", using: yabase.Base91) == Ok(<<"test":utf8>>)
}

pub fn decode_skips_tab_test() -> Nil {
  assert yabase.decode("\tfPNKd\t", using: yabase.Base91) == Ok(<<"test":utf8>>)
}

pub fn decode_skips_mixed_whitespace_test() -> Nil {
  // Hello World encoding ">OwJh>Io0Tv!lE" with whitespace injected
  // throughout (simulates wrapped + tab-indented transport).
  assert yabase.decode(">OwJh\n>Io0\tTv!lE\r\n", using: yabase.Base91)
    == Ok(<<"Hello World":utf8>>)
}

// Inputs where 13 bits are queued exactly when a byte arrives, where 7
// bits are left at the end, and where the last value is exactly 90.
// Expected values from the basE91 reference algorithm.
pub fn encode_queue_boundaries_match_the_reference_test() -> Nil {
  assert codec_test_support.encode(
      <<82, 224, 170, 102, 0, 243>>,
      using: yabase.Base91,
    )
    == "_\"C;O\"eB"
  assert codec_test_support.encode(
      <<58, 96, 6, 128, 215, 31>>,
      using: yabase.Base91,
    )
    == "8\"ZA]]P"
  assert codec_test_support.encode(
      <<115, 74, 180, 211, 239, 150, 64, 240, 181>>,
      using: yabase.Base91,
    )
    == "kdh^6>cDX|\""
}
