import argv
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/regex
import simplifile

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  let options = regex.Options(case_insensitive: False, multi_line: True)
  let assert Ok(re) = regex.compile("mul\\((\\d+),(\\d+)\\)", options)
  let matches = regex.scan(re, content)

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
