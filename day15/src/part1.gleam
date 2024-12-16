import argv
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type ItemType {
  Wall
  Box
  Free
}

pub type Grid {
  Grid(items: Dict(Coord, ItemType), robot: Coord, width: Int, height: Int)
}

type Coord =
  #(Int, Int)

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  let assert [grid_lines, move_lines] =
    content
    |> string.trim()
    |> string.split("\n\n")

  let initial_grid = Grid(dict.new(), #(-1, -1), 0, 0)

  let grid =
    grid_lines
    |> string.split("\n")
    |> list.fold(initial_grid, fn(grid, line) {
      let width = string.length(line)

      let #(items, robot) =
        line
        |> string.to_graphemes()
        |> list.index_fold(#(grid.items, grid.robot), fn(state, c, x) {
          let #(items, robot) = state

          case c {
            "." -> state
            "#" -> #(dict.insert(items, #(x, grid.height), Wall), robot)
            "O" -> #(dict.insert(items, #(x, grid.height), Box), robot)
            "@" -> #(items, #(x, grid.height))
            _ -> panic as "unknown item"
          }
        })

      Grid(items, robot, width, grid.height + 1)
    })

  let grid =
    move_lines
    |> string.replace("\n", "")
    |> string.to_graphemes()
    |> list.map(arrow_to_dir)
    |> list.fold(grid, process_move)

  grid.items
  |> dict.filter(fn(_, item_type) { item_type == Box })
  |> dict.keys()
  |> list.map(to_gps)
  |> int.sum()
  |> io.debug()
}

fn process_move(grid: Grid, dir: Coord) -> Grid {
  let #(dir, items) = find_free(grid, grid.robot, dir, [])

  case dir == cant_move {
    True -> grid
    False -> {
      let robot = move(grid.robot, dir)

      let items =
        items
        |> list.fold(grid.items, fn(items, item) {
          let existing =
            items
            |> dict.get(item)
            |> result.unwrap(Free)

          let items = dict.delete(items, item)
          let item = move(item, dir)

          dict.insert(items, item, existing)
        })

      Grid(..grid, items:, robot:)
    }
  }
}

fn find_free(
  grid: Grid,
  coord: Coord,
  dir: Coord,
  items: List(Coord),
) -> #(Coord, List(Coord)) {
  let next_coord = move(coord, dir)

  let item_type =
    grid.items
    |> dict.get(next_coord)
    |> result.unwrap(Free)

  case item_type {
    Free -> #(dir, items)
    Wall -> #(cant_move, items)
    Box -> find_free(grid, next_coord, dir, [next_coord, ..items])
  }
}

fn to_gps(coord: Coord) -> Int {
  let #(x, y) = coord
  100 * y + x
}

const up = #(0, -1)

const down = #(0, 1)

const left = #(-1, 0)

const right = #(1, 0)

const cant_move = #(0, 0)

fn move(coord: Coord, dir: Coord) -> Coord {
  let #(x, y) = coord
  let #(dx, dy) = dir
  #(x + dx, y + dy)
}

fn arrow_to_dir(str: String) -> Coord {
  case str {
    "<" -> left
    ">" -> right
    "^" -> up
    "v" -> down
    _ -> panic as "robots were not designed to move like this"
  }
}
