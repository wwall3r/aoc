import argv
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import simplifile

type Direction {
  Increasing
  Decreasing
  Unknown
}

type State {
  State(direction: Direction, last: Int, valid: Bool)
}

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  content
  |> string.split("\n")
  |> list.map(string.trim)
  |> list.fold(0, fn(sum, line) {
    case line {
      "" -> sum
      _ -> {
        let report = parse_report(line)
        case process_report(report) {
          True -> sum + 1
          False -> sum
        }
      }
    }
  })
  |> io.debug()
}

fn parse_report(line: String) -> List(Int) {
  line
  |> string.split(" ")
  |> list.map(fn(part) {
    let assert Ok(num) = int.parse(part)
    num
  })
}

fn process_report(report: List(Int)) -> Bool {
  let initial: State = State(direction: Unknown, last: -1, valid: True)

  let state = list.index_fold(report, initial, get_reducer(-1))

  case state.valid {
    True -> state.valid
    False -> {
      // There are not enough of these in the input file to warrant doing something
      // smart. So just try dropping each item and see if it works.
      report
      |> list.index_map(fn(_, i) {
        let state = list.index_fold(report, initial, get_reducer(i))
        state.valid
      })
      |> list.any(function.identity)
    }
  }
}

const invalid: State = State(direction: Unknown, last: -1, valid: False)

fn get_reducer(ignore: Int) {
  fn(state: State, value: Int, index: Int) -> State {
    let State(direction, last, valid) = state

    case ignore == index {
      True -> state
      False -> {
        case valid {
          False -> state
          True -> {
            case last {
              -1 -> State(..state, last: value)
              _ -> {
                case direction {
                  Increasing -> {
                    case value > last && value <= last + 3 {
                      True -> State(..state, last: value)
                      False -> invalid
                    }
                  }
                  Decreasing -> {
                    case value < last && value >= last - 3 {
                      True -> State(..state, last: value)
                      False -> invalid
                    }
                  }
                  Unknown -> {
                    case value {
                      v if v > last && v <= last + 3 ->
                        State(..state, direction: Increasing, last: value)
                      v if v < last && v >= last - 3 ->
                        State(..state, direction: Decreasing, last: value)
                      _ -> invalid
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
