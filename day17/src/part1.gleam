import argv
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/regexp
import gleam/result
import gleam/string
import glearray.{type Array}
import simplifile

pub type State {
  State(
    memory: Array(Int),
    register_a: Int,
    register_b: Int,
    register_c: Int,
    instruction: Int,
    output: String,
  )
}

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  let assert Ok(re) =
    regexp.compile(
      "[^\\d\\s]",
      regexp.Options(case_insensitive: False, multi_line: True),
    )

  let assert [register_lines, program_line] =
    re
    |> regexp.replace(content, " ")
    |> string.trim()
    |> string.split("\n\n")

  let assert [register_a, register_b, register_c] =
    register_lines
    |> string.split("\n")
    |> list.map(fn(line) {
      line
      |> string.trim()
      |> parse_int()
    })

  let memory =
    program_line
    |> string.trim()
    |> string.split(" ")
    |> list.map(parse_int)
    |> glearray.from_list()

  let state = State(memory, register_a, register_b, register_c, 0, "")

  let state = execute(state)
  io.debug(state.output)
}

fn execute(state: State) -> State {
  case state.instruction < glearray.length(state.memory) - 1 {
    False -> state
    True -> {
      let opcode =
        state.memory
        |> glearray.get(state.instruction)
        |> result.unwrap(-1)

      let operand =
        state.memory
        |> glearray.get(state.instruction + 1)
        |> result.unwrap(-1)

      let state = case opcode {
        0 -> adv(state, operand)
        1 -> bxl(state, operand)
        2 -> bst(state, operand)
        3 -> jnz(state, operand)
        4 -> bxc(state, operand)
        5 -> out(state, operand)
        6 -> bdv(state, operand)
        7 -> cdv(state, operand)
        _ -> panic as "unknown opcode"
      }

      execute(state)
    }
  }
}

fn get_combo(state: State, operand: Int) -> Int {
  case operand {
    o if o >= 0 && o <= 3 -> o
    4 -> state.register_a
    5 -> state.register_b
    6 -> state.register_c
    _ -> panic as "invalid combo operator"
  }
}

fn adv(state: State, operand: Int) -> State {
  State(
    ..state,
    register_a: dv(state, operand),
    instruction: state.instruction + 2,
  )
}

fn bxl(state: State, operand: Int) -> State {
  let register_b = int.bitwise_exclusive_or(state.register_b, operand)
  State(..state, register_b:, instruction: state.instruction + 2)
}

fn bst(state: State, operand: Int) -> State {
  let register_b = get_combo(state, operand) % 8
  State(..state, register_b:, instruction: state.instruction + 2)
}

fn jnz(state: State, operand: Int) -> State {
  case state.register_a {
    0 -> State(..state, instruction: state.instruction + 2)
    _ -> State(..state, instruction: operand)
  }
}

fn bxc(state: State, _operand: Int) -> State {
  let register_b = int.bitwise_exclusive_or(state.register_b, state.register_c)
  State(..state, register_b:, instruction: state.instruction + 2)
}

fn out(state: State, operand: Int) -> State {
  let value = get_combo(state, operand) % 8

  let str = case state.output |> string.length() > 0 {
    True -> state.output <> "," <> int.to_string(value)
    False -> state.output <> int.to_string(value)
  }

  State(..state, output: str, instruction: state.instruction + 2)
}

fn bdv(state: State, operand: Int) -> State {
  State(
    ..state,
    register_b: dv(state, operand),
    instruction: state.instruction + 2,
  )
}

fn cdv(state: State, operand: Int) -> State {
  State(
    ..state,
    register_c: dv(state, operand),
    instruction: state.instruction + 2,
  )
}

fn dv(state: State, operand: Int) -> Int {
  let denom = case int.power(2, get_combo(state, operand) |> int.to_float()) {
    Ok(n) -> n
    _ -> panic as "invalid power"
  }

  { { state.register_a |> int.to_float() } /. denom }
  |> float.truncate()
}

fn parse_int(str: String) -> Int {
  let assert Ok(num) = int.parse(str)
  num
}
