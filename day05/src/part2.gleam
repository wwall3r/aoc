import argv
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list.{Continue, Stop}
import gleam/order.{Eq, Gt, Lt}
import gleam/result
import gleam/set.{type Set}
import gleam/string
import simplifile

type RuleSet =
  Dict(String, Set(String))

type RuleSetState =
  #(RuleSet, RuleSet)

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  let assert [rule_lines, page_lines] = string.split(content, "\n\n")

  let initial_state: RuleSetState = #(dict.new(), dict.new())

  let #(less_thans, greater_thans) =
    rule_lines
    |> string.split("\n")
    |> list.map(string.trim)
    |> list.fold(initial_state, fn(state, line) {
      let assert [first, second] = string.split(line, "|")

      let #(lesser_thans, greater_thans) = state

      let new_set = case dict.get(lesser_thans, first) {
        Ok(lesser_set) -> set.insert(lesser_set, second)
        Error(Nil) -> set.from_list([second])
      }

      let new_lesser_thans = dict.insert(lesser_thans, first, new_set)

      let new_set = case dict.get(greater_thans, second) {
        Ok(greater_set) -> set.insert(greater_set, first)
        Error(Nil) -> set.from_list([first])
      }

      let new_greater_thans = dict.insert(greater_thans, second, new_set)

      #(new_lesser_thans, new_greater_thans)
    })

  page_lines
  |> string.split("\n")
  |> list.map(string.trim)
  |> list.filter(fn(str) { !string.is_empty(str) })
  |> list.map(fn(line) {
    let pages =
      line
      |> string.split(",")

    let sorted_pages =
      pages
      |> list.sort(fn(a, b) {
        let lt = is_in_ruleset(less_thans, a, b)
        let gt = is_in_ruleset(greater_thans, a, b)

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

fn is_in_ruleset(ruleset: RuleSet, a: String, b: String) -> Bool {
  ruleset
  |> dict.get(a)
  |> result.unwrap(set.new())
  |> set.contains(b)
}

fn parse_int(str: String) {
  let assert Ok(num) = int.parse(str)
  num
}

// wtf? no list.get? y'all are gonna make me use glearray for everything in this
fn list_get(items: List(a), index: Int) -> Result(a, Nil) {
  let #(_, val) =
    items
    |> list.fold_until(#(0, Error(Nil)), fn(state, item) {
      let #(i, _) = state

      case i == index {
        True -> Stop(#(i, Ok(item)))
        False -> Continue(#(i + 1, Error(Nil)))
      }
    })

  val
}
