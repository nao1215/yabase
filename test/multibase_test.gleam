import gleam/result
import gleam/string
import yabase.{
  InvalidCharacter, InvalidLength, UnsupportedMultibaseEncoding,
  UnsupportedPrefix,
}

// ===== Official multibase registry vectors =====

pub fn registry_0_base2_test() -> Nil {
  let data = <<"Hi":utf8>>
  let assert Ok(encoded) = yabase.encode_multibase(data, using: yabase.Base2)
  assert encoded == "00100100001101001"
  let assert Ok(decoded) =
    yabase.decode_multibase(encoded) |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

pub fn registry_7_base8_test() -> Nil {
  let data = <<"Hi":utf8>>
  let assert Ok(encoded) = yabase.encode_multibase(data, using: yabase.Base8)
  assert case encoded {
    "7" <> _ -> True
    _ -> False
  }
  let assert Ok(decoded) =
    yabase.decode_multibase(encoded) |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

pub fn registry_9_base10_test() -> Nil {
  let data = <<"Hi":utf8>>
  let assert Ok(encoded) = yabase.encode_multibase(data, using: yabase.Base10)
  assert case encoded {
    "9" <> _ -> True
    _ -> False
  }
  let assert Ok(decoded) =
    yabase.decode_multibase(encoded) |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

pub fn registry_f_base16_test() -> Nil {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) = yabase.encode_multibase(data, using: yabase.Base16)
  assert encoded == "f796573206d616e692021"
  let assert Ok(decoded) =
    yabase.decode_multibase(encoded) |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

pub fn registry_upper_f_base16_decode_test() -> Nil {
  let assert Ok(decoded) =
    yabase.decode_multibase("F796573206D616E692021")
    |> result.map(fn(decoded) { decoded.data })
  assert decoded == <<"yes mani !":utf8>>
}

pub fn registry_c_base32pad_test() -> Nil {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) =
    yabase.encode_multibase(data, using: yabase.Base32Rfc4648)
  assert case encoded {
    "c" <> _ -> True
    _ -> False
  }
  let assert Ok(decoded) =
    yabase.decode_multibase(encoded) |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

pub fn registry_t_base32hexpad_test() -> Nil {
  let data = <<"test":utf8>>
  let assert Ok(encoded) =
    yabase.encode_multibase(data, using: yabase.Base32Hex)
  assert case encoded {
    "t" <> _ -> True
    _ -> False
  }
  let assert Ok(decoded) =
    yabase.decode_multibase(encoded) |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

pub fn registry_h_base32z_test() -> Nil {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) = yabase.encode_multibase(data, using: yabase.Zbase32)
  assert case encoded {
    "h" <> _ -> True
    _ -> False
  }
  let assert Ok(decoded) =
    yabase.decode_multibase(encoded) |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

pub fn registry_k_base36_test() -> Nil {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) = yabase.encode_multibase(data, using: yabase.Base36)
  assert case encoded {
    "k" <> _ -> True
    _ -> False
  }
  let assert Ok(decoded) =
    yabase.decode_multibase(encoded) |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

pub fn registry_z_base58btc_test() -> Nil {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) =
    yabase.encode_multibase(data, using: yabase.Base58Bitcoin)
  assert case encoded {
    "z" <> _ -> True
    _ -> False
  }
  let assert Ok(decoded) =
    yabase.decode_multibase(encoded) |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

pub fn registry_upper_z_base58flickr_test() -> Nil {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) =
    yabase.encode_multibase(data, using: yabase.Base58Flickr)
  assert case encoded {
    "Z" <> _ -> True
    _ -> False
  }
  let assert Ok(decoded) =
    yabase.decode_multibase(encoded) |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

pub fn registry_upper_m_base64pad_test() -> Nil {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) = yabase.encode_multibase(data, using: yabase.Base64)
  assert encoded == "MeWVzIG1hbmkgIQ=="
  let assert Ok(decoded) =
    yabase.decode_multibase(encoded) |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

pub fn registry_lower_m_base64_test() -> Nil {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) =
    yabase.encode_multibase(data, using: yabase.Base64NoPadding)
  assert encoded == "meWVzIG1hbmkgIQ"
  let assert Ok(decoded) =
    yabase.decode_multibase(encoded) |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

pub fn registry_upper_u_base64urlpad_test() -> Nil {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) =
    yabase.encode_multibase(data, using: yabase.Base64UrlSafe)
  assert case encoded {
    "U" <> _ -> True
    _ -> False
  }
  let assert Ok(decoded) =
    yabase.decode_multibase(encoded) |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

pub fn registry_lower_u_base64url_nopad_test() -> Nil {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) =
    yabase.encode_multibase(data, using: yabase.Base64UrlSafeNoPadding)
  assert case encoded {
    "u" <> _ -> True
    _ -> False
  }
  let assert Ok(decoded) =
    yabase.decode_multibase(encoded) |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

// ===== Unsupported encodings =====

pub fn crockford_unsupported_test() -> Nil {
  assert case
    yabase.encode_multibase(<<"x":utf8>>, using: yabase.Base32Crockford)
  {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn clockwork_unsupported_test() -> Nil {
  assert case
    yabase.encode_multibase(<<"x":utf8>>, using: yabase.Base32Clockwork)
  {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn registry_upper_r_base45_test() -> Nil {
  let data = <<"AB":utf8>>
  let assert Ok(encoded) = yabase.encode_multibase(data, using: yabase.Base45)
  assert case encoded {
    "R" <> _ -> True
    _ -> False
  }
  let assert Ok(decoded) =
    yabase.decode_multibase(encoded) |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

pub fn registry_upper_b_base32upper_decode_test() -> Nil {
  let assert Ok(decoded) =
    yabase.decode_multibase("BMY") |> result.map(fn(decoded) { decoded.data })
  assert decoded == <<"f":utf8>>
}

pub fn base62_unsupported_test() -> Nil {
  assert case yabase.encode_multibase(<<"x":utf8>>, using: yabase.Base62) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn base91_unsupported_test() -> Nil {
  assert case yabase.encode_multibase(<<"x":utf8>>, using: yabase.Base91) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn base85_btoa_unsupported_test() -> Nil {
  assert case yabase.encode_multibase(<<"x":utf8>>, using: yabase.Ascii85) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn base85_adobe_unsupported_test() -> Nil {
  assert case
    yabase.encode_multibase(<<"x":utf8>>, using: yabase.AdobeAscii85)
  {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn base85_rfc1924_unsupported_test() -> Nil {
  assert case
    yabase.encode_multibase(<<1, 2, 3, 4>>, using: yabase.Rfc1924Base85)
  {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn base85_z85_unsupported_test() -> Nil {
  assert case yabase.encode_multibase(<<1, 2, 3, 4>>, using: yabase.Z85) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn dq_unsupported_test() -> Nil {
  assert case yabase.encode_multibase(<<"x":utf8>>, using: yabase.Base64Dq) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

// ===== Decode error cases =====

pub fn decode_unsupported_prefix_test() -> Nil {
  assert yabase.decode_multibase("!invalid") == Error(UnsupportedPrefix("!"))
}

pub fn decode_empty_test() -> Nil {
  assert yabase.decode_multibase("") == Error(UnsupportedPrefix(""))
}

pub fn decode_bytes_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  let assert Ok(encoded) =
    yabase.encode_multibase(data, using: yabase.Base32Rfc4648)
  assert yabase.decode_multibase(encoded)
    |> result.map(fn(decoded) { decoded.data })
    == Ok(data)
}

// ===== No-padding rejection through multibase wrapper =====

pub fn multibase_m_rejects_padded_input_test() -> Nil {
  // m = base64 no-padding; "mZg==" has padding and must be rejected
  assert case yabase.decode_multibase("mZg==") {
    Error(InvalidCharacter("=", _)) -> True
    _ -> False
  }
}

pub fn multibase_u_rejects_padded_input_test() -> Nil {
  // u = base64url no-padding; "uZg==" has padding and must be rejected
  assert case yabase.decode_multibase("uZg==") {
    Error(InvalidCharacter("=", _)) -> True
    _ -> False
  }
}

// ===== Decode alias prefix regression =====
// encode_with_prefix emits canonical prefixes only;
// these test that non-canonical alias prefixes decode correctly.

// base32pad (c) decoder accepts unpadded input (RFC 4648 decoder flexibility)
pub fn decode_base32pad_accepts_unpadded_test() -> Nil {
  let data = <<"f":utf8>>
  // "cMY======" is canonical padded; "cMY" is unpadded
  let assert Ok(decoded) =
    yabase.decode_multibase("cMY") |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

pub fn decode_base32hexpad_accepts_unpadded_test() -> Nil {
  let data = <<"f":utf8>>
  // "tCO======" is canonical padded; "tCO" is unpadded
  let assert Ok(decoded) =
    yabase.decode_multibase("tCO") |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

pub fn decode_alias_upper_c_base32pad_test() -> Nil {
  // C = base32pad (uppercase); encode emits c
  let data = <<"Hi":utf8>>
  let assert Ok(canonical) =
    yabase.encode_multibase(data, using: yabase.Base32Rfc4648)
  // Replace lowercase c prefix with uppercase C
  let alias_encoded = "C" <> string.drop_start(canonical, 1)
  let assert Ok(decoded) =
    yabase.decode_multibase(alias_encoded)
    |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

pub fn decode_alias_lowercase_b_base32_nopad_test() -> Nil {
  // b = base32 no-padding (lowercase); maps to RFC4648 codec
  let assert Ok(decoded) =
    yabase.decode_multibase("bMY") |> result.map(fn(decoded) { decoded.data })
  assert decoded == <<"f":utf8>>
}

pub fn decode_alias_upper_t_base32hexpad_test() -> Nil {
  // T = base32hexpad (uppercase); encode emits t
  let data = <<"Hi":utf8>>
  let assert Ok(canonical) =
    yabase.encode_multibase(data, using: yabase.Base32Hex)
  let alias_encoded = "T" <> string.drop_start(canonical, 1)
  let assert Ok(decoded) =
    yabase.decode_multibase(alias_encoded)
    |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

pub fn decode_alias_lowercase_v_base32hex_nopad_test() -> Nil {
  // v = base32hex no-padding; maps to Hex codec
  let data = <<"Hi":utf8>>
  let assert Ok(canonical) =
    yabase.encode_multibase(data, using: yabase.Base32Hex)
  // Strip t prefix, strip trailing padding, prepend v
  let body = string.drop_start(canonical, 1) |> string.replace("=", "")
  let alias_encoded = "v" <> body
  let assert Ok(decoded) =
    yabase.decode_multibase(alias_encoded)
    |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

pub fn decode_alias_upper_v_base32hex_nopad_test() -> Nil {
  let data = <<"Hi":utf8>>
  let assert Ok(canonical) =
    yabase.encode_multibase(data, using: yabase.Base32Hex)
  let body = string.drop_start(canonical, 1) |> string.replace("=", "")
  let alias_encoded = "V" <> body
  let assert Ok(decoded) =
    yabase.decode_multibase(alias_encoded)
    |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

pub fn decode_alias_upper_k_base36_test() -> Nil {
  // K = base36 (uppercase); encode emits k
  let data = <<"Hi":utf8>>
  let assert Ok(canonical) = yabase.encode_multibase(data, using: yabase.Base36)
  let alias_encoded = "K" <> string.drop_start(canonical, 1)
  let assert Ok(decoded) =
    yabase.decode_multibase(alias_encoded)
    |> result.map(fn(decoded) { decoded.data })
  assert decoded == data
}

// ===== multiformats/multibase spec vectors =====
// Source: https://github.com/multiformats/multibase/tree/master/tests

// basic.csv: "yes mani !"
pub fn spec_basic_base16_test() -> Nil {
  let data = <<"yes mani !":utf8>>
  let assert Ok(d) =
    yabase.decode_multibase("f796573206d616e692021")
    |> result.map(fn(decoded) { decoded.data })
  assert d == data
}

pub fn spec_basic_base32pad_test() -> Nil {
  let data = <<"yes mani !":utf8>>
  let assert Ok(d) =
    yabase.decode_multibase("cpfsxgidnmfxgsibb")
    |> result.map(fn(decoded) { decoded.data })
  assert d == data
}

pub fn spec_basic_base32z_test() -> Nil {
  let data = <<"yes mani !":utf8>>
  let assert Ok(d) =
    yabase.decode_multibase("hxf1zgedpcfzg1ebb")
    |> result.map(fn(decoded) { decoded.data })
  assert d == data
}

pub fn spec_basic_base36_test() -> Nil {
  let data = <<"yes mani !":utf8>>
  let assert Ok(d) =
    yabase.decode_multibase("k2lcpzo5yikidynfl")
    |> result.map(fn(decoded) { decoded.data })
  assert d == data
}

pub fn spec_basic_base58btc_test() -> Nil {
  let data = <<"yes mani !":utf8>>
  let assert Ok(d) =
    yabase.decode_multibase("z7paNL19xttacUY")
    |> result.map(fn(decoded) { decoded.data })
  assert d == data
}

pub fn spec_basic_base58flickr_test() -> Nil {
  let data = <<"yes mani !":utf8>>
  let assert Ok(d) =
    yabase.decode_multibase("Z7Pznk19XTTzBtx")
    |> result.map(fn(decoded) { decoded.data })
  assert d == data
}

pub fn spec_basic_base64_test() -> Nil {
  let data = <<"yes mani !":utf8>>
  let assert Ok(d) =
    yabase.decode_multibase("meWVzIG1hbmkgIQ")
    |> result.map(fn(decoded) { decoded.data })
  assert d == data
}

pub fn spec_basic_base64pad_test() -> Nil {
  let data = <<"yes mani !":utf8>>
  let assert Ok(d) =
    yabase.decode_multibase("MeWVzIG1hbmkgIQ==")
    |> result.map(fn(decoded) { decoded.data })
  assert d == data
}

pub fn spec_basic_base64url_test() -> Nil {
  let data = <<"yes mani !":utf8>>
  let assert Ok(d) =
    yabase.decode_multibase("ueWVzIG1hbmkgIQ")
    |> result.map(fn(decoded) { decoded.data })
  assert d == data
}

pub fn spec_basic_base64urlpad_test() -> Nil {
  let data = <<"yes mani !":utf8>>
  let assert Ok(d) =
    yabase.decode_multibase("UeWVzIG1hbmkgIQ==")
    |> result.map(fn(decoded) { decoded.data })
  assert d == data
}

// leading_zero.csv: "\x00yes mani !"
pub fn spec_leading_zero_base16_test() -> Nil {
  let data = <<0, "yes mani !":utf8>>
  let assert Ok(d) =
    yabase.decode_multibase("f00796573206d616e692021")
    |> result.map(fn(decoded) { decoded.data })
  assert d == data
}

pub fn spec_leading_zero_base36_test() -> Nil {
  let data = <<0, "yes mani !":utf8>>
  let assert Ok(d) =
    yabase.decode_multibase("k02lcpzo5yikidynfl")
    |> result.map(fn(decoded) { decoded.data })
  assert d == data
}

pub fn spec_leading_zero_base58btc_test() -> Nil {
  let data = <<0, "yes mani !":utf8>>
  let assert Ok(d) =
    yabase.decode_multibase("z17paNL19xttacUY")
    |> result.map(fn(decoded) { decoded.data })
  assert d == data
}

pub fn spec_leading_zero_base58flickr_test() -> Nil {
  let data = <<0, "yes mani !":utf8>>
  let assert Ok(d) =
    yabase.decode_multibase("Z17Pznk19XTTzBtx")
    |> result.map(fn(decoded) { decoded.data })
  assert d == data
}

pub fn spec_leading_zero_base64pad_test() -> Nil {
  let data = <<0, "yes mani !":utf8>>
  let assert Ok(d) =
    yabase.decode_multibase("MAHllcyBtYW5pICE=")
    |> result.map(fn(decoded) { decoded.data })
  assert d == data
}

// two_leading_zeros.csv: "\x00\x00yes mani !"
pub fn spec_two_leading_zeros_base16_test() -> Nil {
  let data = <<0, 0, "yes mani !":utf8>>
  let assert Ok(d) =
    yabase.decode_multibase("f0000796573206d616e692021")
    |> result.map(fn(decoded) { decoded.data })
  assert d == data
}

pub fn spec_two_leading_zeros_base58btc_test() -> Nil {
  let data = <<0, 0, "yes mani !":utf8>>
  let assert Ok(d) =
    yabase.decode_multibase("z117paNL19xttacUY")
    |> result.map(fn(decoded) { decoded.data })
  assert d == data
}

pub fn spec_two_leading_zeros_base36_test() -> Nil {
  let data = <<0, 0, "yes mani !":utf8>>
  let assert Ok(d) =
    yabase.decode_multibase("k002lcpzo5yikidynfl")
    |> result.map(fn(decoded) { decoded.data })
  assert d == data
}

// basic.csv encode side: base8 is RFC 4648-style 3-bit groups, and the
// lowercase base32 prefixes carry a lowercase payload.
pub fn spec_basic_base8_encode_test() -> Nil {
  assert yabase.encode_multibase(<<"yes mani !":utf8>>, using: yabase.Base8)
    == Ok("7362625631006654133464440102")
}

pub fn spec_basic_base8_decode_test() -> Nil {
  assert yabase.decode_multibase("7362625631006654133464440102")
    |> result.map(fn(decoded) { decoded.data })
    == Ok(<<"yes mani !":utf8>>)
}

pub fn spec_leading_zero_base8_test() -> Nil {
  assert yabase.encode_multibase(<<0, "yes mani !":utf8>>, using: yabase.Base8)
    == Ok("7000745453462015530267151100204")
  assert yabase.decode_multibase("7000745453462015530267151100204")
    |> result.map(fn(decoded) { decoded.data })
    == Ok(<<0, "yes mani !":utf8>>)
}

pub fn multibase_base8_rejects_dangling_digit_test() -> Nil {
  // 4 digits hold 12 bits: one byte plus 4 bits, more than the 3-bit
  // remainder a real encoding can leave.
  assert yabase.decode_multibase("71234")
    |> result.map(fn(decoded) { decoded.data })
    == Error(InvalidLength(4))
}

pub fn standalone_base8_keeps_number_shape_test() -> Nil {
  // Only the multibase prefix "7" uses 3-bit groups; yabase/base8 and
  // encoding.encode keep treating the input as one number.
  assert yabase.encode(<<"yes mani !":utf8>>, using: yabase.Base8)
    == Ok("171312714403326055632220041")
}

pub fn spec_basic_base32pad_encode_test() -> Nil {
  assert yabase.encode_multibase(
      <<
        "yes mani !":utf8,
      >>,
      using: yabase.Base32Rfc4648,
    )
    == Ok("cpfsxgidnmfxgsibb")
}

pub fn spec_basic_base32hexpad_encode_test() -> Nil {
  assert yabase.encode_multibase(
      <<
        "yes mani !":utf8,
      >>,
      using: yabase.Base32Hex,
    )
    == Ok("tf5in683dc5n6i811")
}

pub fn multibase_decoded_base8_reports_base8_test() -> Nil {
  let assert Ok(decoded) =
    yabase.decode_multibase("7362625631006654133464440102")
  assert { decoded }.encoding == yabase.Base8
  assert { decoded }.data == <<"yes mani !":utf8>>
}
