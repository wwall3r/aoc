import argv
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/string
import simplifile

// keyed by #(stone, depth) to result
type Seen =
  Dict(#(Int, Int), Int)

// for better part1 set to 25
const target = 75

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  content
  |> string.trim()
  |> string.split(" ")
  |> list.map(parse_int)
  |> io.debug()
  |> list.fold(#(dict.new(), 0), fn(state, next) {
    let #(seen, sum) = state
    let #(seen, n) = blink(next, seen, target)
    #(seen, sum + n)
  })
  |> pair.second()
  |> io.debug()
}

// changes: 
// - memoize by stone and depth
// - avoid allocation of lists; this is a DFS for the number of items, so the list
//   was superfluous

fn blink(stone: Int, seen: Seen, depth: Int) -> #(Seen, Int) {
  let stone_and_depth = #(stone, depth)

  case dict.get(seen, stone_and_depth) {
    Ok(num) -> #(seen, num)
    Error(Nil) -> {
      case depth {
        0 -> #(seen, 1)
        _ -> {
          let str = int.to_string(stone)
          let len = string.length(str)

          let #(seen, n) = case stone {
            0 -> blink(1, seen, depth - 1)
            _ if len % 2 == 0 -> {
              let half = len / 2

              let #(seen, a) =
                blink(
                  str |> string.slice(0, half) |> parse_int(),
                  seen,
                  depth - 1,
                )

              let #(seen, b) =
                blink(
                  str |> string.slice(half, half) |> parse_int(),
                  seen,
                  depth - 1,
                )

              #(seen, a + b)
            }
            n -> blink(n * 2024, seen, depth - 1)
          }

          // I think this could technically be improved by checking if n already
          // exists as the value before making a "new set" (not sure if this call
          // actually does that for you)
          let seen = dict.insert(seen, stone_and_depth, n)

          #(seen, n)
        }
      }
    }
  }
}

fn parse_int(str: String) -> Int {
  let assert Ok(num) = int.parse(str)
  num
}
