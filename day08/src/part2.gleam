import argv
import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import gleam/yielder.{Done, Next}
import simplifile

pub type Grid {
  Grid(antennae: Dict(String, List(Coord)), width: Int, height: Int)
}

type Coord =
  #(Int, Int)

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  let initial_grid = Grid(dict.new(), 0, 0)

  let grid: Grid =
    content
    |> string.trim()
    |> string.split("\n")
    |> list.fold(initial_grid, fn(grid, line) {
      let width = string.length(line)

      let grid =
        line
        |> string.to_graphemes()
        |> list.index_fold(grid, fn(grid, char, x) {
          case char {
            "." -> grid
            c -> {
              let current_list =
                grid.antennae
                |> dict.get(c)
                |> result.unwrap([])

              let new_list = [#(x, grid.height), ..current_list]
              let antennae = dict.insert(grid.antennae, c, new_list)

              Grid(..grid, antennae:)
            }
          }
        })

      Grid(..grid, width:, height: grid.height + 1)
    })

  grid.antennae
  |> dict.values()
  |> list.map(fn(coords) { get_antinodes(grid, coords) })
  |> list.flatten()
  |> set.from_list()
  |> set.size()
  |> io.debug()
}

fn get_antinodes(grid: Grid, coords: List(Coord)) -> List(Coord) {
  case coords {
    [_, ..] -> {
      coords
      |> list.combinations(2)
      |> list.map(fn(coords) {
        let assert [start, #(x2, y2)] = coords
        let #(x1, y1) = start
        let dx = x2 - x1
        let dy = y2 - y1

        let negatives = get_all_in_dir(grid, start, #(-dx, -dy))
        let positives = get_all_in_dir(grid, start, #(dx, dy))

        list.append(negatives, positives)
      })
      |> list.flatten()
    }
    _ -> []
  }
}

fn get_all_in_dir(grid: Grid, start: Coord, dir: Coord) -> List(Coord) {
  let #(dx, dy) = dir
  yielder.unfold(start, fn(coord) {
    case is_in_grid(grid, coord) {
      True -> {
        let #(x, y) = coord
        let next_coord = #(x + dx, y + dy)
        Next(coord, next_coord)
      }
      False -> Done
    }
  })
  |> yielder.to_list()
}

fn is_in_grid(grid: Grid, coord: Coord) -> Bool {
  let #(x, y) = coord
  x >= 0 && x < grid.width && y >= 0 && y < grid.height
}
