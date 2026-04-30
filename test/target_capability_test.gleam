import yabase/core/encoding

// === is_javascript_safe ===

pub fn js_safe_byte_oriented_codecs_test() -> Nil {
  // Byte-oriented codecs are correct on both targets.
  assert encoding.is_javascript_safe(encoding.base2()) == True
  assert encoding.is_javascript_safe(encoding.base16()) == True
  assert encoding.is_javascript_safe(encoding.base45()) == True
  assert encoding.is_javascript_safe(encoding.base91()) == True
}

pub fn js_safe_base32_byte_variants_test() -> Nil {
  assert encoding.is_javascript_safe(encoding.base32_rfc4648()) == True
  assert encoding.is_javascript_safe(encoding.base32_hex()) == True
  assert encoding.is_javascript_safe(encoding.base32_clockwork()) == True
  assert encoding.is_javascript_safe(encoding.base32_z_base32()) == True
}

pub fn js_safe_base64_all_variants_test() -> Nil {
  assert encoding.is_javascript_safe(encoding.base64_standard()) == True
  assert encoding.is_javascript_safe(encoding.base64_url_safe()) == True
  assert encoding.is_javascript_safe(encoding.base64_no_padding()) == True
  assert encoding.is_javascript_safe(encoding.base64_url_safe_no_padding())
    == True
  assert encoding.is_javascript_safe(encoding.base64_dq()) == True
}

pub fn js_safe_base85_all_variants_test() -> Nil {
  assert encoding.is_javascript_safe(encoding.base85_btoa()) == True
  assert encoding.is_javascript_safe(encoding.base85_adobe()) == True
  assert encoding.is_javascript_safe(encoding.base85_rfc1924()) == True
  assert encoding.is_javascript_safe(encoding.base85_z85()) == True
}

pub fn js_unsafe_bignum_codecs_test() -> Nil {
  // Bignum-backed codecs lose precision past Number.MAX_SAFE_INTEGER
  // on JavaScript.
  assert encoding.is_javascript_safe(encoding.base8()) == False
  assert encoding.is_javascript_safe(encoding.base10()) == False
  assert encoding.is_javascript_safe(encoding.base36()) == False
  assert encoding.is_javascript_safe(encoding.base62()) == False
}

pub fn js_unsafe_base32_crockford_variants_test() -> Nil {
  assert encoding.is_javascript_safe(encoding.base32_crockford()) == False
  assert encoding.is_javascript_safe(encoding.base32_crockford_check()) == False
}

pub fn js_unsafe_base58_variants_test() -> Nil {
  assert encoding.is_javascript_safe(encoding.base58_bitcoin()) == False
  assert encoding.is_javascript_safe(encoding.base58_flickr()) == False
}

// === supports_target ===

pub fn supports_erlang_for_every_encoding_test() -> Nil {
  // BEAM has arbitrary-precision integers, so every encoding is
  // supported on the Erlang target.
  let erlang = encoding.target_erlang()
  assert encoding.supports_target(encoding.base2(), erlang) == True
  assert encoding.supports_target(encoding.base8(), erlang) == True
  assert encoding.supports_target(encoding.base58_bitcoin(), erlang) == True
  assert encoding.supports_target(encoding.base32_crockford(), erlang) == True
  assert encoding.supports_target(encoding.base91(), erlang) == True
}

pub fn supports_javascript_byte_oriented_test() -> Nil {
  let js = encoding.target_javascript()
  assert encoding.supports_target(encoding.base16(), js) == True
  assert encoding.supports_target(encoding.base32_rfc4648(), js) == True
  assert encoding.supports_target(encoding.base64_standard(), js) == True
  assert encoding.supports_target(encoding.base85_z85(), js) == True
  assert encoding.supports_target(encoding.base91(), js) == True
}

pub fn supports_javascript_rejects_bignum_codecs_test() -> Nil {
  let js = encoding.target_javascript()
  assert encoding.supports_target(encoding.base8(), js) == False
  assert encoding.supports_target(encoding.base10(), js) == False
  assert encoding.supports_target(encoding.base36(), js) == False
  assert encoding.supports_target(encoding.base62(), js) == False
  assert encoding.supports_target(encoding.base58_bitcoin(), js) == False
  assert encoding.supports_target(encoding.base58_flickr(), js) == False
  assert encoding.supports_target(encoding.base32_crockford(), js) == False
  assert encoding.supports_target(encoding.base32_crockford_check(), js)
    == False
}

// === supports_target / is_javascript_safe agreement ===

pub fn supports_javascript_matches_is_javascript_safe_test() -> Nil {
  // For every encoding, supports_target(_, javascript) must match
  // is_javascript_safe.
  let js = encoding.target_javascript()
  let encs = [
    encoding.base2(),
    encoding.base8(),
    encoding.base10(),
    encoding.base16(),
    encoding.base32_rfc4648(),
    encoding.base32_hex(),
    encoding.base32_crockford(),
    encoding.base32_crockford_check(),
    encoding.base32_clockwork(),
    encoding.base32_z_base32(),
    encoding.base36(),
    encoding.base45(),
    encoding.base58_bitcoin(),
    encoding.base58_flickr(),
    encoding.base62(),
    encoding.base64_standard(),
    encoding.base64_url_safe(),
    encoding.base64_no_padding(),
    encoding.base64_url_safe_no_padding(),
    encoding.base64_dq(),
    encoding.base85_btoa(),
    encoding.base85_adobe(),
    encoding.base85_rfc1924(),
    encoding.base85_z85(),
    encoding.base91(),
  ]
  let agreement =
    list_all(encs, fn(enc) {
      encoding.supports_target(enc, js) == encoding.is_javascript_safe(enc)
    })
  assert agreement == True
}

fn list_all(items: List(a), pred: fn(a) -> Bool) -> Bool {
  case items {
    [] -> True
    [x, ..rest] ->
      case pred(x) {
        True -> list_all(rest, pred)
        False -> False
      }
  }
}
