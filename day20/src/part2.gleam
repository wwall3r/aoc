import argv
import birl
import birl/duration
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder
import glearray.{type Array}
import simplifile

pub type Grid {
  Grid(path: Set(Coord), start: Coord, end: Coord)
}

type Coord =
  #(Int, Int)

const threshold = 100

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  let initial_grid = Grid(set.new(), #(-1, -1), #(-1, -1))

  let grid =
    content
    |> string.trim()
    |> string.split("\n")
    |> list.index_fold(initial_grid, fn(grid, line, y) {
      line
      |> string.to_graphemes()
      |> list.index_fold(grid, fn(grid, c, x) {
        let coord = #(x, y)

        case c {
          "." -> Grid(..grid, path: grid.path |> set.insert(coord))
          "S" ->
            Grid(..grid, path: grid.path |> set.insert(coord), start: coord)
          "E" -> Grid(..grid, path: grid.path |> set.insert(coord), end: coord)
          _ -> grid
        }
      })
    })

  let s = birl.now()

  io.debug("bfs fill")
  let scores = get_scores(grid, dict.new(), [#(grid.start, 0)])

  let s = print_time_from(s)
  io.println("")
  io.debug("scores to array")

  let array =
    scores
    |> dict.to_list()
    |> glearray.from_list()

  let s = print_time_from(s)

  io.println("")
  io.debug("part 1")

  cheat(array, 2)
  |> io.debug()

  let s = print_time_from(s)

  io.println("")
  io.debug("part 2")

  cheat(array, 20)
  |> io.debug()

  print_time_from(s)
}

fn print_time_from(s) {
  let e = birl.now()

  e
  |> birl.difference(s)
  |> duration.blur_to(duration.MilliSecond)
  |> int.to_string
  |> string.append("ms")
  |> io.println()

  e
}

fn get_scores(
  grid: Grid,
  visited: Dict(Coord, Int),
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
        False -> get_scores(grid, visited, rest)
        True -> {
          let visited = visited |> dict.insert(coord, score)

          let neighbors =
            dirs
            |> list.map(fn(dir) { #(move(coord, dir), score + 1) })
            |> list.filter(fn(item) {
              let #(coord, _) = item
              grid.path |> set.contains(coord)
            })
            |> list.append(rest)

          get_scores(grid, visited, neighbors)
        }
      }
    }
  }
}

fn cheat(array: Array(#(Coord, Int)), max_distance: Int) -> Int {
  let len = glearray.length(array)

  yielder.range(0, len - 2)
  |> yielder.fold(0, fn(cheats, i) {
    yielder.range(i + 1, len - 1)
    |> yielder.fold(cheats, fn(cheats, j) {
      let #(#(x1, y1), s1) = get(array, i)
      let #(#(x2, y2), s2) = get(array, j)

      let distance = int.absolute_value(x2 - x1) + int.absolute_value(y2 - y1)
      let score = int.absolute_value(s2 - s1) - distance

      case score >= threshold && distance <= max_distance {
        True -> cheats + 1
        False -> cheats
      }
    })
  })
}

fn get(array: Array(a), i: Int) -> a {
  case array |> glearray.get(i) {
    Ok(item) -> item
    Error(Nil) -> panic as "could not get ith from array"
  }
}

const dirs = [#(0, -1), #(0, 1), #(1, 0), #(-1, 0)]

fn move(coord: Coord, dir: Coord) -> Coord {
  let #(x, y) = coord
  let #(dx, dy) = dir
  #(x + dx, y + dy)
}
