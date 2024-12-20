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

  // scores
  // |> dict.get(grid.end)
  // |> result.unwrap(-1)
  // |> io.debug()

  grid.path
  |> set.fold(dict.new(), fn(cheats, coord) { cheat(scores, cheats, coord) })
  |> dict.fold(0, fn(sum, picoseconds, count) {
    case picoseconds >= 100 {
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

fn cheat(
  scores: Dict(Coord, Int),
  cheats: Dict(Int, Int),
  coord: Coord,
) -> Dict(Int, Int) {
  let current_score =
    scores
    |> dict.get(coord)
    |> result.unwrap(-99_999)

  dirs
  |> list.fold(cheats, fn(cheats, dir) {
    let coord =
      coord
      |> move(dir)
      |> move(dir)

    let score =
      scores
      |> dict.get(coord)
      |> result.unwrap(-1)

    case score > -1 && score - current_score > 2 {
      True ->
        cheats
        |> dict.upsert(score - current_score - 2, fn(maybe_count) {
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
