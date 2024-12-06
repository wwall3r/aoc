import argv
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder
import glearray.{type Array}
import simplifile

type Grid =
  Array(Array(String))

type Coord =
  #(Int, Int)

type Direction =
  #(Int, Int)

type State {
  State(coord: Coord, dir: Direction, seen: Set(Coord))
}

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

  let initial_state = get_initial_state(grid)

  let final_state = walk(grid, initial_state)

  final_state.seen
  |> set.size()
  |> io.debug()
}

fn get_initial_state(grid: Grid) -> State {
  let max_x = get_width(grid)
  let max_y = get_height(grid)

  let initial_state = State(#(-1, -1), #(-1, -1), set.new())

  yielder.range(0, max_y - 1)
  |> yielder.fold(initial_state, fn(state, y) {
    yielder.range(0, max_x - 1)
    |> yielder.fold(state, fn(state, x) {
      let coord = #(x, y)
      case get_value(grid, coord) {
        d if d == "^" || d == "v" || d == "<" || d == ">" ->
          State(coord, to_direction(d), set.new())
        _ -> state
      }
    })
  })
}

fn walk(grid, state: State) -> State {
  let State(coord, dir, seen) = state
  let seen = set.insert(seen, coord)

  let next_coord = get_next_coord(coord, dir)
  let value = get_value(grid, next_coord)

  case value {
    "" -> State(..state, seen:)
    "#" -> {
      let dir = turn(dir)
      let next_coord = get_next_coord(coord, dir)
      walk(grid, State(next_coord, dir, seen))
    }
    _ -> walk(grid, State(next_coord, dir, seen))
  }
}

fn get_next_coord(coord: Coord, dir: Direction) -> Coord {
  let #(x, y) = coord
  let #(dx, dy) = dir
  #(x + dx, y + dy)
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

const up = #(0, -1)

const right = #(1, 0)

const down = #(0, 1)

const left = #(-1, 0)

fn to_direction(str: String) -> Direction {
  case str {
    "^" -> up
    ">" -> right
    "v" -> down
    "<" -> left
    _ -> panic
  }
}

fn turn(direction: Direction) -> Direction {
  case direction {
    d if d == up -> right
    d if d == right -> down
    d if d == down -> left
    d if d == left -> up
    _ -> panic
  }
}
