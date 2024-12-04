import argv
import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/result
import gleam/string
import glearray.{type Array}
import simplifile

type Grid =
  Array(Array(String))

type Coord =
  #(Int, Int)

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  let grid =
    content
    |> string.split("\n")
    |> list.map(fn(line) {
      line
      |> string.to_graphemes()
      |> glearray.from_list()
    })
    |> glearray.from_list()

  grid
  |> find_starts()
  |> list.map(fn(start) { xmas_check(grid, start) })
  |> int.sum()
  |> io.debug()
}

fn find_starts(grid: Grid) -> List(Coord) {
  let max_x = get_width(grid)
  let max_y = get_height(grid)

  0
  |> iterator.range(max_y - 1)
  |> iterator.fold([], fn(starts, y) {
    0
    |> iterator.range(max_x - 1)
    |> iterator.fold(starts, fn(starts, x) {
      let coord = #(x, y)
      case get_value(grid, coord) {
        "A" -> [coord, ..starts]
        _ -> starts
      }
    })
  })
}

// careful, the order of this matters on this solution
const all_dirs = [get_left_up, get_right_up, get_right_down, get_left_down]

fn xmas_check(grid: Grid, coord: Coord) -> Int {
  let str =
    all_dirs
    |> list.map(fn(next_coord) { get_value(grid, next_coord(coord)) })
    |> string.join("")

  case str {
    "MSSM" -> 1
    "MMSS" -> 1
    "SMMS" -> 1
    "SSMM" -> 1
    _ -> 0
  }
}

fn get_value(grid: Grid, coord: Coord) -> String {
  let #(x, y) = coord

  let row = glearray.get(grid, y)

  case row {
    Ok(array) ->
      array
      |> glearray.get(x)
      |> result.unwrap("")
    _ -> ""
  }
}

fn get_width(grid: Grid) -> Int {
  let row = glearray.get(grid, 0)

  case row {
    Ok(array) -> glearray.length(array)
    Error(Nil) -> 0
  }
}

fn get_height(grid: Grid) -> Int {
  glearray.length(grid)
}

fn get_right_down(coord: Coord) {
  let #(x, y) = coord
  #(x + 1, y + 1)
}

fn get_right_up(coord: Coord) {
  let #(x, y) = coord
  #(x + 1, y - 1)
}

fn get_left_down(coord: Coord) {
  let #(x, y) = coord
  #(x - 1, y + 1)
}

fn get_left_up(coord: Coord) {
  let #(x, y) = coord
  #(x - 1, y - 1)
}
