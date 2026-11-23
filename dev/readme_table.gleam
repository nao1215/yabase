import gleam/bit_array
import gleam/int
import gleam/list
import gleam/result
import yabase.{type Encoding}

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
/// Markers used in `README.md` to fence the generated multibase
/// prefix table. Both this module and the README must agree on these
/// strings.
pub const multibase_prefix_table_begin: String =
  "<!-- BEGIN: multibase-prefix-table -->"

pub const multibase_prefix_table_end: String =
  "<!-- END: multibase-prefix-table -->"

// All multibase prefix characters this package recognises, in the
// order they appear in `encoding.from_multibase_prefix/1`.
//
// Adding a new prefix to `from_multibase_prefix` requires adding it
// here too — the drift test will catch the mismatch in CI, since a
// new prefix would also need a row in the README table.
// Enumerate the live registry so a new accepted prefix cannot disappear from
// generated documentation merely because this historical order was not updated.
fn known_prefixes() -> List(#(String, Encoding)) {
  registry_entries(0, [])
  |> list.sort(fn(left, right) {
    int.compare(prefix_rank(left.0), prefix_rank(right.0))
  })
}

fn registry_entries(
  code: Int,
  entries: List(#(String, Encoding)),
) -> List(#(String, Encoding)) {
  case code > 127 {
    True -> list.reverse(entries)
    False -> {
      let entry = {
        use prefix <- result.try(bit_array.to_string(<<code>>))
        use encoding <- result.map(yabase.encoding_from_multibase_prefix(prefix))
        #(prefix, encoding)
      }
      case entry {
        Ok(entry) -> registry_entries(code + 1, [entry, ..entries])
        Error(Nil) -> registry_entries(code + 1, entries)
      }
    }
  }
}

fn prefix_rank(prefix: String) -> Int {
  let order = [
    "0", "7", "9", "f", "F", "c", "C", "b", "B", "t", "T", "v", "V", "k", "K",
    "R", "z", "Z", "h", "M", "m", "U", "u",
  ]
  find_rank(order, prefix, 0)
}

fn find_rank(order: List(String), prefix: String, rank: Int) -> Int {
  case order {
    [] -> rank
    [candidate, ..] if candidate == prefix -> rank
    [_, ..rest] -> find_rank(rest, prefix, rank + 1)
  }
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
    [#(prefix, encoding), ..rest] ->
      rows(rest, acc <> render_row(prefix, encoding))
  }
}

fn render_row(prefix: String, encoding: Encoding) -> String {
  let name = yabase.encoding_to_string(encoding)
  let support = case yabase.multibase_prefix(encoding) {
    Ok(canonical) ->
      case canonical == prefix {
        True -> "encode + decode"
        False -> "decode only (encode emits `" <> canonical <> "`)"
      }
    Error(Nil) -> "decode only"
  }
  "| `" <> prefix <> "` | " <> name <> " | " <> support <> " |\n"
}
