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

// --- yabase.encode / yabase.decode_as roundtrip ---

pub fn encode_decode_as_base16_test() {
  let data = <<"Hello":utf8>>
  let assert Ok(encoded) = yabase.encode(Base16, data)
  assert yabase.decode_as(Base16, encoded) == Ok(data)
}

pub fn encode_decode_as_base64_test() {
  let data = <<"Hello":utf8>>
  let assert Ok(encoded) = yabase.encode(Base64(Standard), data)
  assert encoded == "SGVsbG8="
  assert yabase.decode_as(Base64(Standard), encoded) == Ok(data)
}

pub fn encode_decode_as_base32_test() {
  let data = <<"foo":utf8>>
  let assert Ok(encoded) = yabase.encode(Base32(RFC4648), data)
  assert encoded == "MZXW6==="
  assert yabase.decode_as(Base32(RFC4648), encoded) == Ok(data)
}

// --- yabase.encode_with_prefix / yabase.decode roundtrip ---

pub fn encode_with_prefix_decode_base16_test() {
  let data = <<"Hello":utf8>>
  let assert Ok(prefixed) = yabase.encode_with_prefix(Base16, data)
  let assert Ok(Decoded(encoding: Base16, data: decoded)) =
    yabase.decode(prefixed)
  assert decoded == data
}

pub fn encode_with_prefix_decode_base58_bitcoin_test() {
  let data = <<"Hello":utf8>>
  let assert Ok(prefixed) = yabase.encode_with_prefix(Base58(Bitcoin), data)
  let assert Ok(Decoded(encoding: Base58(Bitcoin), data: decoded)) =
    yabase.decode(prefixed)
  assert decoded == data
}

pub fn encode_with_prefix_decode_base58_flickr_test() {
  let data = <<"Hello":utf8>>
  let assert Ok(prefixed) = yabase.encode_with_prefix(Base58(Flickr), data)
  assert case prefixed {
    "Z" <> _ -> True
    _ -> False
  }
  let assert Ok(Decoded(encoding: Base58(Flickr), data: decoded)) =
    yabase.decode(prefixed)
  assert decoded == data
}

pub fn encode_with_prefix_decode_base64_nopad_test() {
  let data = <<"Hello":utf8>>
  let assert Ok(prefixed) = yabase.encode_with_prefix(Base64(NoPadding), data)
  let assert Ok(Decoded(encoding: Base64(NoPadding), data: decoded)) =
    yabase.decode(prefixed)
  assert decoded == data
}

// --- Error cases ---

pub fn decode_unsupported_prefix_test() {
  assert yabase.decode("!whatever") == Error(UnsupportedPrefix("!"))
}

pub fn decode_empty_test() {
  assert yabase.decode("") == Error(UnsupportedPrefix(""))
}

pub fn encode_with_prefix_dq_unsupported_test() {
  assert case yabase.encode_with_prefix(Base64(DQ), <<"x":utf8>>) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn encode_with_prefix_ascii85_unsupported_test() {
  assert case yabase.encode_with_prefix(Base85(Btoa), <<"test":utf8>>) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

// --- Variant coverage ---

pub fn encode_decode_as_urlsafe_nopadding_test() {
  let data = <<"Hello":utf8>>
  let assert Ok(encoded) = yabase.encode(Base64(UrlSafeNoPadding), data)
  assert yabase.decode_as(Base64(UrlSafeNoPadding), encoded) == Ok(data)
}

pub fn encode_with_prefix_urlsafe_nopadding_test() {
  let data = <<"Hello":utf8>>
  let assert Ok(prefixed) =
    yabase.encode_with_prefix(Base64(UrlSafeNoPadding), data)
  assert case prefixed {
    "u" <> _ -> True
    _ -> False
  }
  let assert Ok(Decoded(encoding: Base64(UrlSafeNoPadding), data: decoded)) =
    yabase.decode(prefixed)
  assert decoded == data
}

pub fn encode_with_prefix_base45_test() {
  let data = <<"AB":utf8>>
  let assert Ok(prefixed) = yabase.encode_with_prefix(Base45, data)
  assert case prefixed {
    "R" <> _ -> True
    _ -> False
  }
  let assert Ok(Decoded(encoding: Base45, data: decoded)) =
    yabase.decode(prefixed)
  assert decoded == data
}
