import argv
import gleam/int
import gleam/io
import gleam/list
import gleam/regex
import gleam/string
import simplifile

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  let #(left, right) =
    content
    |> string.split("\n")
    |> list.fold(#([], []), fn(acc, line) {
      let #(left, right) = acc
      let assert Ok(re) = regex.from_string("\\s+")
      let line = string.trim(line)

      case line {
        "" -> #(left, right)
        _ -> {
          let assert [left_value, right_value] =
            re
            |> regex.split(line)
            |> list.map(fn(part) {
              let assert Ok(num) = int.parse(part)
              num
            })

          #([left_value, ..left], [right_value, ..right])
        }
      }
    })

  let left_sorted = list.sort(left, by: int.compare)
  let right_sorted = list.sort(right, by: int.compare)

  list.zip(left_sorted, right_sorted)
  |> list.map(fn(pair) { int.absolute_value(pair.1 - pair.0) })
  |> int.sum
  |> io.debug
}
