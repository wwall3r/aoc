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

  let #(_, min_t) =
    yielder.range(1, 10_000)
    |> yielder.fold(#(0, 0), fn(state, second) {
      let #(min_distance, min_t) = state

      let distance =
        robots
        |> move(second)
        |> list.unique()
        |> get_total_distance()

      case distance < min_distance || min_t == 0 {
        True -> #(distance, second)
        False -> state
      }
    })

  robots
  |> move(min_t)
  |> set.from_list()
  |> print_grid()
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

fn get_total_distance(coords: List(Coord)) -> Int {
  list.fold(coords, 0, fn(distance, coord) {
    let #(x, y) = coord
    distance + { x * x } + { y * y }
  })
}

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
