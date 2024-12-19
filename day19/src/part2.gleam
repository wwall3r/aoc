import argv
import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/pair
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
  |> list.fold(#(dict.new(), 0), fn(state, pattern) {
    let #(seen, sum) = state
    let #(seen, score) = possibilities([pattern], towels, seen)
    #(seen, sum + score)
  })
  |> pair.second()
  |> io.debug()
}

fn possibilities(
  patterns: List(String),
  towels: List(String),
  seen: Dict(String, Int),
) -> #(Dict(String, Int), Int) {
  case patterns {
    [] -> #(seen, 0)
    _ -> {
      patterns
      |> list.fold(#(seen, 0), fn(state, pattern) {
        let #(seen, sum) = state
        let existing = seen |> dict.get(pattern)

        case existing {
          Ok(n) -> #(seen, sum + n)
          Error(Nil) -> {
            let #(seen, score) = case pattern {
              "" -> #(seen, 1)
              _ -> {
                let next_patterns =
                  towels
                  |> list.filter(fn(towel) {
                    string.starts_with(pattern, towel)
                  })
                  |> list.map(fn(towel) {
                    string.drop_start(pattern, string.length(towel))
                  })

                possibilities(next_patterns, towels, seen)
              }
            }

            let seen = seen |> dict.insert(pattern, score)
            #(seen, sum + score)
          }
        }
      })
    }
  }
}
