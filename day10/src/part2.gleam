import argv
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
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
  #(Dict(Coord, Int), Int)

fn find_trails(grid: Grid) -> Int {
  let initial: FoldState = #(dict.new(), 0)

  grid.starts
  |> list.reverse()
  |> list.fold(#(initial, 0), fn(state, start) {
    let #(inner_state, total) = state
    let #(seen, sum) = find_from_head(grid, inner_state, start)
    let total = total + sum
    #(#(seen, 0), total)
  })
  |> pair.second()
}

const dirs = [#(0, 1), #(1, 0), #(0, -1), #(-1, 0)]

fn find_from_head(grid: Grid, state: FoldState, coord: Coord) -> FoldState {
  let #(seen, _) = state
  case dict.get(seen, coord) {
    Ok(count) -> #(seen, count)

    Error(Nil) -> {
      let curr_height =
        grid.topo
        |> dict.get(coord)
        |> result.unwrap(-1)

      case curr_height {
        9 -> #(seen, 1)
        curr_height -> {
          let #(seen, sum) =
            dirs
            |> list.map(fn(dir) {
              let #(dx, dy) = dir
              let #(x, y) = coord
              #(x + dx, y + dy)
            })
            |> list.filter(fn(coord) {
              case coord, dict.get(grid.topo, coord) {
                #(x, y), Ok(h) -> {
                  h - curr_height == 1
                  && x >= 0
                  && x < grid.width
                  && y >= 0
                  && y < grid.height
                }
                _, Error(Nil) -> False
              }
            })
            |> list.fold(#(seen, 0), fn(state, next) {
              let #(_, total) = state
              let #(seen, sum) = find_from_head(grid, state, next)
              #(seen, total + sum)
            })

          let seen = dict.insert(seen, coord, sum)
          #(seen, sum)
        }
      }
    }
  }
}

fn parse_int(str: String) -> Int {
  let assert Ok(num) = int.parse(str)
  num
}
