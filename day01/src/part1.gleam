import argv
import gleam/io
import gleam/list
import gleam/string
import simplifile

pub fn main() {
  let assert [filename] = argv.load().arguments

  let assert Ok(content) = simplifile.read(from: filename)

  content
  |> string.split("\n")
  |> list.each(fn(line) { io.println(line) })
}
