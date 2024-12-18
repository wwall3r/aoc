import argv
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import simplifile

type Coord =
  #(Int, Int)

const after_num_bytes = 1024

const target = #(70, 70)

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  let corrupted: Set(Coord) =
    content
    |> string.trim()
    |> string.split("\n")
    |> list.take(after_num_bytes)
    |> list.fold(set.new(), fn(corrupted, line) {
      let assert [x, y] =
        line
        |> string.split(",")
        |> list.map(parse_int)

      corrupted
      |> set.insert(#(x, y))
    })

  find_shortest(dict.new(), corrupted, [#(#(0, 0), 0)])
  |> dict.get(target)
  |> result.unwrap(-99_999_999)
  |> io.debug()
}

fn find_shortest(
  visited: Dict(Coord, Int),
  corrupted: Set(Coord),
  neighbors: List(#(Coord, Int)),
) -> Dict(Coord, Int) {
  case neighbors {
    [] -> visited
    [#(coord, score), ..rest] -> {
      let existing =
        visited
        |> dict.get(coord)
        |> result.unwrap(-1)

      case score < existing || existing == -1 {
        False -> find_shortest(visited, corrupted, rest)
        True -> {
          let visited = visited |> dict.insert(coord, score)

          let neighbors =
            dirs
            |> list.map(fn(dir) { #(move(coord, dir), score + 1) })
            |> list.filter(fn(item) {
              let #(coord, _) = item
              let #(max_x, max_y) = target
              let #(x, y) = coord

              !set.contains(corrupted, coord)
              && x >= 0
              && y >= 0
              && x <= max_x
              && y <= max_y
            })
            |> list.append(rest)

          find_shortest(visited, corrupted, neighbors)
        }
      }
    }
  }
}

const dirs = [#(0, 1), #(0, -1), #(1, 0), #(-1, 0)]

fn move(coord: Coord, dir: Coord) -> Coord {
  let #(x, y) = coord
  let #(dx, dy) = dir
  #(x + dx, y + dy)
}

fn parse_int(str: String) -> Int {
  let assert Ok(num) = int.parse(str)
  num
}
