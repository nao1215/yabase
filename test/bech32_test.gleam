import gleam/string
import yabase/bech32
import yabase/core/encoding.{
  Bech32 as Bech32V, Bech32m as Bech32mV, InvalidCharacter, InvalidChecksum,
  InvalidHrp, InvalidLength,
}

// ===== BIP 173 Bech32 =====

pub fn bech32_roundtrip_test() {
  let data = <<0, 1, 2, 3, 4>>
  let assert Ok(encoded) = bech32.encode(Bech32V, "test", data)
  let assert Ok(decoded) = bech32.decode(encoded)
  assert decoded.hrp == "test"
  assert decoded.variant == Bech32V
  assert decoded.data == data
}

pub fn bech32_empty_data_test() {
  let assert Ok(encoded) = bech32.encode(Bech32V, "a", <<>>)
  let assert Ok(decoded) = bech32.decode(encoded)
  assert decoded.hrp == "a"
  assert decoded.data == <<>>
  assert decoded.variant == Bech32V
}

// ===== BIP 350 Bech32m =====

pub fn bech32m_roundtrip_test() {
  let data = <<0, 1, 2, 3>>
  let assert Ok(encoded) = bech32.encode(Bech32mV, "test", data)
  let assert Ok(decoded) = bech32.decode(encoded)
  assert decoded.hrp == "test"
  assert decoded.variant == Bech32mV
  assert decoded.data == data
}

pub fn bech32m_empty_data_test() {
  let assert Ok(encoded) = bech32.encode(Bech32mV, "a", <<>>)
  let assert Ok(decoded) = bech32.decode(encoded)
  assert decoded.hrp == "a"
  assert decoded.variant == Bech32mV
}

// ===== Variant auto-detection =====

pub fn auto_detect_bech32_test() {
  let data = <<10, 20>>
  let assert Ok(encoded) = bech32.encode(Bech32V, "bc", data)
  let assert Ok(decoded) = bech32.decode(encoded)
  assert decoded.variant == Bech32V
}

pub fn auto_detect_bech32m_test() {
  let data = <<10, 20>>
  let assert Ok(encoded) = bech32.encode(Bech32mV, "bc", data)
  let assert Ok(decoded) = bech32.decode(encoded)
  assert decoded.variant == Bech32mV
}

// ===== Error cases =====

pub fn decode_invalid_checksum_test() {
  let assert Ok(encoded) = bech32.encode(Bech32V, "test", <<1, 2, 3>>)
  let corrupted = encoded <> "q"
  assert bech32.decode(corrupted) == Error(InvalidChecksum)
}

pub fn decode_no_separator_test() {
  assert case bech32.decode("noseparator") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}

pub fn decode_empty_hrp_test() {
  assert case bech32.decode("1qqqqqp") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}

pub fn decode_mixed_case_test() {
  assert case bech32.decode("Test1qqqqqq") {
    Error(InvalidCharacter("mixed-case", _)) -> True
    _ -> False
  }
}

// ===== BIP 173/350 length constraints =====

pub fn decode_overlength_reject_test() {
  let long_data = string.repeat("q", 89)
  let input = "a1" <> long_data
  assert string.length(input) == 91
  assert case bech32.decode(input) {
    Error(InvalidLength(91)) -> True
    _ -> False
  }
}

pub fn encode_hrp_too_long_test() {
  let long_hrp = string.repeat("a", 84)
  assert case bech32.encode(Bech32V, long_hrp, <<1>>) {
    Error(InvalidHrp("HRP too long")) -> True
    _ -> False
  }
}

pub fn encode_empty_hrp_test() {
  assert case bech32.encode(Bech32V, "", <<1>>) {
    Error(InvalidHrp("empty HRP")) -> True
    _ -> False
  }
}

pub fn encode_result_overlength_test() {
  let big_data = <<
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
    22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52,
  >>
  assert case bech32.encode(Bech32V, "bc", big_data) {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

// ===== BIP 173 test vectors =====
// Note: some BIP 173 "invalid" vectors are invalid at the segwit-address
// layer (witness version/length), not at the raw Bech32 layer.
// Our bech32.decode is raw Bech32, so valid-Bech32 strings succeed.

pub fn bip173_valid_bech32_but_invalid_segwit_test() {
  // "bc1zw508d6qejxtdg4y5r3zarvaryvqyzf3du" - valid Bech32, invalid segwit
  // Raw Bech32 decode should succeed.
  let assert Ok(decoded) =
    bech32.decode("bc1zw508d6qejxtdg4y5r3zarvaryvqyzf3du")
  assert decoded.hrp == "bc"
  assert decoded.variant == Bech32V
}

pub fn bip173_invalid_mixed_case_test() {
  // Mixed case is rejected at Bech32 level
  assert case bech32.decode("bc1QW508D6QEjXTDG4Y5R3ZaRVARYVQYZF3DU") {
    Error(InvalidCharacter("mixed-case", _)) -> True
    _ -> False
  }
}

pub fn bip173_invalid_checksum_test() {
  // "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t5" has invalid checksum
  // (last char changed from '4' to '5')
  assert case bech32.decode("bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t5") {
    Error(InvalidChecksum) -> True
    _ -> False
  }
}

pub fn padding_bits_preserved_on_roundtrip_test() {
  // 1 byte = 8 bits -> 2 five-bit groups = 10 bits -> 2 padding bits
  // Encode produces zero-padded groups; decode must recover the original byte.
  let assert Ok(encoded) = bech32.encode(Bech32V, "test", <<0xff>>)
  let assert Ok(decoded) = bech32.decode(encoded)
  assert decoded.data == <<0xff>>
}

// ===== BIP 350 Bech32m specific vectors =====

pub fn bech32m_bc_prefix_roundtrip_test() {
  let data = <<0, 0x75, 0x1e, 0x76, 0xe8, 0x19, 0x91, 0x96>>
  let assert Ok(encoded) = bech32.encode(Bech32mV, "bc", data)
  let assert Ok(decoded) = bech32.decode(encoded)
  assert decoded.variant == Bech32mV
  assert decoded.data == data
}

pub fn bech32m_tb_prefix_roundtrip_test() {
  let data = <<1, 2, 3>>
  let assert Ok(encoded) = bech32.encode(Bech32mV, "tb", data)
  let assert Ok(decoded) = bech32.decode(encoded)
  assert decoded.variant == Bech32mV
  assert decoded.hrp == "tb"
  assert decoded.data == data
}

pub fn bech32m_long_hrp_test() {
  // 10 char HRP
  let data = <<42>>
  let assert Ok(encoded) = bech32.encode(Bech32mV, "abcdefghij", data)
  let assert Ok(decoded) = bech32.decode(encoded)
  assert decoded.hrp == "abcdefghij"
  assert decoded.variant == Bech32mV
}

// ===== Additional edge cases =====

pub fn decode_all_uppercase_valid_test() {
  // All-uppercase is valid per BIP 173; decode normalizes to lowercase
  let assert Ok(encoded) = bech32.encode(Bech32V, "test", <<1, 2>>)
  let upper = string_uppercase(encoded)
  let assert Ok(decoded) = bech32.decode(upper)
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

pub fn decode_hrp_out_of_range_test() {
  // HRP with character below ASCII 33 (space = 32)
  assert case bech32.decode(" 1nwldj5") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}

pub fn decode_hrp_del_char_test() {
  // HRP with DEL (127) is out of range
  assert case bech32.decode("\u{007F}1axkwrx") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}

pub fn decode_data_part_too_short_test() {
  // Separator found but data part is less than 6 chars (checksum alone)
  assert case bech32.decode("a1aaaa") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

pub fn decode_data_part_exactly_6_chars_test() {
  // 6 chars in data part = checksum only, no actual data -> valid empty data
  let assert Ok(encoded) = bech32.encode(Bech32V, "a", <<>>)
  let assert Ok(decoded) = bech32.decode(encoded)
  assert decoded.data == <<>>
}

// ===== sipa/bech32 reference vectors =====
// Source: https://github.com/sipa/bech32

// Valid Bech32 strings (raw decode should succeed)
pub fn sipa_valid_bech32_a12uel5l_test() {
  let assert Ok(d) = bech32.decode("A12UEL5L")
  assert d.hrp == "a"
  assert d.variant == Bech32V
}

pub fn sipa_valid_bech32_long_hrp_test() {
  let assert Ok(d) =
    bech32.decode(
      "an83characterlonghumanreadablepartthatcontainsthenumber1andtheexcludedcharactersbio1tt5tgs",
    )
  assert d.variant == Bech32V
}

pub fn sipa_valid_bech32_split_test() {
  let assert Ok(d) =
    bech32.decode(
      "split1checkupstagehandshakeupstreamerranterredcaperred2y9e3w",
    )
  assert d.hrp == "split"
  assert d.variant == Bech32V
}

pub fn sipa_valid_bech32_question_mark_test() {
  let assert Ok(d) = bech32.decode("?1ezyfcl")
  assert d.hrp == "?"
  assert d.variant == Bech32V
}

// Valid Bech32m strings
pub fn sipa_valid_bech32m_a1lqfn3a_test() {
  let assert Ok(d) = bech32.decode("A1LQFN3A")
  assert d.hrp == "a"
  assert d.variant == Bech32mV
}

pub fn sipa_valid_bech32m_question_mark_test() {
  let assert Ok(d) = bech32.decode("?1v759aa")
  assert d.hrp == "?"
  assert d.variant == Bech32mV
}

pub fn sipa_valid_bech32m_split_test() {
  let assert Ok(d) =
    bech32.decode(
      "split1checkupstagehandshakeupstreamerranterredcaperredlc445v",
    )
  assert d.hrp == "split"
  assert d.variant == Bech32mV
}

// Invalid Bech32 strings (must fail to decode)
pub fn sipa_invalid_bech32_no_separator_test() {
  assert case bech32.decode("pzry9x0s0muk") {
    Error(_) -> True
    _ -> False
  }
}

pub fn sipa_invalid_bech32_empty_hrp_1pzry_test() {
  assert case bech32.decode("1pzry9x0s0muk") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}

pub fn sipa_invalid_bech32_empty_hrp_10a06t8_test() {
  assert case bech32.decode("10a06t8") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}

pub fn sipa_invalid_bech32_empty_hrp_1qzzfhee_test() {
  assert case bech32.decode("1qzzfhee") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}

pub fn sipa_invalid_bech32_too_short_li1dgmt3_test() {
  assert case bech32.decode("li1dgmt3") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

// Invalid Bech32m strings
pub fn sipa_invalid_bech32m_no_separator_test() {
  assert case bech32.decode("qyrz8wqd2c9m") {
    Error(_) -> True
    _ -> False
  }
}

pub fn sipa_invalid_bech32m_empty_hrp_test() {
  assert case bech32.decode("1qyrz8wqd2c9m") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}

pub fn sipa_invalid_bech32m_too_short_in1muywd_test() {
  assert case bech32.decode("in1muywd") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

pub fn sipa_invalid_bech32m_empty_hrp_16plkw9_test() {
  assert case bech32.decode("16plkw9") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}

pub fn sipa_invalid_bech32m_empty_hrp_1p2gdwpf_test() {
  assert case bech32.decode("1p2gdwpf") {
    Error(InvalidHrp(_)) -> True
    _ -> False
  }
}
