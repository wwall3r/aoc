import argv
import gleam/int
import gleam/io
import gleam/list.{Continue, Stop}
import gleam/string
import simplifile

const operators = [int.add, int.multiply]

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
    |> list.fold_until(0, fn(_, result) {
      case expected == result {
        True -> Stop(expected)
        False -> Continue(0)
      }
    })
  })
  |> int.sum()
  |> io.debug()
}

fn parse_int(str) {
  let assert Ok(num) = int.parse(str)
  num
}
