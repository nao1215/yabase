import gleam/list
import gleam/string
import yabase as y

fn selections() -> List(y.Encoding) {
  [
    y.Base2,
    y.Base8,
    y.Base10,
    y.Base16,
    y.Base16Lowercase,
    y.Base32Rfc4648,
    y.Base32Hex,
    y.Base32Crockford,
    y.Base32CrockfordCheck,
    y.Base32Clockwork,
    y.Zbase32,
    y.Base36,
    y.Base45,
    y.Base58Bitcoin,
    y.Base58Flickr,
    y.Base58Check(0),
    y.Base62,
    y.Base64,
    y.Base64UrlSafe,
    y.Base64NoPadding,
    y.Base64UrlSafeNoPadding,
    y.Base64Dq,
    y.Ascii85,
    y.AdobeAscii85,
    y.Rfc1924Base85,
    y.Z85,
    y.Base91,
    y.Bech32Encoding("bc", y.Bech32),
    y.Bech32Encoding("bc", y.Bech32m),
  ]
}

fn subbytes() -> List(#(BitArray, Int)) {
  [
    #(<<1:size(1)>>, 1),
    #(<<5:size(3)>>, 3),
    #(<<85:size(7)>>, 7),
    #(<<1:size(9)>>, 9),
    #(<<1:size(28)>>, 28),
    #(<<1:size(36)>>, 36),
  ]
}

pub fn every_selection_rejects_all_subbyte_lengths_test() {
  list.each(selections(), fn(encoding) {
    list.each(subbytes(), fn(row) {
      assert y.encode(row.0, using: encoding) == Error(y.UnalignedInput(row.1))
    })
  })
}

pub fn supported_multibase_paths_reject_subbytes_test() {
  let supported = [
    y.Base2,
    y.Base8,
    y.Base10,
    y.Base16,
    y.Base16Lowercase,
    y.Base32Rfc4648,
    y.Base32Hex,
    y.Zbase32,
    y.Base36,
    y.Base45,
    y.Base58Bitcoin,
    y.Base58Flickr,
    y.Base64,
    y.Base64NoPadding,
    y.Base64UrlSafe,
    y.Base64UrlSafeNoPadding,
  ]
  list.each(supported, fn(encoding) {
    list.each(subbytes(), fn(row) {
      assert y.encode_multibase(row.0, using: encoding)
        == Error(y.UnalignedInput(row.1))
    })
  })
}

pub fn multibase_support_precedes_alignment_and_metadata_test() {
  assert y.encode_multibase(<<1:size(1)>>, using: y.Base58Check(-1))
    == Error(y.UnsupportedMultibaseEncoding("base58check"))
  assert y.encode_multibase(
      <<1:size(1)>>,
      using: y.Bech32Encoding("", y.Bech32m),
    )
    == Error(y.UnsupportedMultibaseEncoding("bech32m"))
  assert y.encode_multibase(<<1:size(1)>>, using: y.Base64Dq)
    == Error(y.UnsupportedMultibaseEncoding("base64dq"))
}

pub fn version_precedes_alignment_test() {
  assert y.encode(<<1:size(1)>>, using: y.Base58Check(-1))
    == Error(y.InvalidVersion(-1))
  assert y.encode(<<1:size(7)>>, using: y.Base58Check(256))
    == Error(y.InvalidVersion(256))
}

pub fn hrp_admission_precedes_alignment_test() {
  assert y.encode(<<1:size(1)>>, using: y.Bech32Encoding("BC", y.Bech32))
    == Error(y.InvalidHrp("HRP must be lowercase"))
  assert y.encode(<<1:size(1)>>, using: y.Bech32Encoding("", y.Bech32m))
    == Error(y.InvalidHrp("empty HRP"))
  assert y.encode(
      <<1:size(1)>>,
      using: y.Bech32Encoding(string.repeat("a", 84), y.Bech32),
    )
    == Error(y.InvalidHrp("HRP too long"))
  assert y.encode(<<1:size(1)>>, using: y.Bech32Encoding(" ", y.Bech32m))
    == Error(y.InvalidHrp("character out of range at 0"))
}

pub fn alignment_precedes_bech32_total_length_test() {
  assert y.encode(
      <<1:size(9)>>,
      using: y.Bech32Encoding(string.repeat("a", 83), y.Bech32),
    )
    == Error(y.UnalignedInput(9))
  assert y.encode(
      <<1>>,
      using: y.Bech32Encoding(string.repeat("a", 82), y.Bech32),
    )
    == Error(y.InvalidLength(91))
  assert y.encode(
      <<>>,
      using: y.Bech32Encoding(string.repeat("a", 83), y.Bech32),
    )
    == Ok(
      "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa17vhfd0",
    )
}

pub fn whole_byte_group_length_is_distinct_from_alignment_test() {
  list.each([y.Z85, y.Rfc1924Base85], fn(encoding) {
    assert y.encode(<<1:size(28)>>, using: encoding)
      == Error(y.UnalignedInput(28))
    assert y.encode(<<0>>, using: encoding) == Error(y.InvalidLength(1))
    assert y.encode(<<0, 0>>, using: encoding) == Error(y.InvalidLength(2))
    assert y.encode(<<0, 0, 0>>, using: encoding) == Error(y.InvalidLength(3))
    assert y.encode(<<0, 0, 0, 0, 0>>, using: encoding)
      == Error(y.InvalidLength(5))
    assert y.encode(<<>>, using: encoding) == Ok("")
    assert y.encode(<<0, 0, 0, 0>>, using: encoding) == Ok("00000")
  })
}

pub fn aligned_short_input_controls_test() {
  assert y.encode(<<>>, using: y.Base64) == Ok("")
  assert y.encode(<<255>>, using: y.Base64) == Ok("/w==")
  assert y.encode(<<0, 255>>, using: y.Base16) == Ok("00FF")
  assert y.encode(<<>>, using: y.AdobeAscii85) == Ok("<~~>")
  assert y.encode(<<0, 0, 0, 0>>, using: y.AdobeAscii85) == Ok("<~z~>")
  assert y.encode(<<1>>, using: y.Bech32Encoding("bc", y.Bech32))
    == Ok("bc1qylhukqn")
  assert y.encode(<<1>>, using: y.Bech32Encoding("bc", y.Bech32m))
    == Ok("bc1qy2tv693")
}
