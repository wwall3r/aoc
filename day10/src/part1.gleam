import argv
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import simplifile

pub type Grid {
  Grid(topo: Dict(Coord, Int), starts: List(Coord), width: Int, height: Int)
}

type Coord =
  #(Int, Int)

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  let initial = Grid(dict.new(), [], 0, 0)

  let grid =
    content
    |> string.trim()
    |> string.split("\n")
    |> list.fold(initial, fn(grid, line) {
      let width = string.length(line)

      let grid =
        line
        |> string.to_graphemes()
        |> list.map(parse_int)
        |> list.index_fold(grid, fn(grid, height, x) {
          let coord = #(x, grid.height)
          let topo =
            grid.topo
            |> dict.insert(coord, height)

          let starts = case height {
            0 -> [coord, ..grid.starts]
            _ -> grid.starts
          }

          Grid(..grid, topo:, starts:)
        })

      Grid(..grid, width:, height: grid.height + 1)
    })

  find_trails(grid)
  |> io.debug()
}

type FoldState =
  #(Grid, Dict(Coord, Set(Coord)), Set(Coord))

fn find_trails(grid: Grid) -> Int {
  let initial = #(grid, dict.new(), set.new())

  grid.starts
  |> list.reverse()
  |> list.fold(#(initial, 0), fn(state, start) {
    let #(next_state, sum) = state
    let #(grid, seen, peak_set) = find_from_head(next_state, start)
    #(#(grid, seen, set.new()), sum + set.size(peak_set))
  })
  |> pair.second()
}

const dirs = [#(0, 1), #(1, 0), #(0, -1), #(-1, 0)]

fn find_from_head(state: FoldState, coord: Coord) -> FoldState {
  let #(grid, seen, _) = state
  case dict.get(seen, coord) {
    Ok(peak_set) -> #(grid, seen, peak_set)

    Error(Nil) -> {
      let curr_height =
        grid.topo
        |> dict.get(coord)
        |> result.unwrap(-1)

      case curr_height {
        9 -> {
          let peak_set = set.from_list([coord])
          #(grid, dict.insert(seen, coord, peak_set), peak_set)
        }
        curr_height -> {
          let #(grid, seen, new_set) =
            dirs
            |> list.map(fn(dir) {
              let #(dx, dy) = dir
              let #(x, y) = coord
              #(x + dx, y + dy)
            })
            |> list.filter(fn(coord) {
              let #(x, y) = coord
              case dict.get(grid.topo, coord) {
                Ok(h) -> {
                  h - curr_height == 1
                  && x >= 0
                  && x < grid.width
                  && y >= 0
                  && y < grid.height
                }
                Error(Nil) -> False
              }
            })
            |> list.fold(#(grid, seen, set.new()), fn(state, next) {
              let #(grid, seen, new_set) = state
              let #(grid, seen, next_set) =
                find_from_head(#(grid, seen, set.new()), next)
              let new_set = set.union(next_set, new_set)
              let seen = dict.insert(seen, coord, new_set)
              #(grid, seen, new_set)
            })

          let seen = dict.insert(seen, coord, new_set)
          #(grid, seen, new_set)
        }
      }
    }
  }
}

fn parse_int(str: String) -> Int {
  let assert Ok(num) = int.parse(str)
  num
}
