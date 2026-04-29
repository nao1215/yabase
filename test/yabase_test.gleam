import gleeunit
import yabase
import yabase/core/encoding.{Decoded}
import yabase/core/error.{
  InvalidCharacter, UnsupportedMultibaseEncoding, UnsupportedPrefix,
}

pub fn main() -> Nil {
  gleeunit.main()
}

// --- yabase.encode / yabase.decode roundtrip ---

pub fn encode_decode_base16_test() -> Nil {
  let data = <<"Hello":utf8>>
  let assert Ok(encoded) = yabase.encode(encoding.base16(), data)
  assert yabase.decode(encoding.base16(), encoded) == Ok(data)
}

pub fn encode_decode_base64_test() -> Nil {
  let data = <<"Hello":utf8>>
  let assert Ok(encoded) = yabase.encode(encoding.base64_standard(), data)
  assert encoded == "SGVsbG8="
  assert yabase.decode(encoding.base64_standard(), encoded) == Ok(data)
}

pub fn encode_decode_base32_test() -> Nil {
  let data = <<"foo":utf8>>
  let assert Ok(encoded) = yabase.encode(encoding.base32_rfc4648(), data)
  assert encoded == "MZXW6==="
  assert yabase.decode(encoding.base32_rfc4648(), encoded) == Ok(data)
}

// --- yabase.encode_multibase / yabase.decode_multibase roundtrip ---

pub fn multibase_roundtrip_base16_test() -> Nil {
  let data = <<"Hello":utf8>>
  let assert Ok(prefixed) = yabase.encode_multibase(encoding.base16(), data)
  let assert Ok(Decoded(encoding: _, data: decoded)) =
    yabase.decode_multibase(prefixed)
  assert decoded == data
}

pub fn multibase_roundtrip_base58_bitcoin_test() -> Nil {
  let data = <<"Hello":utf8>>
  let assert Ok(prefixed) =
    yabase.encode_multibase(encoding.base58_bitcoin(), data)
  let assert Ok(Decoded(encoding: _, data: decoded)) =
    yabase.decode_multibase(prefixed)
  assert decoded == data
}

pub fn multibase_roundtrip_base58_flickr_test() -> Nil {
  let data = <<"Hello":utf8>>
  let assert Ok(prefixed) =
    yabase.encode_multibase(encoding.base58_flickr(), data)
  assert case prefixed {
    "Z" <> _ -> True
    _ -> False
  }
  let assert Ok(Decoded(encoding: _, data: decoded)) =
    yabase.decode_multibase(prefixed)
  assert decoded == data
}

pub fn multibase_roundtrip_base64_nopad_test() -> Nil {
  let data = <<"Hello":utf8>>
  let assert Ok(prefixed) =
    yabase.encode_multibase(encoding.base64_no_padding(), data)
  let assert Ok(Decoded(encoding: _, data: decoded)) =
    yabase.decode_multibase(prefixed)
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
  assert case yabase.encode_multibase(encoding.base64_dq(), <<"x":utf8>>) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

pub fn encode_multibase_ascii85_unsupported_test() -> Nil {
  assert case yabase.encode_multibase(encoding.base85_btoa(), <<"test":utf8>>) {
    Error(UnsupportedMultibaseEncoding(_)) -> True
    _ -> False
  }
}

// --- Variant coverage ---

pub fn encode_decode_urlsafe_nopadding_test() -> Nil {
  let data = <<"Hello":utf8>>
  let assert Ok(encoded) =
    yabase.encode(encoding.base64_url_safe_no_padding(), data)
  assert yabase.decode(encoding.base64_url_safe_no_padding(), encoded)
    == Ok(data)
}

pub fn multibase_roundtrip_urlsafe_nopadding_test() -> Nil {
  let data = <<"Hello":utf8>>
  let assert Ok(prefixed) =
    yabase.encode_multibase(encoding.base64_url_safe_no_padding(), data)
  assert case prefixed {
    "u" <> _ -> True
    _ -> False
  }
  let assert Ok(Decoded(encoding: _, data: decoded)) =
    yabase.decode_multibase(prefixed)
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
  let assert Ok(prefixed) = yabase.encode_multibase(encoding.base45(), data)
  assert case prefixed {
    "R" <> _ -> True
    _ -> False
  }
  let assert Ok(Decoded(encoding: _, data: decoded)) =
    yabase.decode_multibase(prefixed)
  assert decoded == data
}
