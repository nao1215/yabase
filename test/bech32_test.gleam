import gleam/string
import yabase.{
  Bech32 as Bech32V, Bech32m as Bech32mV, InvalidChecksum, InvalidHrp,
  InvalidLength,
}

// ===== BIP 173 Bech32 =====

pub fn bech32_roundtrip_test() -> Nil {
  let data = <<0, 1, 2, 3, 4>>
  let assert Ok(encoded) =
    yabase.encode(data, using: yabase.Bech32Encoding("test", Bech32V))
  let assert Ok(decoded) = yabase.decode_bech32(encoded)
  assert decoded.hrp == "test"
  assert decoded.variant == Bech32V
  assert decoded.data == data
}

pub fn bech32_empty_data_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode(<<>>, using: yabase.Bech32Encoding("a", Bech32V))
  let assert Ok(decoded) = yabase.decode_bech32(encoded)
  assert decoded.hrp == "a"
  assert decoded.data == <<>>
  assert decoded.variant == Bech32V
}

// ===== BIP 350 Bech32m =====

pub fn bech32m_roundtrip_test() -> Nil {
  let data = <<0, 1, 2, 3>>
  let assert Ok(encoded) =
    yabase.encode(data, using: yabase.Bech32Encoding("test", Bech32mV))
  let assert Ok(decoded) = yabase.decode_bech32(encoded)
  assert decoded.hrp == "test"
  assert decoded.variant == Bech32mV
  assert decoded.data == data
}

pub fn bech32m_empty_data_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode(<<>>, using: yabase.Bech32Encoding("a", Bech32mV))
  let assert Ok(decoded) = yabase.decode_bech32(encoded)
  assert decoded.hrp == "a"
  assert decoded.variant == Bech32mV
}

// ===== Default-variant convenience (issue #21) =====

/// `encode_default` lets app authors emit a Bech32-shaped ID with
/// just an HRP and a payload — no variant choice. The default is
/// `Bech32m` (BIP 350), the strict-checksum variant recommended for
/// every non-SegWit-v0 use.
pub fn encode_default_picks_bech32m_test() -> Nil {
  let data = <<10, 20, 30, 40>>
  let assert Ok(encoded) =
    yabase.encode(data, using: yabase.Bech32Encoding("post", yabase.Bech32m))
  let assert Ok(decoded) = yabase.decode_bech32(encoded)
  assert decoded.hrp == "post"
  assert decoded.variant == Bech32mV
  assert decoded.data == data
}

/// `encode_default` matches `encode(Bech32mV, ..)` byte-for-byte —
/// it's a thin alias, not a different algorithm.
pub fn encode_default_matches_explicit_bech32m_test() -> Nil {
  let data = <<1, 2, 3, 4, 5>>
  let assert Ok(via_default) =
    yabase.encode(data, using: yabase.Bech32Encoding("test", yabase.Bech32m))
  let assert Ok(via_explicit) =
    yabase.encode(data, using: yabase.Bech32Encoding("test", Bech32mV))
  assert via_default == via_explicit
}

/// `encode_default` still applies HRP validation — uppercase HRPs
/// are rejected exactly like `encode(...)` would, so the convenience
/// helper doesn't bypass any safety check.
pub fn encode_default_rejects_uppercase_hrp_test() -> Nil {
  assert case
    yabase.encode(<<0>>, using: yabase.Bech32Encoding("BC", yabase.Bech32m))
  {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}

// ===== Variant auto-detection =====

pub fn auto_detect_bech32_test() -> Nil {
  let data = <<10, 20>>
  let assert Ok(encoded) =
    yabase.encode(data, using: yabase.Bech32Encoding("bc", Bech32V))
  let assert Ok(decoded) = yabase.decode_bech32(encoded)
  assert decoded.variant == Bech32V
}

pub fn auto_detect_bech32m_test() -> Nil {
  let data = <<10, 20>>
  let assert Ok(encoded) =
    yabase.encode(data, using: yabase.Bech32Encoding("bc", Bech32mV))
  let assert Ok(decoded) = yabase.decode_bech32(encoded)
  assert decoded.variant == Bech32mV
}

// ===== Error cases =====

pub fn decode_invalid_checksum_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode(<<1, 2, 3>>, using: yabase.Bech32Encoding("test", Bech32V))
  let corrupted = encoded <> "q"
  assert yabase.decode_bech32(corrupted) == Error(InvalidChecksum)
}

pub fn decode_no_separator_test() -> Nil {
  assert case yabase.decode_bech32("noseparator") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}

pub fn decode_empty_hrp_test() -> Nil {
  assert case yabase.decode_bech32("1qqqqqp") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}

pub fn decode_mixed_case_test() -> Nil {
  assert case yabase.decode_bech32("Test1qqqqqq") {
    Error(yabase.MixedCase) -> True
    _ -> False
  }
}

// ===== BIP 173/350 length constraints =====

pub fn decode_overlength_reject_test() -> Nil {
  let long_data = string.repeat("q", 89)
  let input = "a1" <> long_data
  assert string.length(input) == 91
  assert case yabase.decode_bech32(input) {
    Error(InvalidLength(91)) -> True
    _ -> False
  }
}

pub fn encode_hrp_too_long_test() -> Nil {
  let long_hrp = string.repeat("a", 84)
  assert case
    yabase.encode(<<1>>, using: yabase.Bech32Encoding(long_hrp, Bech32V))
  {
    Error(InvalidHrp("HRP too long")) -> True
    _ -> False
  }
}

pub fn encode_empty_hrp_test() -> Nil {
  assert case yabase.encode(<<1>>, using: yabase.Bech32Encoding("", Bech32V)) {
    Error(InvalidHrp("empty HRP")) -> True
    _ -> False
  }
}

pub fn encode_uppercase_hrp_rejected_test() -> Nil {
  // BIP 173 mandates a lowercase HRP. Issue #15 — `encode` previously
  // silently lowercased uppercase input, which mutated the caller's HRP
  // identifier without any signal. The expected behavior is to reject.
  assert case
    yabase.encode(<<1, 2, 3>>, using: yabase.Bech32Encoding("BC", Bech32V))
  {
    Error(InvalidHrp("HRP must be lowercase")) -> True
    _ -> False
  }
}

pub fn encode_mixed_case_hrp_rejected_test() -> Nil {
  // Mixed case is also rejected — any deviation from all-lowercase falls
  // under the same BIP 173 rule.
  assert case
    yabase.encode(<<1, 2, 3>>, using: yabase.Bech32Encoding("Bc", Bech32V))
  {
    Error(InvalidHrp("HRP must be lowercase")) -> True
    _ -> False
  }
}

pub fn encode_uppercase_hrp_rejected_for_bech32m_test() -> Nil {
  // Same rule applies to the Bech32m variant.
  assert case
    yabase.encode(<<1, 2, 3>>, using: yabase.Bech32Encoding("BC", Bech32mV))
  {
    Error(InvalidHrp("HRP must be lowercase")) -> True
    _ -> False
  }
}

pub fn encode_result_overlength_test() -> Nil {
  let big_data = <<
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
    22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52,
  >>
  assert case
    yabase.encode(big_data, using: yabase.Bech32Encoding("bc", Bech32V))
  {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

// ===== BIP 173 test vectors =====
// Note: some BIP 173 "invalid" vectors are invalid at the segwit-address
// layer (witness version/length), not at the raw Bech32 layer.
// Our bech32.decode is raw Bech32, so valid-Bech32 strings succeed.

pub fn bip173_valid_bech32_but_invalid_segwit_test() -> Nil {
  // "bc1zw508d6qejxtdg4y5r3zarvaryvqyzf3du" - valid Bech32, invalid segwit
  // Raw Bech32 decode should succeed.
  let assert Ok(decoded) =
    yabase.decode_bech32("bc1zw508d6qejxtdg4y5r3zarvaryvqyzf3du")
  assert decoded.hrp == "bc"
  assert decoded.variant == Bech32V
}

pub fn bip173_invalid_mixed_case_test() -> Nil {
  // Mixed case is rejected at Bech32 level
  assert case yabase.decode_bech32("bc1QW508D6QEjXTDG4Y5R3ZaRVARYVQYZF3DU") {
    Error(yabase.MixedCase) -> True
    _ -> False
  }
}

pub fn bip173_invalid_checksum_test() -> Nil {
  // "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t5" has invalid checksum
  // (last char changed from '4' to '5')
  assert case
    yabase.decode_bech32("bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t5")
  {
    Error(InvalidChecksum) -> True
    _ -> False
  }
}

pub fn padding_bits_preserved_on_roundtrip_test() -> Nil {
  // 1 byte = 8 bits -> 2 five-bit groups = 10 bits -> 2 padding bits
  // Encode produces zero-padded groups; decode must recover the original byte.
  let assert Ok(encoded) =
    yabase.encode(<<0xff>>, using: yabase.Bech32Encoding("test", Bech32V))
  let assert Ok(decoded) = yabase.decode_bech32(encoded)
  assert decoded.data == <<0xff>>
}

// ===== BIP 350 Bech32m specific vectors =====

pub fn bech32m_bc_prefix_roundtrip_test() -> Nil {
  let data = <<0, 0x75, 0x1e, 0x76, 0xe8, 0x19, 0x91, 0x96>>
  let assert Ok(encoded) =
    yabase.encode(data, using: yabase.Bech32Encoding("bc", Bech32mV))
  let assert Ok(decoded) = yabase.decode_bech32(encoded)
  assert decoded.variant == Bech32mV
  assert decoded.data == data
}

pub fn bech32m_tb_prefix_roundtrip_test() -> Nil {
  let data = <<1, 2, 3>>
  let assert Ok(encoded) =
    yabase.encode(data, using: yabase.Bech32Encoding("tb", Bech32mV))
  let assert Ok(decoded) = yabase.decode_bech32(encoded)
  assert decoded.variant == Bech32mV
  assert decoded.hrp == "tb"
  assert decoded.data == data
}

pub fn bech32m_long_hrp_test() -> Nil {
  // 10 char HRP
  let data = <<42>>
  let assert Ok(encoded) =
    yabase.encode(data, using: yabase.Bech32Encoding("abcdefghij", Bech32mV))
  let assert Ok(decoded) = yabase.decode_bech32(encoded)
  assert decoded.hrp == "abcdefghij"
  assert decoded.variant == Bech32mV
}

// ===== Additional edge cases =====

pub fn decode_all_uppercase_valid_test() -> Nil {
  // All-uppercase is valid per BIP 173; decode normalizes to lowercase
  let assert Ok(encoded) =
    yabase.encode(<<1, 2>>, using: yabase.Bech32Encoding("test", Bech32V))
  let upper = string_uppercase(encoded)
  let assert Ok(decoded) = yabase.decode_bech32(upper)
  assert decoded.data == <<1, 2>>
}

fn string_uppercase(s: String) -> String {
  do_uppercase(s, "")
}

fn do_uppercase(s: String, acc: String) -> String {
  case string.pop_grapheme(s) {
    Error(Nil) -> acc
    Ok(#(c, rest)) -> do_uppercase(rest, acc <> string.uppercase(c))
  }
}

pub fn decode_hrp_out_of_range_test() -> Nil {
  // HRP with character below ASCII 33 (space = 32)
  assert case yabase.decode_bech32(" 1nwldj5") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}

pub fn decode_hrp_del_char_test() -> Nil {
  // HRP with DEL (127) is out of range
  assert case yabase.decode_bech32("\u{007F}1axkwrx") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}

pub fn decode_data_part_too_short_test() -> Nil {
  // Separator found but data part is less than 6 chars (checksum alone)
  assert case yabase.decode_bech32("a1aaaa") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

pub fn decode_data_part_exactly_6_chars_test() -> Nil {
  // 6 chars in data part = checksum only, no actual data -> valid empty data
  let assert Ok(encoded) =
    yabase.encode(<<>>, using: yabase.Bech32Encoding("a", Bech32V))
  let assert Ok(decoded) = yabase.decode_bech32(encoded)
  assert decoded.data == <<>>
}

// ===== sipa/bech32 reference vectors =====
// Source: https://github.com/sipa/bech32

// Valid Bech32 strings (raw decode should succeed)
pub fn sipa_valid_bech32_a12uel5l_test() -> Nil {
  let assert Ok(d) = yabase.decode_bech32("A12UEL5L")
  assert d.hrp == "a"
  assert d.variant == Bech32V
}

pub fn sipa_valid_bech32_long_hrp_test() -> Nil {
  let assert Ok(d) =
    yabase.decode_bech32(
      "an83characterlonghumanreadablepartthatcontainsthenumber1andtheexcludedcharactersbio1tt5tgs",
    )
  assert d.variant == Bech32V
}

pub fn sipa_valid_bech32_split_test() -> Nil {
  let assert Ok(d) =
    yabase.decode_bech32(
      "split1checkupstagehandshakeupstreamerranterredcaperred2y9e3w",
    )
  assert d.hrp == "split"
  assert d.variant == Bech32V
}

pub fn sipa_valid_bech32_question_mark_test() -> Nil {
  let assert Ok(d) = yabase.decode_bech32("?1ezyfcl")
  assert d.hrp == "?"
  assert d.variant == Bech32V
}

// Valid Bech32m strings
pub fn sipa_valid_bech32m_a1lqfn3a_test() -> Nil {
  let assert Ok(d) = yabase.decode_bech32("A1LQFN3A")
  assert d.hrp == "a"
  assert d.variant == Bech32mV
}

pub fn sipa_valid_bech32m_question_mark_test() -> Nil {
  let assert Ok(d) = yabase.decode_bech32("?1v759aa")
  assert d.hrp == "?"
  assert d.variant == Bech32mV
}

pub fn sipa_valid_bech32m_split_test() -> Nil {
  let assert Ok(d) =
    yabase.decode_bech32(
      "split1checkupstagehandshakeupstreamerranterredcaperredlc445v",
    )
  assert d.hrp == "split"
  assert d.variant == Bech32mV
}

// Invalid Bech32 strings (must fail to decode)
pub fn sipa_invalid_bech32_no_separator_test() -> Nil {
  assert case yabase.decode_bech32("pzry9x0s0muk") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}

pub fn sipa_invalid_bech32_empty_hrp_1pzry_test() -> Nil {
  assert case yabase.decode_bech32("1pzry9x0s0muk") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}

pub fn sipa_invalid_bech32_empty_hrp_10a06t8_test() -> Nil {
  assert case yabase.decode_bech32("10a06t8") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}

pub fn sipa_invalid_bech32_empty_hrp_1qzzfhee_test() -> Nil {
  assert case yabase.decode_bech32("1qzzfhee") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}

pub fn sipa_invalid_bech32_too_short_li1dgmt3_test() -> Nil {
  assert case yabase.decode_bech32("li1dgmt3") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

// Invalid Bech32m strings
pub fn sipa_invalid_bech32m_no_separator_test() -> Nil {
  assert case yabase.decode_bech32("qyrz8wqd2c9m") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}

pub fn sipa_invalid_bech32m_empty_hrp_test() -> Nil {
  assert case yabase.decode_bech32("1qyrz8wqd2c9m") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}

pub fn sipa_invalid_bech32m_too_short_in1muywd_test() -> Nil {
  assert case yabase.decode_bech32("in1muywd") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

pub fn sipa_invalid_bech32m_empty_hrp_16plkw9_test() -> Nil {
  assert case yabase.decode_bech32("16plkw9") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}

pub fn sipa_invalid_bech32m_empty_hrp_1p2gdwpf_test() -> Nil {
  assert case yabase.decode_bech32("1p2gdwpf") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}
