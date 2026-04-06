import yabase/core/encoding.{
  AdobeAscii85, Ascii85, Base16, Base32, Base36, Base45, Base58, Base62, Base64,
  Base91, Clockwork, Crockford, Decoded, Hex, NoPadding, RFC4648, Rfc1924Base85,
  Standard, UnsupportedMultibaseEncoding, UnsupportedPrefix, UrlSafe,
  UrlSafeNoPadding, Z85, ZBase32,
}
import yabase/core/multibase

// ===== Official multibase registry vectors =====
// Prefix assignments from:
// https://github.com/multiformats/multibase/blob/master/multibase.csv

// f = base16 (lowercase)
pub fn registry_f_base16_test() {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) = multibase.encode_with_prefix(Base16, data)
  assert encoded == "f796573206d616e692021"
  let assert Ok(Decoded(encoding: Base16, data: decoded)) =
    multibase.decode(encoded)
  assert decoded == data
}

// F = BASE16 (uppercase decode)
pub fn registry_upper_f_base16_decode_test() {
  let assert Ok(Decoded(encoding: Base16, data: decoded)) =
    multibase.decode("F796573206D616E692021")
  assert decoded == <<"yes mani !":utf8>>
}

// c = base32pad (lowercase, padded)
pub fn registry_c_base32pad_test() {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) = multibase.encode_with_prefix(Base32(RFC4648), data)
  assert case encoded {
    "c" <> _ -> True
    _ -> False
  }
  let assert Ok(Decoded(encoding: Base32(RFC4648), data: decoded)) =
    multibase.decode(encoded)
  assert decoded == data
}

// t = base32hexpad (lowercase, padded)
pub fn registry_t_base32hexpad_test() {
  let data = <<"test":utf8>>
  let assert Ok(encoded) = multibase.encode_with_prefix(Base32(Hex), data)
  assert case encoded {
    "t" <> _ -> True
    _ -> False
  }
  let assert Ok(Decoded(encoding: Base32(Hex), data: decoded)) =
    multibase.decode(encoded)
  assert decoded == data
}

// h = base32z (z-base-32)
pub fn registry_h_base32z_test() {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) = multibase.encode_with_prefix(Base32(ZBase32), data)
  assert case encoded {
    "h" <> _ -> True
    _ -> False
  }
  let assert Ok(Decoded(encoding: Base32(ZBase32), data: decoded)) =
    multibase.decode(encoded)
  assert decoded == data
}

// k = base36 (lowercase)
pub fn registry_k_base36_test() {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) = multibase.encode_with_prefix(Base36, data)
  assert case encoded {
    "k" <> _ -> True
    _ -> False
  }
  let assert Ok(Decoded(encoding: Base36, data: decoded)) =
    multibase.decode(encoded)
  assert decoded == data
}

// z = base58btc
pub fn registry_z_base58btc_test() {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) = multibase.encode_with_prefix(Base58, data)
  assert case encoded {
    "z" <> _ -> True
    _ -> False
  }
  let assert Ok(Decoded(encoding: Base58, data: decoded)) =
    multibase.decode(encoded)
  assert decoded == data
}

// M = base64pad (with padding)
pub fn registry_upper_m_base64pad_test() {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) = multibase.encode_with_prefix(Base64(Standard), data)
  assert encoded == "MeWVzIG1hbmkgIQ=="
  let assert Ok(Decoded(encoding: Base64(Standard), data: decoded)) =
    multibase.decode(encoded)
  assert decoded == data
}

// m = base64 (no padding)
pub fn registry_lower_m_base64_test() {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) = multibase.encode_with_prefix(Base64(NoPadding), data)
  assert encoded == "meWVzIG1hbmkgIQ"
  let assert Ok(Decoded(encoding: Base64(NoPadding), data: decoded)) =
    multibase.decode(encoded)
  assert decoded == data
}

// U = base64urlpad (with padding)
pub fn registry_upper_u_base64urlpad_test() {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) = multibase.encode_with_prefix(Base64(UrlSafe), data)
  assert case encoded {
    "U" <> _ -> True
    _ -> False
  }
  let assert Ok(Decoded(encoding: Base64(UrlSafe), data: decoded)) =
    multibase.decode(encoded)
  assert decoded == data
}

// u = base64url (no padding)
pub fn registry_lower_u_base64url_nopad_test() {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) =
    multibase.encode_with_prefix(Base64(UrlSafeNoPadding), data)
  assert case encoded {
    "u" <> _ -> True
    _ -> False
  }
  let assert Ok(Decoded(encoding: Base64(UrlSafeNoPadding), data: decoded)) =
    multibase.decode(encoded)
  assert decoded == data
}

// ===== Unsupported encodings =====

pub fn crockford_unsupported_test() {
  assert case multibase.encode_with_prefix(Base32(Crockford), <<"x":utf8>>) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn clockwork_unsupported_test() {
  assert case multibase.encode_with_prefix(Base32(Clockwork), <<"x":utf8>>) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

// R = base45
pub fn registry_upper_r_base45_test() {
  let data = <<"AB":utf8>>
  let assert Ok(encoded) = multibase.encode_with_prefix(Base45, data)
  assert case encoded {
    "R" <> _ -> True
    _ -> False
  }
  let assert Ok(Decoded(encoding: Base45, data: decoded)) =
    multibase.decode(encoded)
  assert decoded == data
}

// B = base32upper (no padding) -> same codec as RFC4648
pub fn registry_upper_b_base32upper_decode_test() {
  // B prefix followed by base32 encoded "f" without padding
  let assert Ok(Decoded(encoding: Base32(RFC4648), data: decoded)) =
    multibase.decode("BMY")
  assert decoded == <<"f":utf8>>
}

pub fn base62_unsupported_test() {
  assert case multibase.encode_with_prefix(Base62, <<"x":utf8>>) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn base91_unsupported_test() {
  assert case multibase.encode_with_prefix(Base91, <<"x":utf8>>) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn ascii85_unsupported_test() {
  assert case multibase.encode_with_prefix(Ascii85, <<"x":utf8>>) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn adobe_ascii85_unsupported_test() {
  assert case multibase.encode_with_prefix(AdobeAscii85, <<"x":utf8>>) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn rfc1924_unsupported_test() {
  assert case multibase.encode_with_prefix(Rfc1924Base85, <<1, 2, 3, 4>>) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn z85_unsupported_test() {
  assert case multibase.encode_with_prefix(Z85, <<1, 2, 3, 4>>) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn dq_unsupported_test() {
  assert case multibase.encode_with_prefix(Base64(encoding.DQ), <<"x":utf8>>) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

// ===== Decode error cases =====

pub fn decode_unsupported_prefix_test() {
  assert multibase.decode("!invalid") == Error(UnsupportedPrefix("!"))
}

pub fn decode_empty_test() {
  assert multibase.decode("") == Error(UnsupportedPrefix(""))
}

pub fn decode_bytes_roundtrip_test() {
  let data = <<"Hello":utf8>>
  let assert Ok(encoded) = multibase.encode_with_prefix(Base32(RFC4648), data)
  assert multibase.decode_bytes(encoded) == Ok(data)
}
