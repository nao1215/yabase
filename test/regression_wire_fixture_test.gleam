import gleam/list
import regression_wire_fixtures
import yabase as y

pub fn independent_base16_test() {
  list.each(regression_wire_fixtures.rows(), fn(row) {
    assert y.encode(row.0, using: y.Base16) == Ok(row.1)
  })
}

pub fn independent_base16_lowercase_test() {
  list.each(regression_wire_fixtures.rows(), fn(row) {
    assert y.encode(row.0, using: y.Base16Lowercase) == Ok(row.2)
  })
}

pub fn independent_base64_test() {
  list.each(regression_wire_fixtures.rows(), fn(row) {
    assert y.encode(row.0, using: y.Base64) == Ok(row.3)
  })
}

pub fn independent_base64_no_padding_test() {
  list.each(regression_wire_fixtures.rows(), fn(row) {
    assert y.encode(row.0, using: y.Base64NoPadding) == Ok(row.4)
  })
}

pub fn independent_base64_url_safe_test() {
  list.each(regression_wire_fixtures.rows(), fn(row) {
    assert y.encode(row.0, using: y.Base64UrlSafe) == Ok(row.5)
  })
}

pub fn independent_base64_url_safe_no_padding_test() {
  list.each(regression_wire_fixtures.rows(), fn(row) {
    assert y.encode(row.0, using: y.Base64UrlSafeNoPadding) == Ok(row.6)
  })
}
