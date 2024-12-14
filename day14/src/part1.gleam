import argv
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/regexp
import gleam/string
import gleam_community/maths/arithmetics
import simplifile

type Coord =
  #(Int, Int)

type Velocity =
  Coord

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

  robots
  |> part1(101, 103, 100)
  |> io.debug()
}

fn part1(
  robots: List(#(Coord, Velocity)),
  width: Int,
  height: Int,
  seconds: Int,
) {
  robots
  |> list.map(fn(robot) {
    let #(#(x, y), #(vx, vy)) = robot
    let new_x = arithmetics.int_euclidean_modulo(x + vx * seconds, width)
    let new_y = arithmetics.int_euclidean_modulo(y + vy * seconds, height)

    #(new_x, new_y)
  })
  |> list.fold(dict.new(), fn(quadrants, coord) {
    let half_x = width / 2
    let half_y = height / 2

    let quadrant = case coord {
      #(x, y) if x < half_x && y < half_y -> Some(0)
      #(x, y) if x > half_x && y < half_y -> Some(1)
      #(x, y) if x < half_x && y > half_y -> Some(2)
      #(x, y) if x > half_x && y > half_y -> Some(3)
      _ -> None
    }

    case quadrant {
      Some(n) -> {
        dict.upsert(quadrants, n, fn(existing) {
          case existing {
            Some(n) -> n + 1
            None -> 1
          }
        })
      }
      None -> quadrants
    }
  })
  |> dict.values()
  |> list.fold(1, fn(acc, n) { acc * n })
}

fn parse_int(str: String) -> Int {
  let assert Ok(num) = int.parse(str)
  num
}
