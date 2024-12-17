import argv
import gleam/dict.{type Dict}
import gleam/io
import gleam/list
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
      line
      |> string.to_graphemes()
      |> list.index_fold(grid, fn(grid, c, x) {
        let coord = #(x, y)

        let path = case c {
          "#" -> grid.path
          _ -> grid.path |> set.insert(coord)
        }

        case c {
          "." -> Grid(..grid, path:)
          "S" -> Grid(..grid, path:, start: coord)
          "E" -> Grid(..grid, path:, end: coord)
          _ -> grid
        }
      })
    })

  find_shortest(dict.new(), grid, [#(grid.start, right, 0)])
  |> dict.get(grid.end)
  |> result.unwrap(0)
  |> io.debug()
}

// basic "flood fill" or Djikstra's Algorithm simplified to a grid
fn find_shortest(
  scores: Dict(Coord, Int),
  grid: Grid,
  neighbors: List(#(Coord, Coord, Int)),
) -> Dict(Coord, Int) {
  case neighbors {
    [] -> scores
    [#(coord, dir, score), ..rest] -> {
      let existing =
        scores
        |> dict.get(coord)
        |> result.unwrap(-1)

      case score < existing || existing == -1 {
        False -> find_shortest(scores, grid, rest)
        True -> {
          let scores =
            scores
            |> dict.insert(coord, score)

          let left_dir = turn_left(dir)
          let right_dir = turn_right(dir)

          let neighbors =
            [
              #(move(coord, dir), dir, score + 1),
              #(move(coord, left_dir), left_dir, score + 1001),
              #(move(coord, right_dir), right_dir, score + 1001),
            ]
            |> list.filter(fn(neighbor) {
              let #(coord, _, _) = neighbor
              set.contains(grid.path, coord)
            })
            |> list.append(rest)

          find_shortest(scores, grid, neighbors)
        }
      }
    }
  }
}

const up = #(0, -1)

const down = #(0, 1)

const left = #(-1, 0)

const right = #(1, 0)

fn move(coord: Coord, dir: Coord) -> Coord {
  let #(x, y) = coord
  let #(dx, dy) = dir
  #(x + dx, y + dy)
}

fn turn_left(dir: Coord) -> Coord {
  case dir {
    d if d == up -> left
    d if d == right -> up
    d if d == down -> right
    d if d == left -> down
    _ -> panic as "unknown dir"
  }
}

fn turn_right(dir: Coord) -> Coord {
  case dir {
    d if d == up -> right
    d if d == right -> down
    d if d == down -> left
    d if d == left -> up
    _ -> panic as "unknown dir"
  }
}
