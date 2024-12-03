import argv
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/regex
import gleam/string
import simplifile

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  let stripped_newlines =
    content
    |> string.replace("\n", "")

  let options = regex.Options(case_insensitive: False, multi_line: True)

  let assert Ok(snip_re) = regex.compile("don't\\(\\).*?(do\\(\\)|$)", options)
  let new_content = regex.replace(snip_re, stripped_newlines, "")

  let assert Ok(re) = regex.compile("mul\\((\\d+),(\\d+)\\)", options)
  let matches = regex.scan(re, new_content)

  matches
  |> list.map(fn(match) {
    let assert [a, b] =
      match.submatches
      |> list.map(fn(maybe_str) {
        let assert Some(part) = maybe_str
        let assert Ok(num) = int.parse(part)
        num
      })

    a * b
  })
  |> int.sum()
  |> io.debug()
}
