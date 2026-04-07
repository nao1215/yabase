import gleeunit
import yabase
import yabase/core/encoding.{
  Base16, Base32, Base45, Base58, Base64, Base85, Bitcoin, Btoa, DQ, Decoded,
  Flickr, NoPadding, RFC4648, Standard, UnsupportedMultibaseEncoding,
  UnsupportedPrefix, UrlSafeNoPadding,
}

pub fn main() -> Nil {
  gleeunit.main()
}

// --- yabase.encode / yabase.decode roundtrip ---

pub fn encode_decode_base16_test() {
  let data = <<"Hello":utf8>>
  let assert Ok(encoded) = yabase.encode(Base16, data)
  assert yabase.decode(Base16, encoded) == Ok(data)
}

pub fn encode_decode_base64_test() {
  let data = <<"Hello":utf8>>
  let assert Ok(encoded) = yabase.encode(Base64(Standard), data)
  assert encoded == "SGVsbG8="
  assert yabase.decode(Base64(Standard), encoded) == Ok(data)
}

pub fn encode_decode_base32_test() {
  let data = <<"foo":utf8>>
  let assert Ok(encoded) = yabase.encode(Base32(RFC4648), data)
  assert encoded == "MZXW6==="
  assert yabase.decode(Base32(RFC4648), encoded) == Ok(data)
}

// --- yabase.encode_multibase / yabase.decode_multibase roundtrip ---

pub fn multibase_roundtrip_base16_test() {
  let data = <<"Hello":utf8>>
  let assert Ok(prefixed) = yabase.encode_multibase(Base16, data)
  let assert Ok(Decoded(encoding: Base16, data: decoded)) =
    yabase.decode_multibase(prefixed)
  assert decoded == data
}

pub fn multibase_roundtrip_base58_bitcoin_test() {
  let data = <<"Hello":utf8>>
  let assert Ok(prefixed) = yabase.encode_multibase(Base58(Bitcoin), data)
  let assert Ok(Decoded(encoding: Base58(Bitcoin), data: decoded)) =
    yabase.decode_multibase(prefixed)
  assert decoded == data
}

pub fn multibase_roundtrip_base58_flickr_test() {
  let data = <<"Hello":utf8>>
  let assert Ok(prefixed) = yabase.encode_multibase(Base58(Flickr), data)
  assert case prefixed {
    "Z" <> _ -> True
    _ -> False
  }
  let assert Ok(Decoded(encoding: Base58(Flickr), data: decoded)) =
    yabase.decode_multibase(prefixed)
  assert decoded == data
}

pub fn multibase_roundtrip_base64_nopad_test() {
  let data = <<"Hello":utf8>>
  let assert Ok(prefixed) = yabase.encode_multibase(Base64(NoPadding), data)
  let assert Ok(Decoded(encoding: Base64(NoPadding), data: decoded)) =
    yabase.decode_multibase(prefixed)
  assert decoded == data
}

// --- Error cases ---

pub fn decode_multibase_unsupported_prefix_test() {
  assert yabase.decode_multibase("!whatever") == Error(UnsupportedPrefix("!"))
}

pub fn decode_multibase_empty_test() {
  assert yabase.decode_multibase("") == Error(UnsupportedPrefix(""))
}

pub fn encode_multibase_dq_unsupported_test() {
  assert case yabase.encode_multibase(Base64(DQ), <<"x":utf8>>) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn encode_multibase_ascii85_unsupported_test() {
  assert case yabase.encode_multibase(Base85(Btoa), <<"test":utf8>>) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

// --- Variant coverage ---

pub fn encode_decode_urlsafe_nopadding_test() {
  let data = <<"Hello":utf8>>
  let assert Ok(encoded) = yabase.encode(Base64(UrlSafeNoPadding), data)
  assert yabase.decode(Base64(UrlSafeNoPadding), encoded) == Ok(data)
}

pub fn multibase_roundtrip_urlsafe_nopadding_test() {
  let data = <<"Hello":utf8>>
  let assert Ok(prefixed) =
    yabase.encode_multibase(Base64(UrlSafeNoPadding), data)
  assert case prefixed {
    "u" <> _ -> True
    _ -> False
  }
  let assert Ok(Decoded(encoding: Base64(UrlSafeNoPadding), data: decoded)) =
    yabase.decode_multibase(prefixed)
  assert decoded == data
}

pub fn multibase_roundtrip_base45_test() {
  let data = <<"AB":utf8>>
  let assert Ok(prefixed) = yabase.encode_multibase(Base45, data)
  assert case prefixed {
    "R" <> _ -> True
    _ -> False
  }
  let assert Ok(Decoded(encoding: Base45, data: decoded)) =
    yabase.decode_multibase(prefixed)
  assert decoded == data
}
