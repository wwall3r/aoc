import argv
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string
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
      let grid =
        line
        |> string.to_graphemes()
        |> list.index_fold(grid, fn(grid, c, x) {
          let coord = #(x, y)

          case c {
            "." -> Grid(..grid, path: grid.path |> set.insert(coord))
            "S" ->
              Grid(..grid, path: grid.path |> set.insert(coord), start: coord)
            "E" ->
              Grid(..grid, path: grid.path |> set.insert(coord), end: coord)
            _ -> grid
          }
        })
    })

  let scores = get_scores(grid, dict.new(), [#(grid.start, 0)])

  // slow
  let combos =
    scores
    |> dict.to_list()
    |> list.combinations(2)

  io.debug("part 1")

  // also slow
  cheat(combos, 2) |> print_cheats()

  io.debug("part 2")

  // and still slow
  cheat(combos, 20) |> print_cheats()
}

fn print_cheats(cheats: Dict(Int, Int)) {
  cheats
  |> dict.fold(0, fn(sum, picoseconds, count) {
    case picoseconds >= threshold {
      True -> sum + count
      False -> sum
    }
  })
  |> io.debug()
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

fn cheat(combos: List(List(#(Coord, Int))), max_distance: Int) -> Dict(Int, Int) {
  combos
  |> list.fold(dict.new(), fn(cheats, item) {
    let assert [#(#(x1, y1), s1), #(#(x2, y2), s2)] = item

    let distance = int.absolute_value(x2 - x1) + int.absolute_value(y2 - y1)
    let score = int.absolute_value(s2 - s1) - distance

    case score >= threshold && distance <= max_distance {
      True ->
        cheats
        |> dict.upsert(score, fn(maybe_count) {
          case maybe_count {
            Some(count) -> count + 1
            None -> 1
          }
        })
      False -> cheats
    }
  })
}

const dirs = [#(0, -1), #(0, 1), #(1, 0), #(-1, 0)]

fn move(coord: Coord, dir: Coord) -> Coord {
  let #(x, y) = coord
  let #(dx, dy) = dir
  #(x + dx, y + dy)
}
