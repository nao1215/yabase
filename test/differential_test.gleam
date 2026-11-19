//// Differential tests: yabase against independent implementations of
//// the same specifications.
////
//// gleam_stdlib's `bit_array.base64_encode`, `base64_url_encode` and
//// `base16_encode` are separate implementations of RFC 4648 (they call
//// the platform's own codec on each target), and Erlang's `crypto`
//// module is an independent SHA-256 (FIPS 180-4), the hash behind the
//// base58check checksum. For random byte strings both
//// sides must agree byte for byte, and yabase must decode what the
//// other implementation encoded.

import gleam/bit_array
import gleam/string
import metamon
import metamon/generator.{type Generator}
import metamon/generator/range
import yabase/base16
import yabase/base64/nopadding
import yabase/base64/standard
import yabase/base64/urlsafe
import yabase/base64/urlsafe_nopadding

@target(erlang)
import yabase/internal/sha256

/// Lengths 0..70 cover every padding case and, for SHA-256, the
/// 55/56/64-byte message lengths where the padding spills into a
/// second block.
fn bytes_generator() -> Generator(BitArray) {
  generator.bit_array(range.constant(0, 70))
}

pub fn base64_standard_matches_gleam_stdlib_test() -> Nil {
  metamon.forall(bytes_generator(), fn(data) {
    let reference = bit_array.base64_encode(data, True)
    standard.encode(data) == reference && standard.decode(reference) == Ok(data)
  })
}

pub fn base64_nopadding_matches_gleam_stdlib_test() -> Nil {
  metamon.forall(bytes_generator(), fn(data) {
    let reference = bit_array.base64_encode(data, False)
    nopadding.encode(data) == reference
    && nopadding.decode(reference) == Ok(data)
  })
}

pub fn base64_urlsafe_matches_gleam_stdlib_test() -> Nil {
  metamon.forall(bytes_generator(), fn(data) {
    let reference = bit_array.base64_url_encode(data, True)
    urlsafe.encode(data) == reference && urlsafe.decode(reference) == Ok(data)
  })
}

pub fn base64_urlsafe_nopadding_matches_gleam_stdlib_test() -> Nil {
  metamon.forall(bytes_generator(), fn(data) {
    let reference = bit_array.base64_url_encode(data, False)
    urlsafe_nopadding.encode(data) == reference
    && urlsafe_nopadding.decode(reference) == Ok(data)
  })
}

pub fn base16_matches_gleam_stdlib_test() -> Nil {
  metamon.forall(bytes_generator(), fn(data) {
    let reference = bit_array.base16_encode(data)
    base16.encode(data) == reference
    && base16.encode_lowercase(data) == string.lowercase(reference)
    && base16.decode(reference) == Ok(data)
    && base16.decode(string.lowercase(reference)) == Ok(data)
  })
}

@target(erlang)
@external(erlang, "crypto", "hash")
fn erlang_crypto_hash(algorithm: HashAlgorithm, data: BitArray) -> BitArray

@target(erlang)
type HashAlgorithm {
  Sha256
}

@target(erlang)
pub fn sha256_matches_erlang_crypto_test() -> Nil {
  metamon.forall(generator.bit_array(range.constant(0, 200)), fn(data) {
    sha256.hash(data) == erlang_crypto_hash(Sha256, data)
  })
}
