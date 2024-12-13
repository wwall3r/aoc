import argv
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/order.{type Order, Eq}
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
  Region(
    plant: String,
    area: Int,
    perimeter: Set(List(Coord)),
    coords: Set(Coord),
  )
}

// changes:
// - switch sides to List(Coord) rather than List(String) and write comparator for
//   Coord
// - num corners should equal num sides, so write something to count those

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

    let region = Region(plant, 0, set.new(), set.new())
    let #(seen, region) = find_region(plants, seen, region, coord)

    #(seen, [region, ..regions])
  })
  |> pair.second()
  |> list.filter(fn(region) { region.area != 0 })
  |> list.map(fn(region) { region.area * count_corners(region) })
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

      let coords = set.insert(region.coords, coord)

      let perimeter =
        coord
        |> get_next_coords()
        |> list.fold(region.perimeter, fn(perimeter, other) {
          let side =
            [coord, other]
            |> list.sort(coord_compare)

          case set.contains(perimeter, side) {
            True -> set.delete(perimeter, side)
            False -> set.insert(perimeter, side)
          }
        })

      let region = Region(..region, area: region.area + 1, perimeter:, coords:)

      get_next(plants, seen, region, coord)
      |> list.fold(#(seen, region), fn(state, coord) {
        let #(seen, region) = state
        find_region(plants, seen, region, coord)
      })
    }
  }
}

fn count_corners(region: Region) -> Int {
  region.coords
  |> set.to_list()
  |> list.map(fn(coord) {
    coord
    |> get_corners()
    |> list.filter(fn(corner) {
      let assert [side1, side2, diagonal] =
        corner
        |> list.map(fn(coord) { set.contains(region.coords, coord) })

      { side1 != diagonal && side2 != diagonal } || { !side1 && !side2 }
    })
  })
  |> list.flatten()
  |> list.map(fn(corner) { list.sort(corner, coord_compare) })
  |> set.from_list()
  |> set.size()
}

const up = #(0, -1)

const down = #(0, 1)

const right = #(1, 0)

const left = #(-1, 0)

const left_up = #(-1, -1)

const right_up = #(1, -1)

const left_down = #(-1, 1)

const right_down = #(1, 1)

const dirs = [down, up, right, left]

const corners = [
  [left, down, left_down], [left, up, left_up], [right, down, right_down],
  [right, up, right_up],
]

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
  |> list.map(fn(dir) { move(coord, dir) })
}

fn get_corners(coord: Coord) -> List(List(Coord)) {
  corners
  |> list.map(fn(corner) { list.map(corner, fn(dir) { move(coord, dir) }) })
}

fn move(coord: Coord, dir: Coord) -> Coord {
  let #(x, y) = coord
  let #(dx, dy) = dir
  #(x + dx, y + dy)
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

fn coord_compare(a: Coord, b: Coord) -> Order {
  let #(ax, ay) = a
  let #(bx, by) = b

  case int.compare(ax, bx) {
    Eq -> int.compare(ay, by)
    c -> c
  }
}
