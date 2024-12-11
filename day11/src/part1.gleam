import argv
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import simplifile

type Seen =
  Dict(Int, List(Int))

const target = 25

// This isn't really "nice" other than that it memoizes the result for each seen
// value
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

fn blink(stone: Int, seen: Seen, depth: Int) -> #(Seen, Int) {
  case depth {
    0 -> #(seen, 1)
    _ -> {
      let next_stones =
        seen
        |> dict.get(stone)
        |> result.unwrap(get_next(stone))

      let seen = dict.insert(seen, stone, next_stones)

      blink_stones(next_stones, seen, depth - 1)
    }
  }
}

fn get_next(stone: Int) -> List(Int) {
  let str = int.to_string(stone)
  let len = string.length(str)
  let half = len / 2

  case stone {
    0 -> [1]
    _ if len % 2 == 0 ->
      [string.slice(str, 0, half), string.slice(str, half, half)]
      |> list.map(parse_int)
    n -> [n * 2024]
  }
}

fn parse_int(str: String) -> Int {
  let assert Ok(num) = int.parse(str)
  num
}
