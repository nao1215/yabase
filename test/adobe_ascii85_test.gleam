import yabase/adobe_ascii85
import yabase/core/encoding.{InvalidCharacter, InvalidLength, Overflow}

pub fn encode_empty_test() -> Nil {
  assert adobe_ascii85.encode(<<>>) == "<~~>"
}

pub fn encode_man_test() -> Nil {
  assert adobe_ascii85.encode(<<"Man ":utf8>>) == "<~9jqo^~>"
}

pub fn encode_zeros_test() -> Nil {
  assert adobe_ascii85.encode(<<0, 0, 0, 0>>) == "<~z~>"
}

pub fn decode_empty_test() -> Nil {
  assert adobe_ascii85.decode("<~~>") == Ok(<<>>)
}

pub fn decode_man_test() -> Nil {
  assert adobe_ascii85.decode("<~9jqo^~>") == Ok(<<"Man ":utf8>>)
}

pub fn decode_zeros_test() -> Nil {
  assert adobe_ascii85.decode("<~z~>") == Ok(<<0, 0, 0, 0>>)
}

// --- Whitespace handling (Adobe spec: whitespace ignored inside) ---

pub fn decode_with_internal_whitespace_test() -> Nil {
  // "9jqo^" with spaces and newlines inserted
  assert adobe_ascii85.decode("<~9j qo\n^~>") == Ok(<<"Man ":utf8>>)
}

pub fn decode_with_tabs_test() -> Nil {
  assert adobe_ascii85.decode("<~9j\tqo^~>") == Ok(<<"Man ":utf8>>)
}

pub fn decode_with_form_feed_test() -> Nil {
  assert adobe_ascii85.decode("<~9j\u{000C}qo^~>") == Ok(<<"Man ":utf8>>)
}

pub fn decode_with_form_feed_between_groups_test() -> Nil {
  assert adobe_ascii85.decode("<~z\u{000C}z~>")
    == Ok(<<0, 0, 0, 0, 0, 0, 0, 0>>)
}

// --- Missing delimiters ---

pub fn decode_missing_prefix_test() -> Nil {
  assert case adobe_ascii85.decode("9jqo^~>") {
    Error(InvalidCharacter(_, _)) -> True
    _ -> False
  }
}

pub fn decode_missing_suffix_test() -> Nil {
  assert case adobe_ascii85.decode("<~9jqo^") {
    Error(InvalidCharacter(_, _)) -> True
    _ -> False
  }
}

// --- 1-char final group (must be rejected) ---

pub fn decode_1char_final_group_test() -> Nil {
  // "!" is a single char after "z" -> incomplete final group
  assert case adobe_ascii85.decode("<~z!~>") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

// --- Overflow: impossible combinations ---

pub fn decode_overflow_full_group_test() -> Nil {
  // "uuuuu" = all index 84 -> 84*85^4+... > 2^32
  assert case adobe_ascii85.decode("<~uuuuu~>") {
    Error(Overflow) -> True
    _ -> False
  }
}

pub fn decode_overflow_partial_group_test() -> Nil {
  // "uuuu" = 4 chars, padded to [84,84,84,84,84] -> same overflow
  assert case adobe_ascii85.decode("<~uuuu~>") {
    Error(Overflow) -> True
    _ -> False
  }
}

pub fn decode_overflow_partial_3char_test() -> Nil {
  // "uuu" = 3 chars, padded to [84,84,84,84,84] -> overflow
  assert case adobe_ascii85.decode("<~uuu~>") {
    Error(Overflow) -> True
    _ -> False
  }
}

// --- Roundtrips ---

pub fn roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert adobe_ascii85.decode(adobe_ascii85.encode(data)) == Ok(data)
}

pub fn roundtrip_short_test() -> Nil {
  let data = <<"Hi":utf8>>
  assert adobe_ascii85.decode(adobe_ascii85.encode(data)) == Ok(data)
}

pub fn roundtrip_aligned_test() -> Nil {
  let data = <<"test1234":utf8>>
  assert adobe_ascii85.decode(adobe_ascii85.encode(data)) == Ok(data)
}
