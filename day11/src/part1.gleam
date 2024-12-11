import argv
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import gleam/yielder
import simplifile

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  let stones =
    content
    |> string.trim()
    |> string.split(" ")
    |> list.map(parse_int)
    |> io.debug()

  io.debug("part 1: 25 times")

  yielder.range(1, 25)
  |> yielder.fold(stones, fn(stones, _) { blink_all(stones) })
  |> list.length()
  |> io.debug()
}

fn blink_all(stones: List(Int)) -> List(Int) {
  stones
  |> list.map(blink)
  |> list.flatten()
}

fn blink(stone: Int) -> List(Int) {
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
