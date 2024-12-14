import argv
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/regexp
import gleam/string
import gleam/yielder
import simplifile

type Coord =
  #(Int, Int)

const costs = #(3, 1)

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  let assert Ok(re) =
    regexp.compile(
      "[^\\d\\s]",
      regexp.Options(case_insensitive: False, multi_line: True),
    )

  re
  |> regexp.replace(content, "")
  |> string.trim()
  |> string.split("\n\n")
  |> list.map(fn(lines) {
    let assert [a, b, target] =
      lines
      |> string.split("\n")
      |> list.map(fn(line) {
        let assert [x, y] =
          line
          |> string.trim()
          |> string.split(" ")
          |> list.map(parse_int)

        #(x, y)
      })

    check(a, b, target)
  })
  |> int.sum()
  |> io.debug()
}

fn check(a: Coord, b: Coord, target: Coord) -> Int {
  let #(ax, ay) = a
  let #(bx, by) = b
  let #(tx, ty) = target

  yielder.range(0, 100)
  |> yielder.fold([], fn(answers, count_a) {
    yielder.range(0, 100)
    |> yielder.fold(answers, fn(answers, count_b) {
      let cx = count_a * ax + count_b * bx
      let cy = count_a * ay + count_b * by

      case cx == tx && cy == ty {
        True -> [#(count_a, count_b), ..answers]
        False -> answers
      }
    })
  })
  |> list.fold(0, fn(cost, count) {
    let #(cost_a, cost_b) = costs
    let #(a, b) = count
    let new_cost = cost_a * a + cost_b * b

    case new_cost < cost || cost == 0 {
      True -> new_cost
      False -> cost
    }
  })
}

fn parse_int(str: String) -> Int {
  let assert Ok(num) = int.parse(str)
  num
}
