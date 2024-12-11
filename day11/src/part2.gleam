import argv
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import simplifile

// map[stone][depth] = length produced
type Seen =
  Dict(Int, Dict(Int, Int))

// for better part1 set to 25
const target = 75

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  let stones =
    content
    |> string.trim()
    |> string.split(" ")
    |> list.map(parse_int)
    |> io.debug()

  let seen: Seen = dict.new()

  blink_stones(stones, seen, target)
  |> pair.second()
  |> io.debug()
}

fn blink_stones(stones: List(Int), seen: Seen, depth: Int) -> #(Seen, Int) {
  list.fold(stones, #(seen, 0), fn(state, next) {
    let #(seen, sum) = state
    let #(seen, n) = blink(next, seen, depth)
    #(seen, sum + n)
  })
}

// changes: 
// - memoize by stone and depth
// - avoid allocation of lists; this is a DFS for the number of items, so the list
//   was superfluous

fn blink(stone: Int, seen: Seen, depth: Int) -> #(Seen, Int) {
  let known = case dict.get(seen, stone) {
    Ok(by_depth) ->
      case dict.get(by_depth, depth) {
        Ok(num) -> Ok(num)
        _ -> Error(Nil)
      }
    _ -> Error(Nil)
  }

  case known {
    Ok(num) -> #(seen, num)
    Error(Nil) -> {
      case depth {
        0 -> #(seen, 1)
        _ -> {
          let str = int.to_string(stone)
          let len = string.length(str)
          let half = len / 2

          let #(seen, n) = case stone {
            0 -> blink(1, seen, depth - 1)
            _ if len % 2 == 0 -> {
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

          let existing =
            seen
            |> dict.get(stone)
            |> result.unwrap(dict.new())

          let seen = dict.insert(seen, stone, dict.insert(existing, depth, n))

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
