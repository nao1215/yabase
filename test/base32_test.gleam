import gleam/string
import yabase/base32/clockwork
import yabase/base32/crockford
import yabase/base32/hex as base32_hex
import yabase/base32/rfc4648
import yabase/core/encoding.{InvalidCharacter, InvalidLength}

// ===== RFC4648 =====

// --- Fixed vectors (RFC 4648 section 10) ---

pub fn rfc4648_encode_empty_test() {
  assert rfc4648.encode(<<>>) == ""
}

pub fn rfc4648_encode_f_test() {
  assert rfc4648.encode(<<"f":utf8>>) == "MY======"
}

pub fn rfc4648_encode_fo_test() {
  assert rfc4648.encode(<<"fo":utf8>>) == "MZXQ===="
}

pub fn rfc4648_encode_foo_test() {
  assert rfc4648.encode(<<"foo":utf8>>) == "MZXW6==="
}

pub fn rfc4648_encode_foob_test() {
  assert rfc4648.encode(<<"foob":utf8>>) == "MZXW6YQ="
}

pub fn rfc4648_encode_fooba_test() {
  assert rfc4648.encode(<<"fooba":utf8>>) == "MZXW6YTB"
}

pub fn rfc4648_encode_foobar_test() {
  assert rfc4648.encode(<<"foobar":utf8>>) == "MZXW6YTBOI======"
}

pub fn rfc4648_decode_empty_test() {
  assert rfc4648.decode("") == Ok(<<>>)
}

pub fn rfc4648_decode_f_test() {
  assert rfc4648.decode("MY======") == Ok(<<"f":utf8>>)
}

pub fn rfc4648_decode_foobar_test() {
  assert rfc4648.decode("MZXW6YTBOI======") == Ok(<<"foobar":utf8>>)
}

// --- Decode errors ---

pub fn rfc4648_decode_invalid_char_test() {
  assert rfc4648.decode("M1======") == Error(InvalidCharacter("1", 1))
}

pub fn rfc4648_decode_leading_pad_test() {
  // "=MY=====" has padding before data -> must fail
  assert case rfc4648.decode("=MY=====") {
    Error(InvalidCharacter("=", _)) -> True
    _ -> False
  }
}

pub fn rfc4648_decode_mid_pad_test() {
  // "M=Y=====" has padding in the middle -> must fail
  assert case rfc4648.decode("M=Y=====") {
    Error(InvalidCharacter("=", _)) -> True
    _ -> False
  }
}

pub fn rfc4648_decode_excess_pad_test() {
  // More padding than 8 chars -> must fail
  assert case rfc4648.decode("MY=======") {
    Error(_) -> True
    _ -> False
  }
}

pub fn rfc4648_decode_pure_padding_test() {
  // "========" is all padding, no data characters -> must fail
  assert case rfc4648.decode("========") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

// --- Roundtrip corpus ---

pub fn rfc4648_roundtrip_test() {
  let data = <<"Hello, World!":utf8>>
  assert rfc4648.decode(rfc4648.encode(data)) == Ok(data)
}

pub fn rfc4648_roundtrip_empty_test() {
  assert rfc4648.decode(rfc4648.encode(<<>>)) == Ok(<<>>)
}

pub fn rfc4648_roundtrip_single_zero_test() {
  assert rfc4648.decode(rfc4648.encode(<<0>>)) == Ok(<<0>>)
}

pub fn rfc4648_roundtrip_leading_zeros_test() {
  let data = <<0, 0, 0, 42>>
  assert rfc4648.decode(rfc4648.encode(data)) == Ok(data)
}

pub fn rfc4648_roundtrip_all_zeros_test() {
  let data = <<0, 0, 0, 0>>
  assert rfc4648.decode(rfc4648.encode(data)) == Ok(data)
}

pub fn rfc4648_roundtrip_high_bits_test() {
  let data = <<0xff, 0x80, 0x7f>>
  assert rfc4648.decode(rfc4648.encode(data)) == Ok(data)
}

// ===== Hex =====

pub fn hex_encode_empty_test() {
  assert base32_hex.encode(<<>>) == ""
}

pub fn hex_encode_foo_test() {
  assert base32_hex.encode(<<"foo":utf8>>) == "CPNMU==="
}

pub fn hex_roundtrip_test() {
  let data = <<"Hello, World!":utf8>>
  assert base32_hex.decode(base32_hex.encode(data)) == Ok(data)
}

pub fn hex_roundtrip_empty_test() {
  assert base32_hex.decode(base32_hex.encode(<<>>)) == Ok(<<>>)
}

pub fn hex_roundtrip_single_zero_test() {
  assert base32_hex.decode(base32_hex.encode(<<0>>)) == Ok(<<0>>)
}

pub fn hex_decode_leading_pad_test() {
  // "=0000000" is 8 chars with leading pad -> InvalidCharacter
  assert case base32_hex.decode("=0000000") {
    Error(InvalidCharacter("=", _)) -> True
    _ -> False
  }
}

pub fn hex_decode_mid_pad_test() {
  // "00=00000" is 8 chars with mid pad -> InvalidCharacter
  assert case base32_hex.decode("00=00000") {
    Error(InvalidCharacter("=", _)) -> True
    _ -> False
  }
}

pub fn hex_decode_pure_padding_test() {
  assert case base32_hex.decode("========") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

// ===== Crockford =====

pub fn crockford_encode_empty_test() {
  assert crockford.encode(<<>>) == ""
}

pub fn crockford_roundtrip_test() {
  let data = <<"Hello, World!":utf8>>
  assert crockford.decode(crockford.encode(data)) == Ok(data)
}

pub fn crockford_roundtrip_empty_test() {
  assert crockford.decode(crockford.encode(<<>>)) == Ok(<<>>)
}

pub fn crockford_roundtrip_single_zero_test() {
  assert crockford.decode(crockford.encode(<<0>>)) == Ok(<<0>>)
}

pub fn crockford_decode_with_hyphens_test() {
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
  chars: List(String),
  every: Int,
  count: Int,
  acc: String,
) -> String {
  case chars {
    [] -> acc
    [c, ..rest] -> {
      let new_count = count + 1
      let sep = case new_count % every == 0 && rest != [] {
        True -> "-"
        False -> ""
      }
      insert_hyphen_every(rest, every, new_count, acc <> c <> sep)
    }
  }
}

pub fn crockford_decode_o_as_zero_test() {
  // "O" should be decoded as "0"
  let data = <<"test":utf8>>
  let encoded = crockford.encode(data)
  // Replace any "0" with "O" — should still decode
  let with_o = string.replace(encoded, "0", "O")
  assert crockford.decode(with_o) == Ok(data)
}

pub fn crockford_decode_i_l_as_one_test() {
  // "I" and "L" should be decoded as "1"
  let data = <<"test":utf8>>
  let encoded = crockford.encode(data)
  let with_i = string.replace(encoded, "1", "I")
  assert crockford.decode(with_i) == Ok(data)
}

// ===== Clockwork =====

pub fn clockwork_encode_empty_test() {
  assert clockwork.encode(<<>>) == ""
}

pub fn clockwork_roundtrip_test() {
  let data = <<"Hello, World!":utf8>>
  assert clockwork.decode(clockwork.encode(data)) == Ok(data)
}

pub fn clockwork_roundtrip_empty_test() {
  assert clockwork.decode(clockwork.encode(<<>>)) == Ok(<<>>)
}

pub fn clockwork_roundtrip_single_zero_test() {
  assert clockwork.decode(clockwork.encode(<<0>>)) == Ok(<<0>>)
}

pub fn clockwork_decode_lowercase_test() {
  let data = <<"test":utf8>>
  let encoded = clockwork.encode(data)
  // lowercase should also decode
  assert clockwork.decode(string.lowercase(encoded)) == Ok(data)
}

pub fn clockwork_decode_o_as_zero_test() {
  let data = <<"test":utf8>>
  let encoded = clockwork.encode(data)
  let with_o = string.replace(encoded, "0", "O")
  assert clockwork.decode(with_o) == Ok(data)
}

pub fn clockwork_decode_i_l_as_one_test() {
  let data = <<"test":utf8>>
  let encoded = clockwork.encode(data)
  let with_l = string.replace(encoded, "1", "L")
  assert clockwork.decode(with_l) == Ok(data)
}
