import argv
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import simplifile

const operators = [int.add, int.multiply, concat]

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  content
  |> string.replace(":", "")
  |> string.split("\n")
  |> list.filter(fn(str) { !string.is_empty(str) })
  |> list.map(fn(line) {
    let assert [expected, first, ..rest] =
      line
      |> string.split(" ")
      |> list.map(parse_int)

    rest
    |> list.fold([first], fn(results, operand) {
      results
      |> list.map(fn(result) {
        operators
        |> list.map(fn(op) { op(result, operand) })
        |> list.filter(fn(n) { n <= expected })
      })
      |> list.flatten()
    })
    |> list.fold(0, fn(val, result) {
      case expected == result {
        True -> expected
        False -> val
      }
    })
  })
  |> int.sum()
  |> io.debug()
}

fn concat(a: Int, b: Int) -> Int {
  let str = int.to_string(a) <> int.to_string(b)
  parse_int(str)
}

fn parse_int(str) {
  let assert Ok(num) = int.parse(str)
  num
}
