import yabase/core/encoding.{
  Adobe, Base10, Base16, Base2, Base32, Base36, Base45, Base58, Base62, Base64,
  Base8, Base85, Base91, Bitcoin, Btoa, Clockwork, Crockford, Decoded, Flickr,
  Hex, InvalidCharacter, NoPadding, RFC4648, Rfc1924, Standard,
  UnsupportedMultibaseEncoding, UnsupportedPrefix, UrlSafe, UrlSafeNoPadding,
  Z85, ZBase32,
}
import yabase/core/multibase

// ===== Official multibase registry vectors =====

pub fn registry_0_base2_test() {
  let data = <<"Hi":utf8>>
  let assert Ok(encoded) = multibase.encode_with_prefix(Base2, data)
  assert encoded == "00100100001101001"
  let assert Ok(Decoded(encoding: Base2, data: decoded)) =
    multibase.decode(encoded)
  assert decoded == data
}

pub fn registry_7_base8_test() {
  let data = <<"Hi":utf8>>
  let assert Ok(encoded) = multibase.encode_with_prefix(Base8, data)
  assert case encoded {
    "7" <> _ -> True
    _ -> False
  }
  let assert Ok(Decoded(encoding: Base8, data: decoded)) =
    multibase.decode(encoded)
  assert decoded == data
}

pub fn registry_9_base10_test() {
  let data = <<"Hi":utf8>>
  let assert Ok(encoded) = multibase.encode_with_prefix(Base10, data)
  assert case encoded {
    "9" <> _ -> True
    _ -> False
  }
  let assert Ok(Decoded(encoding: Base10, data: decoded)) =
    multibase.decode(encoded)
  assert decoded == data
}

pub fn registry_f_base16_test() {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) = multibase.encode_with_prefix(Base16, data)
  assert encoded == "f796573206d616e692021"
  let assert Ok(Decoded(encoding: Base16, data: decoded)) =
    multibase.decode(encoded)
  assert decoded == data
}

pub fn registry_upper_f_base16_decode_test() {
  let assert Ok(Decoded(encoding: Base16, data: decoded)) =
    multibase.decode("F796573206D616E692021")
  assert decoded == <<"yes mani !":utf8>>
}

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

pub fn registry_z_base58btc_test() {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) = multibase.encode_with_prefix(Base58(Bitcoin), data)
  assert case encoded {
    "z" <> _ -> True
    _ -> False
  }
  let assert Ok(Decoded(encoding: Base58(Bitcoin), data: decoded)) =
    multibase.decode(encoded)
  assert decoded == data
}

pub fn registry_upper_z_base58flickr_test() {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) = multibase.encode_with_prefix(Base58(Flickr), data)
  assert case encoded {
    "Z" <> _ -> True
    _ -> False
  }
  let assert Ok(Decoded(encoding: Base58(Flickr), data: decoded)) =
    multibase.decode(encoded)
  assert decoded == data
}

pub fn registry_upper_m_base64pad_test() {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) = multibase.encode_with_prefix(Base64(Standard), data)
  assert encoded == "MeWVzIG1hbmkgIQ=="
  let assert Ok(Decoded(encoding: Base64(Standard), data: decoded)) =
    multibase.decode(encoded)
  assert decoded == data
}

pub fn registry_lower_m_base64_test() {
  let data = <<"yes mani !":utf8>>
  let assert Ok(encoded) = multibase.encode_with_prefix(Base64(NoPadding), data)
  assert encoded == "meWVzIG1hbmkgIQ"
  let assert Ok(Decoded(encoding: Base64(NoPadding), data: decoded)) =
    multibase.decode(encoded)
  assert decoded == data
}

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

pub fn registry_upper_b_base32upper_decode_test() {
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

pub fn base85_btoa_unsupported_test() {
  assert case multibase.encode_with_prefix(Base85(Btoa), <<"x":utf8>>) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn base85_adobe_unsupported_test() {
  assert case multibase.encode_with_prefix(Base85(Adobe), <<"x":utf8>>) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn base85_rfc1924_unsupported_test() {
  assert case multibase.encode_with_prefix(Base85(Rfc1924), <<1, 2, 3, 4>>) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn base85_z85_unsupported_test() {
  assert case multibase.encode_with_prefix(Base85(Z85), <<1, 2, 3, 4>>) {
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

// ===== No-padding rejection through multibase wrapper =====

pub fn multibase_m_rejects_padded_input_test() {
  // m = base64 no-padding; "mZg==" has padding and must be rejected
  assert case multibase.decode("mZg==") {
    Error(InvalidCharacter("=", _)) -> True
    _ -> False
  }
}

pub fn multibase_u_rejects_padded_input_test() {
  // u = base64url no-padding; "uZg==" has padding and must be rejected
  assert case multibase.decode("uZg==") {
    Error(InvalidCharacter("=", _)) -> True
    _ -> False
  }
}
