import argv
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
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
    |> string.split("\n")
    |> list.filter(fn(str) { !string.is_empty(str) })
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
  Set(List(Coord))

fn find_trails(grid: Grid) -> Int {
  grid.starts
  |> list.reverse()
  |> list.map(fn(start) {
    find_from_head(grid, set.new(), [], start)
    |> set.size()
  })
  |> int.sum()
}

const dirs = [#(0, 1), #(1, 0), #(0, -1), #(-1, 0)]

fn find_from_head(
  grid: Grid,
  end_set: FoldState,
  path: List(Coord),
  coord: Coord,
) -> FoldState {
  let path = [coord, ..path]

  let curr_height =
    grid.topo
    |> dict.get(coord)
    |> result.unwrap(-1)

  case curr_height {
    9 -> {
      end_set |> set.insert(path)
    }
    curr_height -> {
      dirs
      |> list.map(fn(dir) {
        let #(dx, dy) = dir
        let #(x, y) = coord
        #(x + dx, y + dy)
      })
      |> list.filter(fn(coord) {
        let #(x, y) = coord
        let height = dict.get(grid.topo, coord)

        case height {
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
      |> list.fold(end_set, fn(end_set, next) {
        find_from_head(grid, end_set, path, next)
      })
    }
  }
}

fn parse_int(str: String) -> Int {
  let assert Ok(num) = int.parse(str)
  num
}
