import codec_test_support
import yabase.{InvalidCharacter, InvalidLength, Overflow}

pub fn encode_empty_test() -> Nil {
  assert codec_test_support.encode(<<>>, using: yabase.AdobeAscii85) == "<~~>"
}

pub fn encode_man_test() -> Nil {
  assert codec_test_support.encode(<<"Man ":utf8>>, using: yabase.AdobeAscii85)
    == "<~9jqo^~>"
}

pub fn encode_zeros_test() -> Nil {
  assert codec_test_support.encode(<<0, 0, 0, 0>>, using: yabase.AdobeAscii85)
    == "<~z~>"
}

pub fn decode_empty_test() -> Nil {
  assert yabase.decode("<~~>", using: yabase.AdobeAscii85) == Ok(<<>>)
}

pub fn decode_man_test() -> Nil {
  assert yabase.decode("<~9jqo^~>", using: yabase.AdobeAscii85)
    == Ok(<<"Man ":utf8>>)
}

pub fn decode_zeros_test() -> Nil {
  assert yabase.decode("<~z~>", using: yabase.AdobeAscii85)
    == Ok(<<0, 0, 0, 0>>)
}

// --- Whitespace handling (Adobe spec: whitespace ignored inside) ---

pub fn decode_with_internal_whitespace_test() -> Nil {
  // "9jqo^" with spaces and newlines inserted
  assert yabase.decode("<~9j qo\n^~>", using: yabase.AdobeAscii85)
    == Ok(<<"Man ":utf8>>)
}

pub fn decode_with_tabs_test() -> Nil {
  assert yabase.decode("<~9j\tqo^~>", using: yabase.AdobeAscii85)
    == Ok(<<"Man ":utf8>>)
}

pub fn decode_with_form_feed_test() -> Nil {
  assert yabase.decode("<~9j\u{000C}qo^~>", using: yabase.AdobeAscii85)
    == Ok(<<"Man ":utf8>>)
}

pub fn decode_with_form_feed_between_groups_test() -> Nil {
  assert yabase.decode("<~z\u{000C}z~>", using: yabase.AdobeAscii85)
    == Ok(<<0, 0, 0, 0, 0, 0, 0, 0>>)
}

// --- Missing delimiters ---

pub fn decode_missing_prefix_test() -> Nil {
  assert case yabase.decode("9jqo^~>", using: yabase.AdobeAscii85) {
    Error(yabase.MissingDelimiter(_, _)) -> True
    _ -> False
  }
}

pub fn decode_missing_suffix_test() -> Nil {
  assert case yabase.decode("<~9jqo^", using: yabase.AdobeAscii85) {
    Error(yabase.MissingDelimiter(_, _)) -> True
    _ -> False
  }
}

// --- 1-char final group (must be rejected) ---

pub fn decode_1char_final_group_test() -> Nil {
  // "!" is a single char after "z" -> incomplete final group
  assert case yabase.decode("<~z!~>", using: yabase.AdobeAscii85) {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

// --- Overflow: impossible combinations ---

pub fn decode_overflow_full_group_test() -> Nil {
  // "uuuuu" = all index 84 -> 84*85^4+... > 2^32
  assert case yabase.decode("<~uuuuu~>", using: yabase.AdobeAscii85) {
    Error(Overflow) -> True
    _ -> False
  }
}

pub fn decode_overflow_partial_group_test() -> Nil {
  // "uuuu" = 4 chars, padded to [84,84,84,84,84] -> same overflow
  assert case yabase.decode("<~uuuu~>", using: yabase.AdobeAscii85) {
    Error(Overflow) -> True
    _ -> False
  }
}

pub fn decode_overflow_partial_3char_test() -> Nil {
  // "uuu" = 3 chars, padded to [84,84,84,84,84] -> overflow
  assert case yabase.decode("<~uuu~>", using: yabase.AdobeAscii85) {
    Error(Overflow) -> True
    _ -> False
  }
}

// --- Roundtrips ---

pub fn roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.AdobeAscii85),
      using: yabase.AdobeAscii85,
    )
    == Ok(data)
}

pub fn roundtrip_short_test() -> Nil {
  let data = <<"Hi":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.AdobeAscii85),
      using: yabase.AdobeAscii85,
    )
    == Ok(data)
}

pub fn roundtrip_aligned_test() -> Nil {
  let data = <<"test1234":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.AdobeAscii85),
      using: yabase.AdobeAscii85,
    )
    == Ok(data)
}

pub fn decode_reports_the_position_after_whitespace_inside_a_group_test() -> Nil {
  // Positions count the "<~" prefix: the invalid "v" is index 10.
  assert yabase.decode("<~87cU RD]v,\"Ebo80~>", using: yabase.AdobeAscii85)
    == Error(InvalidCharacter("v", 10))
  assert yabase.decode(
      "<~87cURD ]i,\"Eb\u{7F}o80~>",
      using: yabase.AdobeAscii85,
    )
    == Error(InvalidCharacter("\u{7F}", 15))
}

pub fn decode_skips_crlf_like_btoa_test() -> Nil {
  // CR LF used to arrive as one "\r\n" grapheme that the Adobe decoder did
  // not list as whitespace, so wrapped PDF streams were rejected.
  assert yabase.decode("<~9jqo^\r\nBl~>", using: yabase.AdobeAscii85)
    == Ok(<<"Man i":utf8>>)
}
