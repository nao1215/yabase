import gleeunit
import yabase.{InvalidCharacter, UnsupportedMultibaseEncoding, UnsupportedPrefix}

pub fn main() -> Nil {
  gleeunit.main()
}

// --- yabase.encode / yabase.decode roundtrip ---

pub fn encode_decode_base16_test() -> Nil {
  let data = <<"Hello":utf8>>
  let assert Ok(encoded) = yabase.encode(data, using: yabase.Base16)
  assert yabase.decode(encoded, using: yabase.Base16) == Ok(data)
}

pub fn encode_decode_base64_test() -> Nil {
  let data = <<"Hello":utf8>>
  let assert Ok(encoded) = yabase.encode(data, using: yabase.Base64)
  assert encoded == "SGVsbG8="
  assert yabase.decode(encoded, using: yabase.Base64) == Ok(data)
}

pub fn encode_decode_base32_test() -> Nil {
  let data = <<"foo":utf8>>
  let assert Ok(encoded) = yabase.encode(data, using: yabase.Base32Rfc4648)
  assert encoded == "MZXW6==="
  assert yabase.decode(encoded, using: yabase.Base32Rfc4648) == Ok(data)
}

// --- yabase.encode_multibase / yabase.decode_multibase roundtrip ---

pub fn multibase_roundtrip_base16_test() -> Nil {
  let data = <<"Hello":utf8>>
  let assert Ok(prefixed) = yabase.encode_multibase(data, using: yabase.Base16)
  let assert Ok(d) = yabase.decode_multibase(prefixed)
  let decoded = { d }.data
  assert decoded == data
}

pub fn multibase_roundtrip_base58_bitcoin_test() -> Nil {
  let data = <<"Hello":utf8>>
  let assert Ok(prefixed) =
    yabase.encode_multibase(data, using: yabase.Base58Bitcoin)
  let assert Ok(d) = yabase.decode_multibase(prefixed)
  let decoded = { d }.data
  assert decoded == data
}

pub fn multibase_roundtrip_base58_flickr_test() -> Nil {
  let data = <<"Hello":utf8>>
  let assert Ok(prefixed) =
    yabase.encode_multibase(data, using: yabase.Base58Flickr)
  assert case prefixed {
    "Z" <> _ -> True
    _ -> False
  }
  let assert Ok(d) = yabase.decode_multibase(prefixed)
  let decoded = { d }.data
  assert decoded == data
}

pub fn multibase_roundtrip_base64_nopad_test() -> Nil {
  let data = <<"Hello":utf8>>
  let assert Ok(prefixed) =
    yabase.encode_multibase(data, using: yabase.Base64NoPadding)
  let assert Ok(d) = yabase.decode_multibase(prefixed)
  let decoded = { d }.data
  assert decoded == data
}

// --- Error cases ---

pub fn decode_multibase_unsupported_prefix_test() -> Nil {
  assert yabase.decode_multibase("!whatever") == Error(UnsupportedPrefix("!"))
}

pub fn decode_multibase_empty_test() -> Nil {
  assert yabase.decode_multibase("") == Error(UnsupportedPrefix(""))
}

pub fn encode_multibase_dq_unsupported_test() -> Nil {
  assert case yabase.encode_multibase(<<"x":utf8>>, using: yabase.Base64Dq) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn encode_multibase_ascii85_unsupported_test() -> Nil {
  assert case yabase.encode_multibase(<<"test":utf8>>, using: yabase.Ascii85) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

// --- Variant coverage ---

pub fn encode_decode_urlsafe_nopadding_test() -> Nil {
  let data = <<"Hello":utf8>>
  let assert Ok(encoded) =
    yabase.encode(data, using: yabase.Base64UrlSafeNoPadding)
  assert yabase.decode(encoded, using: yabase.Base64UrlSafeNoPadding)
    == Ok(data)
}

pub fn multibase_roundtrip_urlsafe_nopadding_test() -> Nil {
  let data = <<"Hello":utf8>>
  let assert Ok(prefixed) =
    yabase.encode_multibase(data, using: yabase.Base64UrlSafeNoPadding)
  assert case prefixed {
    "u" <> _ -> True
    _ -> False
  }
  let assert Ok(d) = yabase.decode_multibase(prefixed)
  let decoded = { d }.data
  assert decoded == data
}

pub fn decode_multibase_rejects_padded_nopadding_test() -> Nil {
  // u = base64url no-padding through top-level API
  assert case yabase.decode_multibase("uZg==") {
    Error(InvalidCharacter("=", _)) -> True
    _ -> False
  }
}

pub fn multibase_roundtrip_base45_test() -> Nil {
  let data = <<"AB":utf8>>
  let assert Ok(prefixed) = yabase.encode_multibase(data, using: yabase.Base45)
  assert case prefixed {
    "R" <> _ -> True
    _ -> False
  }
  let assert Ok(d) = yabase.decode_multibase(prefixed)
  let decoded = { d }.data
  assert decoded == data
}
