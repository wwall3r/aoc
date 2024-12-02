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

  left
  |> list.map(fn(num) {
    num
    * list.fold(right, 0, fn(count, value) {
      case num == value {
        True -> count + 1
        _ -> count
      }
    })
  })
  |> int.sum
  |> io.debug
}
