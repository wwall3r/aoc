import argv
import gleam/int
import gleam/io
import gleam/list
import gleam/regexp
import gleam/string
import simplifile

type Coord =
  #(Int, Int)

// set to 0 for part1 and sanity check
// const offset = 0

const offset = 10_000_000_000_000

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
    let assert [a, b, #(tx, ty)] =
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

    check(a, b, #(tx + offset, ty + offset))
  })
  |> int.sum()
  |> io.debug()
}

// change: solve parametric equations for A and B
// tx = ax * A + bx * B
// ty = ay * A + by * B
//
// This is not a generic solution over all the cases implied in the puzzle
// text. Therefore, the input (or at least my input) must be constrained
// specifically to allow this solution in that there is only ever exactly
// one solution.
//
// (Consider a case like A=(1, 1) and B=(2, 2) which might have MANY solutions)

fn check(a: Coord, b: Coord, target: Coord) -> Int {
  let #(ax, ay) = a
  let #(bx, by) = b
  let #(tx, ty) = target

  let a = { tx * by - ty * bx } / { by * ax - bx * ay }
  let b = { tx * ay - ty * ax } / { ay * bx - by * ax }

  // ensure real solution was not actually fractional
  let good_x = ax * a + bx * b == tx
  let good_y = ay * a + by * b == ty

  case good_x, good_y {
    True, True -> 3 * a + b
    _, _ -> 0
  }
}

fn parse_int(str: String) -> Int {
  let assert Ok(num) = int.parse(str)
  num
}
