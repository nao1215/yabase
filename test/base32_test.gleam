import codec_test_support
import gleam/string
import yabase.{InvalidCharacter, InvalidChecksum, InvalidLength, NonCanonical}

// ===== RFC4648 =====

// --- Fixed vectors (RFC 4648 section 10) ---

pub fn rfc4648_encode_empty_test() -> Nil {
  assert codec_test_support.encode(<<>>, using: yabase.Base32Rfc4648) == ""
}

pub fn rfc4648_encode_f_test() -> Nil {
  assert codec_test_support.encode(<<"f":utf8>>, using: yabase.Base32Rfc4648)
    == "MY======"
}

pub fn rfc4648_encode_fo_test() -> Nil {
  assert codec_test_support.encode(<<"fo":utf8>>, using: yabase.Base32Rfc4648)
    == "MZXQ===="
}

pub fn rfc4648_encode_foo_test() -> Nil {
  assert codec_test_support.encode(<<"foo":utf8>>, using: yabase.Base32Rfc4648)
    == "MZXW6==="
}

pub fn rfc4648_encode_foob_test() -> Nil {
  assert codec_test_support.encode(<<"foob":utf8>>, using: yabase.Base32Rfc4648)
    == "MZXW6YQ="
}

pub fn rfc4648_encode_fooba_test() -> Nil {
  assert codec_test_support.encode(
      <<"fooba":utf8>>,
      using: yabase.Base32Rfc4648,
    )
    == "MZXW6YTB"
}

pub fn rfc4648_encode_foobar_test() -> Nil {
  assert codec_test_support.encode(
      <<"foobar":utf8>>,
      using: yabase.Base32Rfc4648,
    )
    == "MZXW6YTBOI======"
}

pub fn rfc4648_decode_empty_test() -> Nil {
  assert yabase.decode("", using: yabase.Base32Rfc4648) == Ok(<<>>)
}

pub fn rfc4648_decode_f_test() -> Nil {
  assert yabase.decode("MY======", using: yabase.Base32Rfc4648)
    == Ok(<<"f":utf8>>)
}

pub fn rfc4648_decode_foobar_test() -> Nil {
  assert yabase.decode("MZXW6YTBOI======", using: yabase.Base32Rfc4648)
    == Ok(<<"foobar":utf8>>)
}

// --- Decode errors ---

pub fn rfc4648_decode_invalid_char_test() -> Nil {
  assert yabase.decode("M1======", using: yabase.Base32Rfc4648)
    == Error(InvalidCharacter("1", 1))
}

pub fn rfc4648_decode_leading_pad_test() -> Nil {
  // "=MY=====" has padding before data -> must fail
  assert case yabase.decode("=MY=====", using: yabase.Base32Rfc4648) {
    Error(InvalidCharacter("=", _)) -> True
    _ -> False
  }
}

pub fn rfc4648_decode_mid_pad_test() -> Nil {
  // "M=Y=====" has padding in the middle -> must fail
  assert case yabase.decode("M=Y=====", using: yabase.Base32Rfc4648) {
    Error(InvalidCharacter("=", _)) -> True
    _ -> False
  }
}

pub fn rfc4648_decode_excess_pad_test() -> Nil {
  // "MY=======" is 9 chars with padding -> 9 % 8 != 0 -> InvalidLength
  assert yabase.decode("MY=======", using: yabase.Base32Rfc4648)
    == Error(InvalidLength(9))
}

pub fn rfc4648_decode_pure_padding_test() -> Nil {
  // "========" is all padding, no data characters -> must fail
  assert case yabase.decode("========", using: yabase.Base32Rfc4648) {
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
  assert yabase.decode("MZXW6\n===", using: yabase.Base32Rfc4648)
    == Error(InvalidCharacter("\n", 5))
}

pub fn rfc4648_decode_rejects_space_test() -> Nil {
  assert yabase.decode("MZXW 6===", using: yabase.Base32Rfc4648)
    == Error(InvalidCharacter(" ", 4))
}

// --- Unpadded decode ---

pub fn rfc4648_decode_unpadded_f_test() -> Nil {
  assert yabase.decode("MY", using: yabase.Base32Rfc4648) == Ok(<<"f":utf8>>)
}

pub fn rfc4648_decode_unpadded_foobar_test() -> Nil {
  assert yabase.decode("MZXW6YTBOI", using: yabase.Base32Rfc4648)
    == Ok(<<"foobar":utf8>>)
}

// --- Roundtrip corpus ---

pub fn rfc4648_roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base32Rfc4648),
      using: yabase.Base32Rfc4648,
    )
    == Ok(data)
}

pub fn rfc4648_roundtrip_empty_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<>>, using: yabase.Base32Rfc4648),
      using: yabase.Base32Rfc4648,
    )
    == Ok(<<>>)
}

pub fn rfc4648_roundtrip_single_zero_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<0>>, using: yabase.Base32Rfc4648),
      using: yabase.Base32Rfc4648,
    )
    == Ok(<<0>>)
}

pub fn rfc4648_roundtrip_leading_zeros_test() -> Nil {
  let data = <<0, 0, 0, 42>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base32Rfc4648),
      using: yabase.Base32Rfc4648,
    )
    == Ok(data)
}

pub fn rfc4648_roundtrip_all_zeros_test() -> Nil {
  let data = <<0, 0, 0, 0>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base32Rfc4648),
      using: yabase.Base32Rfc4648,
    )
    == Ok(data)
}

pub fn rfc4648_roundtrip_high_bits_test() -> Nil {
  let data = <<0xff, 0x80, 0x7f>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base32Rfc4648),
      using: yabase.Base32Rfc4648,
    )
    == Ok(data)
}

// ===== Hex =====

pub fn hex_encode_empty_test() -> Nil {
  assert codec_test_support.encode(<<>>, using: yabase.Base32Hex) == ""
}

pub fn hex_encode_foo_test() -> Nil {
  assert codec_test_support.encode(<<"foo":utf8>>, using: yabase.Base32Hex)
    == "CPNMU==="
}

pub fn hex_decode_unpadded_foo_test() -> Nil {
  assert yabase.decode("CPNMU", using: yabase.Base32Hex) == Ok(<<"foo":utf8>>)
}

pub fn hex_roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base32Hex),
      using: yabase.Base32Hex,
    )
    == Ok(data)
}

pub fn hex_roundtrip_empty_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<>>, using: yabase.Base32Hex),
      using: yabase.Base32Hex,
    )
    == Ok(<<>>)
}

pub fn hex_roundtrip_single_zero_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<0>>, using: yabase.Base32Hex),
      using: yabase.Base32Hex,
    )
    == Ok(<<0>>)
}

pub fn hex_decode_leading_pad_test() -> Nil {
  // "=0000000" is 8 chars with leading pad -> InvalidCharacter
  assert case yabase.decode("=0000000", using: yabase.Base32Hex) {
    Error(InvalidCharacter("=", _)) -> True
    _ -> False
  }
}

pub fn hex_decode_mid_pad_test() -> Nil {
  // "00=00000" is 8 chars with mid pad -> InvalidCharacter
  assert case yabase.decode("00=00000", using: yabase.Base32Hex) {
    Error(InvalidCharacter("=", _)) -> True
    _ -> False
  }
}

pub fn hex_decode_pure_padding_test() -> Nil {
  assert case yabase.decode("========", using: yabase.Base32Hex) {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

// ===== Crockford =====
// Crockford Base32 treats data as a number, not a byte stream.
// See: https://www.crockford.com/base32.html

pub fn crockford_encode_empty_test() -> Nil {
  assert codec_test_support.encode(<<>>, using: yabase.Base32Crockford) == ""
}

// Spec conformance: numeric value encoding
pub fn crockford_encode_numeric_65_test() -> Nil {
  // <<65>> = numeric 65, 65 = 2*32 + 1 = "21"
  assert codec_test_support.encode(<<65>>, using: yabase.Base32Crockford)
    == "21"
}

pub fn crockford_encode_numeric_0_test() -> Nil {
  // <<0>> = numeric 0
  assert codec_test_support.encode(<<0>>, using: yabase.Base32Crockford) == "0"
}

pub fn crockford_encode_numeric_31_test() -> Nil {
  // <<31>> = numeric 31 = "Z"
  assert codec_test_support.encode(<<31>>, using: yabase.Base32Crockford) == "Z"
}

pub fn crockford_encode_numeric_32_test() -> Nil {
  // <<32>> = numeric 32 = 1*32 + 0 = "10"
  assert codec_test_support.encode(<<32>>, using: yabase.Base32Crockford)
    == "10"
}

pub fn crockford_encode_numeric_1023_test() -> Nil {
  // <<3, 0xFF>> = numeric 1023 = 31*32 + 31 = "ZZ"
  assert codec_test_support.encode(<<3, 255>>, using: yabase.Base32Crockford)
    == "ZZ"
}

pub fn crockford_roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base32Crockford),
      using: yabase.Base32Crockford,
    )
    == Ok(data)
}

pub fn crockford_roundtrip_empty_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<>>, using: yabase.Base32Crockford),
      using: yabase.Base32Crockford,
    )
    == Ok(<<>>)
}

pub fn crockford_roundtrip_single_zero_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<0>>, using: yabase.Base32Crockford),
      using: yabase.Base32Crockford,
    )
    == Ok(<<0>>)
}

pub fn crockford_roundtrip_leading_zeros_test() -> Nil {
  let data = <<0, 0, 42>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base32Crockford),
      using: yabase.Base32Crockford,
    )
    == Ok(data)
}

pub fn crockford_decode_with_hyphens_test() -> Nil {
  // Crockford allows hyphens as separators
  let data = <<"test":utf8>>
  let encoded = codec_test_support.encode(data, using: yabase.Base32Crockford)
  // Insert hyphens into the encoded string
  let with_hyphens =
    string.to_graphemes(encoded)
    |> insert_hyphen_every(4, 0, "")
  assert yabase.decode(with_hyphens, using: yabase.Base32Crockford) == Ok(data)
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
  let encoded = codec_test_support.encode(data, using: yabase.Base32Crockford)
  // Replace any "0" with "O" — should still decode
  let with_o = string.replace(encoded, "0", "O")
  assert yabase.decode(with_o, using: yabase.Base32Crockford) == Ok(data)
}

pub fn crockford_decode_i_l_as_one_test() -> Nil {
  // "I" and "L" should be decoded as "1"
  let data = <<"test":utf8>>
  let encoded = codec_test_support.encode(data, using: yabase.Base32Crockford)
  let with_i = string.replace(encoded, "1", "I")
  assert yabase.decode(with_i, using: yabase.Base32Crockford) == Ok(data)
}

pub fn crockford_decode_case_insensitive_test() -> Nil {
  assert yabase.decode("2a", using: yabase.Base32Crockford)
    == yabase.decode("2A", using: yabase.Base32Crockford)
  assert yabase.decode("zz", using: yabase.Base32Crockford)
    == yabase.decode("ZZ", using: yabase.Base32Crockford)
}

// ===== Crockford check symbol =====

pub fn crockford_check_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base32CrockfordCheck),
      using: yabase.Base32CrockfordCheck,
    )
    == Ok(data)
}

pub fn crockford_check_roundtrip_empty_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<>>, using: yabase.Base32CrockfordCheck),
      using: yabase.Base32CrockfordCheck,
    )
    == Ok(<<>>)
}

pub fn crockford_check_roundtrip_single_byte_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<42>>, using: yabase.Base32CrockfordCheck),
      using: yabase.Base32CrockfordCheck,
    )
    == Ok(<<42>>)
}

pub fn crockford_check_symbol_is_appended_test() -> Nil {
  // encode_check should produce encode output + 1 check character
  let data = <<"test":utf8>>
  let without = codec_test_support.encode(data, using: yabase.Base32Crockford)
  let with = codec_test_support.encode(data, using: yabase.Base32CrockfordCheck)
  assert string.length(with) == string.length(without) + 1
}

pub fn crockford_check_wrong_symbol_test() -> Nil {
  let encoded =
    codec_test_support.encode(
      <<"test":utf8>>,
      using: yabase.Base32CrockfordCheck,
    )
  // Corrupt the check symbol (last char)
  let len = string.length(encoded)
  let body = string.slice(encoded, 0, len - 1)
  let corrupted = body <> "*"
  // If the original check was not *, this should fail
  case string.slice(encoded, len - 1, 1) == "*" {
    True -> {
      // Original check was *, pick a different corruption
      assert yabase.decode(body <> "~", using: yabase.Base32CrockfordCheck)
        == Error(InvalidChecksum)
    }
    False -> {
      assert yabase.decode(corrupted, using: yabase.Base32CrockfordCheck)
        == Error(InvalidChecksum)
    }
  }
}

pub fn crockford_check_extended_symbols_test() -> Nil {
  // Values 32-36 map to *~$=U; test that these round-trip
  // Find data whose mod 37 hits each extended symbol
  // 32 = *, 33 = ~, 34 = $, 35 = =, 36 = U
  assert yabase.decode(
      codec_test_support.encode(<<32>>, using: yabase.Base32CrockfordCheck),
      using: yabase.Base32CrockfordCheck,
    )
    == Ok(<<32>>)
  assert yabase.decode(
      codec_test_support.encode(<<33>>, using: yabase.Base32CrockfordCheck),
      using: yabase.Base32CrockfordCheck,
    )
    == Ok(<<33>>)
  assert yabase.decode(
      codec_test_support.encode(<<34>>, using: yabase.Base32CrockfordCheck),
      using: yabase.Base32CrockfordCheck,
    )
    == Ok(<<34>>)
  assert yabase.decode(
      codec_test_support.encode(<<35>>, using: yabase.Base32CrockfordCheck),
      using: yabase.Base32CrockfordCheck,
    )
    == Ok(<<35>>)
  assert yabase.decode(
      codec_test_support.encode(<<36>>, using: yabase.Base32CrockfordCheck),
      using: yabase.Base32CrockfordCheck,
    )
    == Ok(<<36>>)
}

pub fn crockford_check_empty_input_decode_test() -> Nil {
  // Decoding a single character = just a check symbol, body is empty
  assert yabase.decode("0", using: yabase.Base32CrockfordCheck) == Ok(<<>>)
}

// ===== Clockwork =====

pub fn clockwork_encode_empty_test() -> Nil {
  assert codec_test_support.encode(<<>>, using: yabase.Base32Clockwork) == ""
}

pub fn clockwork_roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base32Clockwork),
      using: yabase.Base32Clockwork,
    )
    == Ok(data)
}

pub fn clockwork_roundtrip_empty_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<>>, using: yabase.Base32Clockwork),
      using: yabase.Base32Clockwork,
    )
    == Ok(<<>>)
}

pub fn clockwork_roundtrip_single_zero_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<0>>, using: yabase.Base32Clockwork),
      using: yabase.Base32Clockwork,
    )
    == Ok(<<0>>)
}

pub fn clockwork_decode_lowercase_test() -> Nil {
  let data = <<"test":utf8>>
  let encoded = codec_test_support.encode(data, using: yabase.Base32Clockwork)
  // lowercase should also decode
  assert yabase.decode(string.lowercase(encoded), using: yabase.Base32Clockwork)
    == Ok(data)
}

pub fn clockwork_decode_o_as_zero_test() -> Nil {
  let data = <<"test":utf8>>
  let encoded = codec_test_support.encode(data, using: yabase.Base32Clockwork)
  let with_o = string.replace(encoded, "0", "O")
  assert yabase.decode(with_o, using: yabase.Base32Clockwork) == Ok(data)
}

pub fn clockwork_decode_i_l_as_one_test() -> Nil {
  let data = <<"test":utf8>>
  let encoded = codec_test_support.encode(data, using: yabase.Base32Clockwork)
  let with_l = string.replace(encoded, "1", "L")
  assert yabase.decode(with_l, using: yabase.Base32Clockwork) == Ok(data)
}

// ===== rfc4648.decode_strict (RFC 4648 §3.5 canonical-encoding) =====

pub fn rfc4648_decode_strict_canonical_passes_test() -> Nil {
  // Canonical encoding of "f" is "MY======" — pad bits zero.
  assert yabase.decode_base32_strict("MY======") == Ok(<<"f":utf8>>)
}

pub fn rfc4648_decode_strict_non_canonical_rejected_test() -> Nil {
  // Non-canonical: "MB======" decodes to a one-byte value but the
  // last alphabet character ('B') has non-zero bits in the
  // pad-bit positions. Canonical for one byte uses only A/I/Q/Y as
  // the second character (depending on first), making the trailing
  // 2 bits zero.
  assert yabase.decode_base32_strict("MB======") == Error(NonCanonical)
}

pub fn rfc4648_decode_strict_full_block_passes_test() -> Nil {
  // Full-block encodings have no pad bits to non-canonicalise.
  assert yabase.decode_base32_strict("MZXW6YTBOI======")
    == Ok(<<"foobar":utf8>>)
}

pub fn rfc4648_decode_strict_lowercase_rejected_test() -> Nil {
  // Per RFC 4648 §3.5/§6, the canonical form is uppercase. A strict
  // decoder MUST reject lowercase input, even though the lenient
  // `decode/1` accepts it. Closes the security gap where two distinct
  // wire forms ("MY======" and "my======") would both validate as
  // canonical for the same bytes — exactly the replay-attack surface
  // strict decoders exist to close.
  assert yabase.decode_base32_strict("my======") == Error(NonCanonical)
}

pub fn rfc4648_decode_strict_mixed_case_rejected_test() -> Nil {
  // Mixed case is also non-canonical.
  assert yabase.decode_base32_strict("My======") == Error(NonCanonical)
}

pub fn rfc4648_decode_strict_missing_padding_rejected_test() -> Nil {
  // Canonical form for "f" is "MY======" with full padding to 8
  // chars. The unpadded form "MY" is accepted by lenient `decode/1`
  // but is non-canonical for the strict path.
  assert yabase.decode_base32_strict("MY") == Error(NonCanonical)
}

// One or nine data characters leave five bits, less than a byte.
pub fn rfc4648_decode_rejects_a_lone_data_character_before_padding_test() -> Nil {
  assert yabase.decode("A=======", using: yabase.Base32Rfc4648)
    == Error(InvalidLength(8))
  assert yabase.decode("AAAAAAAAA=======", using: yabase.Base32Rfc4648)
    == Error(InvalidLength(16))
}
