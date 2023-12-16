Mix.install([:aja])

defmodule Day16Part1 do
  alias Aja.Vector

  def main() do
    grid =
      File.read!("input")
      |> String.trim()
      |> String.split("\n")
      |> Vector.new()
      |> Vector.map(fn str ->
        str
        |> String.graphemes()
        |> Vector.new()
      end)

    grid
    |> process_beams(MapSet.new(), [{{0, 0}, {1, 0}}])
    |> MapSet.size()
    |> IO.puts()
  end

  defp print_grid(grid) do
    {_, size_y} = sizes(grid)

    0..(size_y - 1)
    |> Enum.each(fn y ->
      Vector.at(grid, y)
      |> Enum.join("")
      |> IO.puts()
    end)

    grid
  end

  defp sizes(grid) do
    size_y =
      grid
      |> Vector.size()

    size_x =
      grid
      |> Vector.at(0)
      |> Vector.size()

    {size_x, size_y}
  end

  defp process_beams(grid, cycles, []) do
    MapSet.new()
  end

  defp process_beams(grid, cycles, [{{x, y} = pos, {dx, dy} = dir} = beam | beams_tail]) do
    energized = MapSet.new([pos])

    space =
      grid
      |> Vector.at(y)
      |> Vector.at(x)

    {size_x, size_y} = sizes(grid)

    IO.puts("processing #{inspect(pos)} going #{inspect(dir)} ")

    new_beams =
      cond do
        MapSet.member?(cycles, beam) ->
          []

        space == "." ->
          [{{x + dx, y + dy}, dir}]

        space == "/" and dx > 0 ->
          [{{x, y - 1}, {0, -1}}]

        space == "/" and dx < 0 ->
          [{{x, y + 1}, {0, 1}}]

        space == "/" and dy > 0 ->
          [{{x - 1, y}, {-1, 0}}]

        space == "/" and dy < 0 ->
          [{{x + 1, y}, {1, 0}}]

        space == "\\" and dx > 0 ->
          [{{x, y + 1}, {0, 1}}]

        space == "\\" and dx < 0 ->
          [{{x, y - 1}, {0, -1}}]

        space == "\\" and dy > 0 ->
          [{{x + 1, y}, {1, 0}}]

        space == "\\" and dy < 0 ->
          [{{x - 1, y}, {-1, 0}}]

        space == "|" and dx == 0 ->
          [{{x + dx, y + dy}, dir}]

        space == "|" and dy == 0 ->
          [
            {{x, y - 1}, {0, -1}},
            {{x, y + 1}, {0, 1}}
          ]

        space == "-" and dy == 0 ->
          [{{x + dx, y + dy}, dir}]

        space == "-" and dx == 0 ->
          [
            {{x - 1, y}, {-1, 0}},
            {{x + 1, y}, {1, 0}}
          ]
      end
      |> Enum.reject(fn {{x, y}, _} -> x < 0 || x >= size_x || y < 0 || y >= size_y end)

    cycles = MapSet.put(cycles, beam)

    grid
    |> process_beams(cycles, new_beams ++ beams_tail)
    |> MapSet.union(energized)
  end
end

Day16Part1.main()
