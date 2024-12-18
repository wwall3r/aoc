import argv
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import simplifile

type Coord =
  #(Int, Int)

const target = #(70, 70)

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  let bytes =
    content
    |> string.trim()
    |> string.split("\n")
    |> list.map(fn(line) {
      let assert [x, y] =
        line
        |> string.split(",")
        |> list.map(parse_int)

      #(x, y)
    })

  let i =
    search(bytes, 0, list.length(bytes) - 1)
    |> io.debug()

  bytes
  |> list.take(i + 1)
  |> list.last()
  |> result.unwrap(#(-1, -1))
  |> io.debug()
}

// ideas:
// - could binary search over bytes until we find the first one in which the 
//   exit is unreachable (which is ln(3450) / ln(2) or about 12 iterations)

fn search(array: List(Coord), left: Int, right: Int) -> Int {
  case right < left {
    True -> left
    False -> {
      let mid = { left + right } / 2

      let corrupted =
        array
        |> list.take(mid + 1)
        |> set.from_list()

      let exit_length =
        find_shortest(dict.new(), corrupted, [#(#(0, 0), 0)])
        |> dict.get(target)
        |> result.unwrap(-1)

      case exit_length {
        -1 -> search(array, left, mid - 1)
        _ -> search(array, mid + 1, right)
      }
    }
  }
}

fn find_shortest(
  visited: Dict(Coord, Int),
  corrupted: Set(Coord),
  neighbors: List(#(Coord, Int)),
) -> Dict(Coord, Int) {
  case neighbors {
    [] -> visited
    [#(coord, score), ..rest] -> {
      let existing =
        visited
        |> dict.get(coord)
        |> result.unwrap(-1)

      case score < existing || existing == -1 {
        False -> find_shortest(visited, corrupted, rest)
        True -> {
          let visited = visited |> dict.insert(coord, score)

          let neighbors =
            dirs
            |> list.map(fn(dir) { #(move(coord, dir), score + 1) })
            |> list.filter(fn(item) {
              let #(coord, _) = item
              let #(max_x, max_y) = target
              let #(x, y) = coord

              !set.contains(corrupted, coord)
              && x >= 0
              && y >= 0
              && x <= max_x
              && y <= max_y
            })
            |> list.append(rest)

          find_shortest(visited, corrupted, neighbors)
        }
      }
    }
  }
}

const dirs = [#(0, 1), #(0, -1), #(1, 0), #(-1, 0)]

fn move(coord: Coord, dir: Coord) -> Coord {
  let #(x, y) = coord
  let #(dx, dy) = dir
  #(x + dx, y + dy)
}

fn parse_int(str: String) -> Int {
  let assert Ok(num) = int.parse(str)
  num
}
