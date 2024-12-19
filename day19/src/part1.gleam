import argv
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import simplifile

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  let assert [towel_line, pattern_lines] =
    content
    |> string.trim()
    |> string.split("\n\n")

  let towels =
    towel_line
    |> string.trim()
    |> string.split(", ")

  pattern_lines
  |> string.trim()
  |> string.split("\n")
  |> list.map(fn(pattern) { is_possible([pattern], towels) })
  |> int.sum()
  |> io.debug()
}

fn is_possible(patterns: List(String), towels: List(String)) -> Int {
  case patterns {
    [] -> 0
    [pattern, ..rest] -> {
      case pattern {
        "" -> 1
        _ -> {
          let next_patterns =
            towels
            |> list.filter(fn(towel) { string.starts_with(pattern, towel) })
            |> list.map(fn(towel) {
              string.drop_start(pattern, string.length(towel))
            })
            |> list.append(rest)

          is_possible(next_patterns, towels)
        }
      }
    }
  }
}
