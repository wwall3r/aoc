import argv
import gleam/int
import gleam/io
import gleam/list.{Continue, Stop}
import gleam/order.{Eq, Gt, Lt}
import gleam/result
import gleam/set
import gleam/string
import simplifile

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)
  let assert [rule_lines, page_lines] = string.split(content, "\n\n")

  let rules =
    rule_lines
    |> string.split("\n")
    |> set.from_list()

  page_lines
  |> string.split("\n")
  |> list.filter(fn(str) { !string.is_empty(str) })
  |> list.map(fn(line) {
    let pages = string.split(line, ",")

    let sorted_pages =
      list.sort(pages, fn(a, b) {
        let lt = set.contains(rules, a <> "|" <> b)
        let gt = set.contains(rules, b <> "|" <> a)

        case lt, gt {
          True, False -> Lt
          False, True -> Gt
          _, _ -> Eq
        }
      })

    let sorted = string.join(sorted_pages, ",")

    case line == sorted {
      True -> 0
      False -> {
        sorted_pages
        |> list_get(
          sorted_pages
          |> list.length()
          |> int.floor_divide(2)
          |> result.unwrap(-3),
        )
        |> result.unwrap("")
        |> parse_int()
      }
    }
  })
  |> int.sum()
  |> io.debug()
}

fn parse_int(str: String) {
  let assert Ok(num) = int.parse(str)
  num
}

// wtf? no list.get? y'all are gonna make me use glearray for everything in this
fn list_get(items: List(a), index: Int) -> Result(a, Nil) {
  let #(_, val) =
    list.fold_until(items, #(0, Error(Nil)), fn(state, item) {
      let #(i, _) = state

      case i == index {
        True -> Stop(#(i, Ok(item)))
        False -> Continue(#(i + 1, Error(Nil)))
      }
    })

  val
}
