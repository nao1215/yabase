import gleam/string
import yabase/base32/clockwork
import yabase/base32/crockford
import yabase/base32/hex as base32_hex
import yabase/base32/rfc4648
import yabase/core/error.{InvalidCharacter, InvalidChecksum, InvalidLength}

// ===== RFC4648 =====

// --- Fixed vectors (RFC 4648 section 10) ---

pub fn rfc4648_encode_empty_test() -> Nil {
  assert rfc4648.encode(<<>>) == ""
}

pub fn rfc4648_encode_f_test() -> Nil {
  assert rfc4648.encode(<<"f":utf8>>) == "MY======"
}

pub fn rfc4648_encode_fo_test() -> Nil {
  assert rfc4648.encode(<<"fo":utf8>>) == "MZXQ===="
}

pub fn rfc4648_encode_foo_test() -> Nil {
  assert rfc4648.encode(<<"foo":utf8>>) == "MZXW6==="
}

pub fn rfc4648_encode_foob_test() -> Nil {
  assert rfc4648.encode(<<"foob":utf8>>) == "MZXW6YQ="
}

pub fn rfc4648_encode_fooba_test() -> Nil {
  assert rfc4648.encode(<<"fooba":utf8>>) == "MZXW6YTB"
}

pub fn rfc4648_encode_foobar_test() -> Nil {
  assert rfc4648.encode(<<"foobar":utf8>>) == "MZXW6YTBOI======"
}

pub fn rfc4648_decode_empty_test() -> Nil {
  assert rfc4648.decode("") == Ok(<<>>)
}

pub fn rfc4648_decode_f_test() -> Nil {
  assert rfc4648.decode("MY======") == Ok(<<"f":utf8>>)
}

pub fn rfc4648_decode_foobar_test() -> Nil {
  assert rfc4648.decode("MZXW6YTBOI======") == Ok(<<"foobar":utf8>>)
}

// --- Decode errors ---

pub fn rfc4648_decode_invalid_char_test() -> Nil {
  assert rfc4648.decode("M1======") == Error(InvalidCharacter("1", 1))
}

pub fn rfc4648_decode_leading_pad_test() -> Nil {
  // "=MY=====" has padding before data -> must fail
  assert case rfc4648.decode("=MY=====") {
    Error(InvalidCharacter("=", _)) -> True
    _ -> False
  }
}

pub fn rfc4648_decode_mid_pad_test() -> Nil {
  // "M=Y=====" has padding in the middle -> must fail
  assert case rfc4648.decode("M=Y=====") {
    Error(InvalidCharacter("=", _)) -> True
    _ -> False
  }
}

pub fn rfc4648_decode_excess_pad_test() -> Nil {
  // "MY=======" is 9 chars with padding -> 9 % 8 != 0 -> InvalidLength
  assert rfc4648.decode("MY=======") == Error(InvalidLength(9))
}

pub fn rfc4648_decode_pure_padding_test() -> Nil {
  // "========" is all padding, no data characters -> must fail
  assert case rfc4648.decode("========") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

// --- Whitespace and other non-alphabet bytes (#7) ---
//
// Whitespace surfaces as InvalidCharacter with its position; the
// alphabet check runs before the length check so the diagnostic
// points at the real fault rather than at a misleading length
// mismatch.

pub fn rfc4648_decode_rejects_lf_test() -> Nil {
  assert rfc4648.decode("MZXW6\n===") == Error(InvalidCharacter("\n", 5))
}

pub fn rfc4648_decode_rejects_space_test() -> Nil {
  assert rfc4648.decode("MZXW 6===") == Error(InvalidCharacter(" ", 4))
}

// --- Unpadded decode ---

pub fn rfc4648_decode_unpadded_f_test() -> Nil {
  assert rfc4648.decode("MY") == Ok(<<"f":utf8>>)
}

pub fn rfc4648_decode_unpadded_foobar_test() -> Nil {
  assert rfc4648.decode("MZXW6YTBOI") == Ok(<<"foobar":utf8>>)
}

// --- Roundtrip corpus ---

pub fn rfc4648_roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert rfc4648.decode(rfc4648.encode(data)) == Ok(data)
}

pub fn rfc4648_roundtrip_empty_test() -> Nil {
  assert rfc4648.decode(rfc4648.encode(<<>>)) == Ok(<<>>)
}

pub fn rfc4648_roundtrip_single_zero_test() -> Nil {
  assert rfc4648.decode(rfc4648.encode(<<0>>)) == Ok(<<0>>)
}

pub fn rfc4648_roundtrip_leading_zeros_test() -> Nil {
  let data = <<0, 0, 0, 42>>
  assert rfc4648.decode(rfc4648.encode(data)) == Ok(data)
}

pub fn rfc4648_roundtrip_all_zeros_test() -> Nil {
  let data = <<0, 0, 0, 0>>
  assert rfc4648.decode(rfc4648.encode(data)) == Ok(data)
}

pub fn rfc4648_roundtrip_high_bits_test() -> Nil {
  let data = <<0xff, 0x80, 0x7f>>
  assert rfc4648.decode(rfc4648.encode(data)) == Ok(data)
}

// ===== Hex =====

pub fn hex_encode_empty_test() -> Nil {
  assert base32_hex.encode(<<>>) == ""
}

pub fn hex_encode_foo_test() -> Nil {
  assert base32_hex.encode(<<"foo":utf8>>) == "CPNMU==="
}

pub fn hex_decode_unpadded_foo_test() -> Nil {
  assert base32_hex.decode("CPNMU") == Ok(<<"foo":utf8>>)
}

pub fn hex_roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert base32_hex.decode(base32_hex.encode(data)) == Ok(data)
}

pub fn hex_roundtrip_empty_test() -> Nil {
  assert base32_hex.decode(base32_hex.encode(<<>>)) == Ok(<<>>)
}

pub fn hex_roundtrip_single_zero_test() -> Nil {
  assert base32_hex.decode(base32_hex.encode(<<0>>)) == Ok(<<0>>)
}

pub fn hex_decode_leading_pad_test() -> Nil {
  // "=0000000" is 8 chars with leading pad -> InvalidCharacter
  assert case base32_hex.decode("=0000000") {
    Error(InvalidCharacter("=", _)) -> True
    _ -> False
  }
}

pub fn hex_decode_mid_pad_test() -> Nil {
  // "00=00000" is 8 chars with mid pad -> InvalidCharacter
  assert case base32_hex.decode("00=00000") {
    Error(InvalidCharacter("=", _)) -> True
    _ -> False
  }
}

pub fn hex_decode_pure_padding_test() -> Nil {
  assert case base32_hex.decode("========") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

// ===== Crockford =====
// Crockford Base32 treats data as a number, not a byte stream.
// See: https://www.crockford.com/base32.html

pub fn crockford_encode_empty_test() -> Nil {
  assert crockford.encode(<<>>) == ""
}

// Spec conformance: numeric value encoding
pub fn crockford_encode_numeric_65_test() -> Nil {
  // <<65>> = numeric 65, 65 = 2*32 + 1 = "21"
  assert crockford.encode(<<65>>) == "21"
}

pub fn crockford_encode_numeric_0_test() -> Nil {
  // <<0>> = numeric 0
  assert crockford.encode(<<0>>) == "0"
}

pub fn crockford_encode_numeric_31_test() -> Nil {
  // <<31>> = numeric 31 = "Z"
  assert crockford.encode(<<31>>) == "Z"
}

pub fn crockford_encode_numeric_32_test() -> Nil {
  // <<32>> = numeric 32 = 1*32 + 0 = "10"
  assert crockford.encode(<<32>>) == "10"
}

pub fn crockford_encode_numeric_1023_test() -> Nil {
  // <<3, 0xFF>> = numeric 1023 = 31*32 + 31 = "ZZ"
  assert crockford.encode(<<3, 255>>) == "ZZ"
}

pub fn crockford_roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert crockford.decode(crockford.encode(data)) == Ok(data)
}

pub fn crockford_roundtrip_empty_test() -> Nil {
  assert crockford.decode(crockford.encode(<<>>)) == Ok(<<>>)
}

pub fn crockford_roundtrip_single_zero_test() -> Nil {
  assert crockford.decode(crockford.encode(<<0>>)) == Ok(<<0>>)
}

pub fn crockford_roundtrip_leading_zeros_test() -> Nil {
  let data = <<0, 0, 42>>
  assert crockford.decode(crockford.encode(data)) == Ok(data)
}

pub fn crockford_decode_with_hyphens_test() -> Nil {
  // Crockford allows hyphens as separators
  let data = <<"test":utf8>>
  let encoded = crockford.encode(data)
  // Insert hyphens into the encoded string
  let with_hyphens =
    string.to_graphemes(encoded)
    |> insert_hyphen_every(4, 0, "")
  assert crockford.decode(with_hyphens) == Ok(data)
}

fn insert_hyphen_every(
  chars chars: List(String),
  every every: Int,
  count count: Int,
  acc acc: String,
) -> String {
  case chars {
    [] -> acc
    [c, ..rest] -> {
      let new_count = count + 1
      let sep = case new_count % every == 0 && rest != [] {
        True -> "-"
        False -> ""
      }
      insert_hyphen_every(
        chars: rest,
        every: every,
        count: new_count,
        acc: acc <> c <> sep,
      )
    }
  }
}

pub fn crockford_decode_o_as_zero_test() -> Nil {
  // "O" should be decoded as "0"
  let data = <<"test":utf8>>
  let encoded = crockford.encode(data)
  // Replace any "0" with "O" — should still decode
  let with_o = string.replace(encoded, "0", "O")
  assert crockford.decode(with_o) == Ok(data)
}

pub fn crockford_decode_i_l_as_one_test() -> Nil {
  // "I" and "L" should be decoded as "1"
  let data = <<"test":utf8>>
  let encoded = crockford.encode(data)
  let with_i = string.replace(encoded, "1", "I")
  assert crockford.decode(with_i) == Ok(data)
}

pub fn crockford_decode_case_insensitive_test() -> Nil {
  assert crockford.decode("2a") == crockford.decode("2A")
  assert crockford.decode("zz") == crockford.decode("ZZ")
}

// ===== Crockford check symbol =====

pub fn crockford_check_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert crockford.decode_check(crockford.encode_check(data)) == Ok(data)
}

pub fn crockford_check_roundtrip_empty_test() -> Nil {
  assert crockford.decode_check(crockford.encode_check(<<>>)) == Ok(<<>>)
}

pub fn crockford_check_roundtrip_single_byte_test() -> Nil {
  assert crockford.decode_check(crockford.encode_check(<<42>>)) == Ok(<<42>>)
}

pub fn crockford_check_symbol_is_appended_test() -> Nil {
  // encode_check should produce encode output + 1 check character
  let data = <<"test":utf8>>
  let without = crockford.encode(data)
  let with = crockford.encode_check(data)
  assert string.length(with) == string.length(without) + 1
}

pub fn crockford_check_wrong_symbol_test() -> Nil {
  let encoded = crockford.encode_check(<<"test":utf8>>)
  // Corrupt the check symbol (last char)
  let len = string.length(encoded)
  let body = string.slice(encoded, 0, len - 1)
  let corrupted = body <> "*"
  // If the original check was not *, this should fail
  case string.slice(encoded, len - 1, 1) == "*" {
    True -> {
      // Original check was *, pick a different corruption
      assert crockford.decode_check(body <> "~") == Error(InvalidChecksum)
    }
    False -> {
      assert crockford.decode_check(corrupted) == Error(InvalidChecksum)
    }
  }
}

pub fn crockford_check_extended_symbols_test() -> Nil {
  // Values 32-36 map to *~$=U; test that these round-trip
  // Find data whose mod 37 hits each extended symbol
  // 32 = *, 33 = ~, 34 = $, 35 = =, 36 = U
  assert crockford.decode_check(crockford.encode_check(<<32>>)) == Ok(<<32>>)
  assert crockford.decode_check(crockford.encode_check(<<33>>)) == Ok(<<33>>)
  assert crockford.decode_check(crockford.encode_check(<<34>>)) == Ok(<<34>>)
  assert crockford.decode_check(crockford.encode_check(<<35>>)) == Ok(<<35>>)
  assert crockford.decode_check(crockford.encode_check(<<36>>)) == Ok(<<36>>)
}

pub fn crockford_check_empty_input_decode_test() -> Nil {
  // Decoding a single character = just a check symbol, body is empty
  assert crockford.decode_check("0") == Ok(<<>>)
}

// ===== Clockwork =====

pub fn clockwork_encode_empty_test() -> Nil {
  assert clockwork.encode(<<>>) == ""
}

pub fn clockwork_roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert clockwork.decode(clockwork.encode(data)) == Ok(data)
}

pub fn clockwork_roundtrip_empty_test() -> Nil {
  assert clockwork.decode(clockwork.encode(<<>>)) == Ok(<<>>)
}

pub fn clockwork_roundtrip_single_zero_test() -> Nil {
  assert clockwork.decode(clockwork.encode(<<0>>)) == Ok(<<0>>)
}

pub fn clockwork_decode_lowercase_test() -> Nil {
  let data = <<"test":utf8>>
  let encoded = clockwork.encode(data)
  // lowercase should also decode
  assert clockwork.decode(string.lowercase(encoded)) == Ok(data)
}

pub fn clockwork_decode_o_as_zero_test() -> Nil {
  let data = <<"test":utf8>>
  let encoded = clockwork.encode(data)
  let with_o = string.replace(encoded, "0", "O")
  assert clockwork.decode(with_o) == Ok(data)
}

pub fn clockwork_decode_i_l_as_one_test() -> Nil {
  let data = <<"test":utf8>>
  let encoded = clockwork.encode(data)
  let with_l = string.replace(encoded, "1", "L")
  assert clockwork.decode(with_l) == Ok(data)
}
