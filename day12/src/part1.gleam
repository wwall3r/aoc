import argv
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/set.{type Set}
import gleam/string
import simplifile

type Plants =
  Dict(Coord, String)

type Coord =
  #(Int, Int)

type Seen =
  Set(Coord)

pub type Region {
  Region(plant: String, area: Int, perimeter: Set(List(String)))
}

pub fn main() {
  let assert [filename] = argv.load().arguments
  let assert Ok(content) = simplifile.read(from: filename)

  let plants: Plants =
    content
    |> string.trim()
    |> string.split("\n")
    |> list.index_fold(dict.new(), fn(plants, line, y) {
      line
      |> string.to_graphemes()
      |> list.index_fold(plants, fn(plants, plant, x) {
        let coord = #(x, y)
        dict.insert(plants, coord, plant)
      })
    })

  plants
  |> dict.keys()
  |> list.fold(#(set.new(), []), fn(state, coord) {
    let #(seen, regions) = state

    let plant = case dict.get(plants, coord) {
      Ok(p) -> p
      Error(Nil) -> panic as "Coord not in plants; This can't happen?"
    }

    let region = Region(plant, 0, set.new())
    let #(seen, region) = find_region(plants, seen, region, coord)

    #(seen, [region, ..regions])
  })
  |> pair.second()
  |> list.map(fn(region: Region) {
    region.area * { region.perimeter |> set.size() }
  })
  |> int.sum()
  |> io.debug()
}

fn find_region(
  plants: Plants,
  seen: Seen,
  region: Region,
  coord: Coord,
) -> #(Seen, Region) {
  case is_valid_coord(plants, seen, region, coord) {
    False -> #(seen, region)
    True -> {
      let seen = set.insert(seen, coord)

      let perimeter =
        coord
        |> get_next_coords()
        |> list.map(fn(other) {
          [coord, other]
          |> list.map(coord_to_string)
          |> list.sort(string.compare)
        })
        |> list.fold(region.perimeter, fn(perimeter, side) {
          case set.contains(perimeter, side) {
            True -> set.delete(perimeter, side)
            False -> set.insert(perimeter, side)
          }
        })

      let region = Region(..region, area: region.area + 1, perimeter:)

      get_next(plants, seen, region, coord)
      |> list.fold(#(seen, region), fn(state, coord) {
        let #(seen, region) = state
        find_region(plants, seen, region, coord)
      })
    }
  }
}

const dirs = [#(0, 1), #(0, -1), #(1, 0), #(-1, 0)]

fn get_next(
  plants: Plants,
  seen: Seen,
  region: Region,
  coord: Coord,
) -> List(Coord) {
  coord
  |> get_next_coords()
  |> list.filter(fn(coord) { is_valid_coord(plants, seen, region, coord) })
}

fn get_next_coords(coord: Coord) -> List(Coord) {
  dirs
  |> list.map(fn(dir) {
    let #(x, y) = coord
    let #(dx, dy) = dir
    #(x + dx, y + dy)
  })
}

fn is_valid_coord(
  plants: Plants,
  seen: Seen,
  region: Region,
  coord: Coord,
) -> Bool {
  case dict.get(plants, coord) {
    Ok(plant) -> !set.contains(seen, coord) && region.plant == plant
    _ -> False
  }
}

fn coord_to_string(coord: Coord) -> String {
  let #(x, y) = coord
  int.to_string(x) <> "," <> int.to_string(y)
}
