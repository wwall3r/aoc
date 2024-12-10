import argv
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  let line =
    content
    |> string.trim()

  let #(_, disk, _) =
    line
    |> string.to_graphemes()
    |> list.fold(#(False, "", 0), fn(state, c) {
      let #(is_free_space, disk, id) = state
      let len = parse_int(c) + string.length(disk)

      let disk = case is_free_space {
        True -> string.pad_end(disk, len, ".")
        False -> string.pad_end(disk, len, int.to_string(id))
      }

      let id = case is_free_space {
        True -> id + 1
        False -> id
      }

      #(!is_free_space, disk, id)
    })

  let reverse_disk =
    disk
    |> string.replace(".", "")
    |> string.reverse()
    |> string.to_graphemes()

  disk
  |> string.to_graphemes()
  |> compact(reverse_disk)
  |> list.index_fold(0, fn(sum, item, index) { sum + parse_int(item) * index })
  |> io.debug()
}

fn compact(disk: List(String), reverse_disk: List(String)) -> List(String) {
  let #(disk, reverse_disk) =
    disk
    |> list.fold(#([], reverse_disk), fn(state, c) {
      let #(disk, reverse_disk) = state
      case c {
        "." -> {
          let replacement =
            reverse_disk
            |> list.first()

          let replacement = case replacement {
            Ok(r) -> r
            Error(_) -> panic as "No replacement available"
          }

          let reverse_disk =
            reverse_disk
            |> list.rest()
            |> result.unwrap([])

          #([replacement, ..disk], reverse_disk)
        }
        c -> #([c, ..disk], reverse_disk)
      }
    })

  disk
  |> list.drop(list.length(reverse_disk))
  |> list.filter(fn(str) { !string.is_empty(str) })
  |> list.reverse()
}

fn print_disk(disk: List(String)) {
  disk
  |> string.join("")
  |> io.debug()

  disk
}

fn parse_int(str: String) -> Int {
  let assert Ok(num) = int.parse(str)
  num
}
