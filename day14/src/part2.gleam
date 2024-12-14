import argv
import gleam/int
import gleam/io
import gleam/list
import gleam/regexp
import gleam/set.{type Set}
import gleam/string
import gleam/yielder
import gleam_community/maths/arithmetics
import simplifile

type Coord =
  #(Int, Int)

type Velocity =
  Coord

const width = 101

const height = 103

const threshold = 30

// Changes:
//
// It stands to reason that if it is going to make a picture, we probably want
// to find the largest contiguous region
// 
// The number of seconds to loop was a guess that I filtered down by starting
// the above threshold for region size at 5

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  let assert Ok(re) =
    regexp.compile(
      "-?\\d+",
      regexp.Options(case_insensitive: False, multi_line: True),
    )

  let robots =
    content
    |> string.trim()
    |> string.split("\n")
    |> list.map(fn(line) {
      let assert [x, y, vx, vy] =
        re
        |> regexp.scan(line)
        |> list.map(fn(match) { parse_int(match.content) })

      #(#(x, y), #(vx, vy))
    })

  yielder.range(1, 10_000)
  |> yielder.each(fn(second) {
    let new_robots =
      robots
      |> move(second)
      |> set.from_list()

    let largest_region_size = get_largest_region_size(new_robots)

    case largest_region_size > threshold {
      True -> {
        io.debug(second)
        print_grid(new_robots)
      }
      False -> new_robots
    }
  })
}

fn move(robots: List(#(Coord, Velocity)), seconds: Int) {
  robots
  |> list.map(fn(robot) {
    let #(#(x, y), #(vx, vy)) = robot
    let new_x = arithmetics.int_euclidean_modulo(x + vx * seconds, width)
    let new_y = arithmetics.int_euclidean_modulo(y + vy * seconds, height)
    #(new_x, new_y)
  })
}

fn get_largest_region_size(coords: Set(Coord)) -> Int {
  let #(_, max) =
    coords
    |> set.fold(#(set.new(), 0), fn(state, coord) {
      let #(_, max) = state
      let region = flood_fill(coords, coord, set.new())

      case region |> set.size() {
        n if n > max -> #(region, n)
        _ -> state
      }
    })

  max
}

fn flood_fill(coords: Set(Coord), coord: Coord, seen: Set(Coord)) -> Set(Coord) {
  case set.contains(coords, coord) {
    False -> seen
    True -> {
      case set.contains(seen, coord) {
        True -> seen
        False -> {
          let seen = seen |> set.insert(coord)

          dirs
          |> list.fold(seen, fn(seen, dir) {
            let #(x, y) = coord
            let #(dx, dy) = dir
            flood_fill(coords, #(x + dx, y + dy), seen)
            |> set.union(seen)
          })
        }
      }
    }
  }
}

const dirs = [#(0, 1), #(0, -1), #(1, 0), #(-1, 0)]

fn parse_int(str: String) -> Int {
  let assert Ok(num) = int.parse(str)
  num
}

fn print_grid(coords: Set(Coord)) -> Set(Coord) {
  yielder.range(0, height - 1)
  |> yielder.each(fn(y) {
    yielder.range(0, width - 1)
    |> yielder.fold("", fn(str, x) {
      str
      <> {
        case set.contains(coords, #(x, y)) {
          True -> "◼"
          False -> " "
        }
      }
    })
    |> io.debug()
  })

  coords
}
