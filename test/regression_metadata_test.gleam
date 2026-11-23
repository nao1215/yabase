import gleam/option.{None, Some}
import gleam/string
import yabase as y

pub fn base58check_auto_metadata_is_independent_of_expected_version_test() {
  assert y.decode_base58check("26k9aD1PF")
    == Ok(y.Base58CheckDecoded(128, <<1>>))
  assert y.decode("26k9aD1PF", using: y.Base58Check(128)) == Ok(<<1>>)
  assert y.decode("26k9aD1PF", using: y.Base58Check(0))
    == Error(y.UnexpectedVersion(0, 128))
  assert y.decode_base58check("FXjQL6s") == Ok(y.Base58CheckDecoded(128, <<>>))
}

pub fn base58check_wire_errors_precede_invalid_setting_test() {
  assert y.decode("!", using: y.Base58Check(-1))
    == Error(y.InvalidCharacter("!", 0))
  assert y.decode("1", using: y.Base58Check(-1)) == Error(y.InvalidLength(1))
  assert y.decode("26k9aD1PG", using: y.Base58Check(-1))
    == Error(y.InvalidChecksum)
  assert y.decode("26k9aD1PG", using: y.Base58Check(0))
    == Error(y.InvalidChecksum)
}

pub fn base58check_setting_validation_precedes_mismatch_test() {
  assert y.decode("26k9aD1PF", using: y.Base58Check(-1))
    == Error(y.InvalidVersion(-1))
  assert y.decode("26k9aD1PF", using: y.Base58Check(256))
    == Error(y.InvalidVersion(256))
}

pub fn base58check_integer_stage_order_test() {
  assert y.decode_int("", using: y.Base58Check(-1), up_to: Some(-1))
    == Error(y.InvalidLength(0))
  assert y.decode_int("26k9aD1PG", using: y.Base58Check(-1), up_to: Some(-1))
    == Error(y.InvalidChecksum)
  assert y.decode_int("5rLWbXvFUx", using: y.Base58Check(-1), up_to: Some(-1))
    == Error(y.InvalidVersion(-1))
  assert y.decode_int("5rLWbXvFUx", using: y.Base58Check(0), up_to: Some(-1))
    == Error(y.UnexpectedVersion(0, 128))
  assert y.decode_int("5rLWbXvFUx", using: y.Base58Check(128), up_to: Some(-1))
    == Error(y.NonCanonical)
  assert y.decode_int("26k9aD1PF", using: y.Base58Check(128), up_to: Some(0))
    == Error(y.Overflow)
}

pub fn bech32_auto_metadata_uses_literal_wire_test() {
  assert y.decode_bech32("bc1qylhukqn")
    == Ok(y.Bech32Decoded("bc", <<1>>, y.Bech32))
  assert y.decode_bech32("BC1QYLHUKQN")
    == Ok(y.Bech32Decoded("bc", <<1>>, y.Bech32))
  assert y.decode_bech32("bc1qy2tv693")
    == Ok(y.Bech32Decoded("bc", <<1>>, y.Bech32m))
}

pub fn bech32_metadata_mismatch_priority_test() {
  assert y.decode("bc1qylhukqn", using: y.Bech32Encoding("tb", y.Bech32m))
    == Error(y.UnexpectedHrp("tb", "bc"))
  assert y.decode("bc1qylhukqn", using: y.Bech32Encoding("bc", y.Bech32m))
    == Error(y.UnexpectedBech32Variant(y.Bech32m, y.Bech32))
  assert y.decode("bc1qy2tv693", using: y.Bech32Encoding("bc", y.Bech32))
    == Error(y.UnexpectedBech32Variant(y.Bech32, y.Bech32m))
  assert y.decode("BC1QYLHUKQN", using: y.Bech32Encoding("BC", y.Bech32))
    == Error(y.UnexpectedHrp("BC", "bc"))
}

pub fn bech32_wire_then_setting_then_mismatch_test() {
  assert y.decode("bc1qylhukqq", using: y.Bech32Encoding("", y.Bech32m))
    == Error(y.InvalidChecksum)
  assert y.decode("bc1qylhukqn", using: y.Bech32Encoding("", y.Bech32m))
    == Error(y.InvalidHrp("empty HRP"))
  assert y.decode("bc1qylhukqn", using: y.Bech32Encoding(" ", y.Bech32m))
    == Error(y.InvalidHrp("character out of range at 0"))
  assert y.decode(
      "bc1qylhukqn",
      using: y.Bech32Encoding(string.repeat("a", 84), y.Bech32m),
    )
    == Error(y.InvalidHrp("HRP too long"))
}

pub fn bech32_synthetic_errors_are_distinct_test() {
  assert y.decode_bech32("bC1!qqqqq") == Error(y.MixedCase)
  assert y.decode_bech32("bc1qpdt29jm") == Error(y.NonZeroPadding)
  assert y.decode_bech32("bc1q9zpgru") == Error(y.InvalidLength(1))
  assert y.decode_bech32("bc1qpdt29jq") == Error(y.InvalidChecksum)
}

pub fn bech32_length_ascii_case_and_data_priority_test() {
  assert y.decode_bech32("é" <> string.repeat("A", 90))
    == Error(y.InvalidLength(91))
  assert y.decode_bech32("bC1éqqqqq") == Error(y.InvalidCharacter("é", 3))
  assert y.decode_bech32("bC1!qqqqq") == Error(y.MixedCase)
  assert y.decode_bech32("bc1!qqqq") == Error(y.InvalidLength(5))
  assert y.decode_bech32("bc1!qqqqq") == Error(y.InvalidCharacter("!", 3))
}

pub fn integer_unsupported_and_negative_precede_version_test() {
  assert y.encode_int(-1, using: y.Base64)
    == Error(y.UnsupportedForInt("Base64(Standard)"))
  assert y.decode_int("", using: y.Base64, up_to: None)
    == Error(y.UnsupportedForInt("Base64(Standard)"))
  assert y.encode_int(-1, using: y.Base58Check(-1))
    == Error(y.NegativeValue(-1))
  assert y.encode_int(1, using: y.Base58Check(-1))
    == Error(y.InvalidVersion(-1))
}

@target(javascript)
pub fn javascript_integer_range_precedes_version_test() {
  assert y.encode_int(9_007_199_254_740_991 + 1, using: y.Base58Check(-1))
    == Error(y.Overflow)
}
