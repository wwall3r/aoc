defmodule Day13Part1 do
  def main() do
    File.read!("input")
    |> String.trim()
    |> String.split("\n\n")
    |> Enum.reduce(0, &process/2)
    |> IO.puts()
  end

  defp process(str, sum) do
    grid =
      str
      |> parse_grid()

    str_len = String.length(Enum.at(grid, 0))
    grid_len = length(grid)

    x =
      grid
      |> rotate()
      |> y_reflection()
      |> Enum.sum()

    y =
      grid
      |> y_reflection()
      |> Enum.map(fn y -> y * 100 end)
      |> Enum.sum()

    # string diff in reflection. If only one, return

    sum + x + y
  end

  defp parse_grid(str) do
    str
    |> String.trim()
    |> String.split("\n")
  end

  defp y_reflection(strs) do
    strs_len = length(strs)

    1..strs_len
    |> Enum.reduce([], fn i, ys ->
      distance = min(i, strs_len - i)

      top =
        strs
        |> Enum.slice(max(0, i - distance)..min(strs_len, i - 1))

      bottom =
        strs
        |> Enum.slice(i..min(strs_len, i + distance - 1))
        |> Enum.reverse()

      cond do
        i == strs_len -> ys
        distance == 0 -> ys
        top == bottom -> [i | ys]
        true -> ys
      end
    end)
  end

  defp print_grid(grid) do
    IO.puts("")

    grid
    |> Enum.join("\n")
    |> IO.puts()

    grid
  end

  defp rotate(grid) do
    map =
      grid
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {row_str, y}, map ->
        row_str
        |> String.graphemes()
        |> Enum.with_index()
        |> Enum.reduce(map, fn {grapheme, x}, map ->
          Map.put(map, "#{x},#{y}", grapheme)
        end)
      end)

    max_x =
      grid
      |> Enum.at(0)
      |> String.length()

    max_y = length(grid)

    0..(max_x - 1)
    |> Enum.map(fn y ->
      (max_y - 1)..0
      |> Enum.reduce("", fn x, str ->
        str <> Map.get(map, "#{y},#{x}")
      end)
    end)
  end

  defp print_grid(grid) do
    IO.puts("")

    grid
    |> Enum.join("\n")
    |> IO.puts()

    grid
  end
end

Day13Part1.main()
