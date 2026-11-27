import codec_test_support
import yabase.{InvalidCharacter, InvalidLength, Overflow}

pub fn encode_empty_test() -> Nil {
  assert codec_test_support.encode(<<>>, using: yabase.Ascii85) == ""
}

pub fn encode_zeros_test() -> Nil {
  assert codec_test_support.encode(<<0, 0, 0, 0>>, using: yabase.Ascii85) == "z"
}

pub fn encode_man_test() -> Nil {
  assert codec_test_support.encode(<<"Man ":utf8>>, using: yabase.Ascii85)
    == "9jqo^"
}

pub fn decode_empty_test() -> Nil {
  assert yabase.decode("", using: yabase.Ascii85) == Ok(<<>>)
}

pub fn decode_zeros_test() -> Nil {
  assert yabase.decode("z", using: yabase.Ascii85) == Ok(<<0, 0, 0, 0>>)
}

pub fn encode_spaces_y_test() -> Nil {
  // btoa abbreviation: 4 spaces -> 'y'
  assert codec_test_support.encode(
      <<0x20, 0x20, 0x20, 0x20>>,
      using: yabase.Ascii85,
    )
    == "y"
}

pub fn encode_eight_spaces_test() -> Nil {
  assert codec_test_support.encode(
      <<0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20>>,
      using: yabase.Ascii85,
    )
    == "yy"
}

pub fn decode_y_test() -> Nil {
  assert yabase.decode("y", using: yabase.Ascii85)
    == Ok(<<0x20, 0x20, 0x20, 0x20>>)
}

pub fn decode_yy_test() -> Nil {
  assert yabase.decode("yy", using: yabase.Ascii85)
    == Ok(<<0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20>>)
}

pub fn roundtrip_spaces_test() -> Nil {
  let data = <<0x20, 0x20, 0x20, 0x20>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Ascii85),
      using: yabase.Ascii85,
    )
    == Ok(data)
}

pub fn encode_mixed_z_y_test() -> Nil {
  // zeros + spaces
  let data = <<0, 0, 0, 0, 0x20, 0x20, 0x20, 0x20>>
  assert codec_test_support.encode(data, using: yabase.Ascii85) == "zy"
}

pub fn decode_invalid_char_test() -> Nil {
  // Characters outside '!' (33) to 'u' (117) are invalid (except 'z')
  assert case yabase.decode("\u{01}", using: yabase.Ascii85) {
    Error(InvalidCharacter(_, _)) -> True
    _ -> False
  }
}

// --- Decode edge cases ---

pub fn decode_single_char_invalid_length_test() -> Nil {
  // 1 char is too short to form a group (need at least 2)
  assert case yabase.decode("!", using: yabase.Ascii85) {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

pub fn decode_5_max_chars_overflow_test() -> Nil {
  // "uuuuu" -> 84*85^4 + 84*85^3 + 84*85^2 + 84*85 + 84 = 4294967295 (max u32, OK)
  // "s8W-!" is the encoding of <<0xff, 0xff, 0xff, 0xff>>
  let assert Ok(_) = yabase.decode("s8W-!", using: yabase.Ascii85)
  Nil
}

pub fn decode_overflow_test() -> Nil {
  // Values that decode above u32 max must return Overflow
  // "s8W-\"" = one past max for full 5-char group
  assert yabase.decode("s8W-\"", using: yabase.Ascii85) == Error(Overflow)
}

pub fn decode_2_char_group_test() -> Nil {
  // 2-char partial group -> 1 output byte
  let assert Ok(data) = yabase.decode("!!", using: yabase.Ascii85)
  assert data == <<0>>
}

pub fn decode_3_char_group_test() -> Nil {
  // 3-char partial group -> 2 output bytes
  let assert Ok(data) = yabase.decode("!!!", using: yabase.Ascii85)
  assert data == <<0, 0>>
}

pub fn decode_4_char_group_test() -> Nil {
  // 4-char partial group -> 3 output bytes
  let assert Ok(data) = yabase.decode("!!!!", using: yabase.Ascii85)
  assert data == <<0, 0, 0>>
}

// --- Roundtrip corpus ---

pub fn roundtrip_aligned_test() -> Nil {
  let data = <<"Hello, World!!!!":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Ascii85),
      using: yabase.Ascii85,
    )
    == Ok(data)
}

pub fn roundtrip_short_test() -> Nil {
  let data = <<"Hi":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Ascii85),
      using: yabase.Ascii85,
    )
    == Ok(data)
}

pub fn roundtrip_empty_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<>>, using: yabase.Ascii85),
      using: yabase.Ascii85,
    )
    == Ok(<<>>)
}

pub fn roundtrip_single_byte_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<42>>, using: yabase.Ascii85),
      using: yabase.Ascii85,
    )
    == Ok(<<42>>)
}

pub fn roundtrip_all_zeros_test() -> Nil {
  let data = <<0, 0, 0, 0, 0, 0, 0, 0>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Ascii85),
      using: yabase.Ascii85,
    )
    == Ok(data)
}

pub fn roundtrip_high_bits_test() -> Nil {
  let data = <<0xff, 0xfe, 0xfd, 0xfc>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Ascii85),
      using: yabase.Ascii85,
    )
    == Ok(data)
}

// --- Whitespace tolerance (#59) ---
//
// Mirror `adobe_ascii85`'s posture: skip ASCII whitespace inside the
// payload so wrapped btoa output round-trips without a hand-rolled
// `string.replace` shim on the caller side.

pub fn decode_skips_space_test() -> Nil {
  // 'y' is the four-spaces shortcut. Surrounding whitespace must be
  // ignored.
  assert yabase.decode(" y ", using: yabase.Ascii85)
    == Ok(<<0x20, 0x20, 0x20, 0x20>>)
}

pub fn decode_skips_newline_test() -> Nil {
  assert yabase.decode("9jqo^\n", using: yabase.Ascii85) == Ok(<<"Man ":utf8>>)
}

pub fn decode_skips_carriage_return_test() -> Nil {
  assert yabase.decode("9jqo^\r\n", using: yabase.Ascii85)
    == Ok(<<"Man ":utf8>>)
}

pub fn decode_skips_tab_test() -> Nil {
  assert yabase.decode("\t9jqo^\t", using: yabase.Ascii85)
    == Ok(<<"Man ":utf8>>)
}

pub fn decode_skips_whitespace_inside_group_test() -> Nil {
  // Whitespace must also be skipped between characters of a single
  // 5-char group.
  assert yabase.decode("9j\nqo^", using: yabase.Ascii85) == Ok(<<"Man ":utf8>>)
}

pub fn decode_reports_the_position_after_whitespace_inside_a_group_test() -> Nil {
  // "87cU RD]v": the space is index 4, so the invalid "v" is index 8.
  assert yabase.decode("87cU RD]v,\"Ebo80", using: yabase.Ascii85)
    == Error(InvalidCharacter("v", 8))
  assert yabase.decode("87cURD ]i,\"Eb\u{7F}o80", using: yabase.Ascii85)
    == Error(InvalidCharacter("\u{7F}", 13))
  assert yabase.decode("87\ncU\nRD]v", using: yabase.Ascii85)
    == Error(InvalidCharacter("v", 9))
}

pub fn decode_reports_the_position_of_a_lone_final_char_after_whitespace_test() -> Nil {
  // "87cU R" is one group (5 chars + 1 space); the lone final "D" ends
  // the input at index 7, so the reported length is 7 as for "87cURD".
  assert yabase.decode("87cURD", using: yabase.Ascii85)
    == Error(InvalidLength(6))
  assert yabase.decode("87cU RD", using: yabase.Ascii85)
    == Error(InvalidLength(7))
}

// The length reported for a lone final character counts a CR LF, a "z"
// and a "y" as one character each.
pub fn decode_counts_shortcuts_and_crlf_before_a_lone_final_char_test() -> Nil {
  assert yabase.decode("\r\n!", using: yabase.Ascii85)
    == Error(InvalidLength(2))
  assert yabase.decode("z!", using: yabase.Ascii85) == Error(InvalidLength(2))
  assert yabase.decode("y!", using: yabase.Ascii85) == Error(InvalidLength(2))
}
