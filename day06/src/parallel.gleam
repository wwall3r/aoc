import argv
import birl
import birl/duration
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder
import glearray.{type Array}
import parallel_map.{MatchSchedulersOnline}
import simplifile

type Grid =
  Array(Array(String))

// type Node {
//   Node(
//     coord: Coord,
//     up: Node,
//     right: Node,
//     down: Node,
//     left: Node,
//   )
//   Obstacle
//   Exit
// }

type Coord =
  #(Int, Int)

type Direction =
  #(Int, Int)

type Guard =
  #(Coord, Direction)

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  let grid: Grid =
    content
    |> string.split("\n")
    |> list.map(fn(line) {
      line
      |> string.to_graphemes()
      |> glearray.from_list()
    })
    |> glearray.from_list()

  let guard = get_guard(grid)
  let path = walk(grid, guard, [])

  // useful when refactoring so we know if we broke the first part, since we use 
  // it in the second
  let s = birl.now()
  io.debug("part1")

  path
  |> list.map(pair.first)
  |> set.from_list()
  |> set.size()
  |> io.debug()

  birl.now()
  |> birl.difference(s)
  |> duration.blur_to(duration.MilliSecond)
  |> int.to_string
  |> string.append("ms")
  |> io.println()

  io.debug("part2")

  let s = birl.now()

  path
  |> list.reverse()
  |> list.rest()
  |> result.unwrap([])
  |> parallel_map.list_pmap(
    fn(curr) {
      // place current position as extra obstacle
      let temp_grid = set_value(grid, curr.0, "#")
      #(curr.0, detect_loop(temp_grid, guard, set.new()))
    },
    MatchSchedulersOnline,
    100,
  )
  |> list.map(fn(r) { result.unwrap(r, #(#(-1, -1), False)) })
  |> list.filter(pair.second)
  |> list.map(pair.first)
  |> set.from_list()
  |> set.size()
  |> io.debug()

  birl.now()
  |> birl.difference(s)
  |> duration.blur_to(duration.MilliSecond)
  |> int.to_string
  |> string.append("ms")
  |> io.println()
}

fn get_guard(grid: Grid) -> Guard {
  let max_x = get_width(grid)
  let max_y = get_height(grid)

  let guard = #(#(-1, -1), #(-1, -1))

  yielder.range(0, max_y - 1)
  |> yielder.fold(guard, fn(guard, y) {
    yielder.range(0, max_x - 1)
    |> yielder.fold(guard, fn(guard, x) {
      let coord = #(x, y)
      case get_value(grid, coord) {
        d if d == "^" || d == "v" || d == "<" || d == ">" -> #(
          coord,
          to_direction(d),
        )
        _ -> guard
      }
    })
  })
}

fn walk(grid: Grid, guard: Guard, path: List(Guard)) -> List(Guard) {
  let path = [guard, ..path]

  case move_next(grid, guard) {
    Ok(guard) -> walk(grid, guard, path)
    Error(Nil) -> path
  }
}

fn detect_loop(grid: Grid, guard: Guard, seen: Set(Guard)) -> Bool {
  case set.contains(seen, guard) {
    True -> True
    False -> {
      let seen = set.insert(seen, guard)

      case move_next(grid, guard) {
        Ok(guard) -> detect_loop(grid, guard, seen)
        Error(Nil) -> False
      }
    }
  }
}

fn move_next(grid: Grid, guard: Guard) -> Result(Guard, Nil) {
  let #(coord, dir) = guard

  let next_coord = get_next_coord(guard)
  let value = get_value(grid, next_coord)

  case value {
    "" -> Error(Nil)
    "#" -> Ok(#(coord, turn(dir)))
    _ -> Ok(#(next_coord, dir))
  }
}

fn get_next_coord(guard: Guard) -> Coord {
  let #(#(x, y), #(dx, dy)) = guard
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

fn set_value(grid: Grid, coord: Coord, value: String) -> Grid {
  let #(x, y) = coord

  let row = glearray.get(grid, y)

  let new_row = case row {
    Ok(array) ->
      case glearray.copy_set(array, x, value) {
        Ok(array) -> array
        _ -> panic
      }
    _ -> panic
  }

  let new_grid = glearray.copy_set(grid, y, new_row)

  case new_grid {
    Ok(value) -> value
    _ -> panic
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
