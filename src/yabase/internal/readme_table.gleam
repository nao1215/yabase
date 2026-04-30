/// Single source of truth for the README's auto-generated tables.
///
/// The README contains capability tables that derive from data already
/// living in `yabase/core/encoding`. Rather than maintain them by hand
/// (and drift), the README declares fenced sections like
///
/// ```
/// <!-- BEGIN: multibase-prefix-table -->
/// ...generated content...
/// <!-- END: multibase-prefix-table -->
/// ```
///
/// and the matching string in this module is the canonical content.
/// `test/readme_drift_test.gleam` reads the README at test time and
/// asserts the bytes between markers equal the function output here.
/// Contributors regenerate the README via `just gen-readme`, which
/// prints the canonical content so it can be pasted in.
import yabase/core/encoding.{type Encoding}

/// Markers used in `README.md` to fence the generated multibase
/// prefix table. Both this module and the README must agree on these
/// strings.
pub const multibase_prefix_table_begin: String = "<!-- BEGIN: multibase-prefix-table -->"

pub const multibase_prefix_table_end: String = "<!-- END: multibase-prefix-table -->"

/// All multibase prefix characters this package recognises, in the
/// order they appear in `encoding.from_multibase_prefix/1`.
///
/// Adding a new prefix to `from_multibase_prefix` requires adding it
/// here too — the drift test will catch the mismatch in CI, since a
/// new prefix would also need a row in the README table.
pub fn known_prefixes() -> List(#(String, Encoding)) {
  [
    #("0", encoding.base2()),
    #("7", encoding.base8()),
    #("9", encoding.base10()),
    #("f", encoding.base16()),
    #("F", encoding.base16()),
    #("c", encoding.base32_rfc4648()),
    #("C", encoding.base32_rfc4648()),
    #("b", encoding.base32_rfc4648()),
    #("B", encoding.base32_rfc4648()),
    #("t", encoding.base32_hex()),
    #("T", encoding.base32_hex()),
    #("v", encoding.base32_hex()),
    #("V", encoding.base32_hex()),
    #("k", encoding.base36()),
    #("K", encoding.base36()),
    #("R", encoding.base45()),
    #("z", encoding.base58_bitcoin()),
    #("Z", encoding.base58_flickr()),
    #("h", encoding.base32_z_base32()),
    #("M", encoding.base64_standard()),
    #("m", encoding.base64_no_padding()),
    #("U", encoding.base64_url_safe()),
    #("u", encoding.base64_url_safe_no_padding()),
  ]
}

/// Render the multibase prefix table as the markdown body that goes
/// between the BEGIN/END markers in the README.
///
/// Each row classifies the prefix as either:
/// - `encode + decode`: the prefix is what `encode_multibase` emits
///   for this encoding.
/// - `decode only (encode emits ` + canonical + `)`: the prefix is
///   recognised by `decode_multibase` but `encode_multibase` uses a
///   different canonical prefix.
pub fn multibase_prefix_table() -> String {
  let header =
    "| Prefix | Encoding | Support |\n|--------|----------|---------|\n"
  rows(known_prefixes(), header)
}

fn rows(prefixes: List(#(String, Encoding)), acc: String) -> String {
  case prefixes {
    [] -> acc
    [#(prefix, enc), ..rest] -> rows(rest, acc <> render_row(prefix, enc))
  }
}

fn render_row(prefix: String, enc: Encoding) -> String {
  let name = encoding.multibase_name(enc)
  let support = case encoding.multibase_prefix(enc) {
    Ok(canonical) ->
      case canonical == prefix {
        True -> "encode + decode"
        False -> "decode only (encode emits `" <> canonical <> "`)"
      }
    Error(Nil) -> "decode only"
  }
  "| `" <> prefix <> "` | " <> name <> " | " <> support <> " |\n"
}
