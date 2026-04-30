/// Print the canonical README content for the auto-generated tables.
///
/// Run via `gleam run -m yabase/dev/gen_readme` or `just gen-readme`.
/// The output goes to stdout — pipe / paste it into `README.md` or
/// run `just gen-readme` (which has the splicing built in).
///
/// This module is separated from the table renderer in
/// `yabase/internal/readme_table` so the renderer can stay pure
/// (string -> string, no I/O) and be exercised from tests.
import gleam/io
import yabase/internal/readme_table

pub fn main() -> Nil {
  io.println(readme_table.multibase_prefix_table_begin)
  io.println("")
  io.print(readme_table.multibase_prefix_table())
  io.println("")
  io.println(readme_table.multibase_prefix_table_end)
}
