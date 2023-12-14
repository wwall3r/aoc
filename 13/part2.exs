defmodule Day13Part2 do
  def main() do
    File.read!("input")
    |> String.trim()
    |> String.split("\n\n")
    |> Enum.with_index()
    |> Enum.reduce(0, &process/2)
    |> IO.puts()
  end

  defp process({str, i}, sum) do
    grid =
      str
      |> parse_grid()

    IO.puts("puzzle #{i}")
    print_grid(grid)

    old_xs =
      grid
      |> rotate()
      |> y_reflection()
      |> MapSet.new()

    old_ys =
      grid
      |> y_reflection()
      |> MapSet.new()

    coord =
      grid
      |> rotate()
      |> print_grid()
      |> get_smudge_y(old_xs)

    coord =
      cond do
        coord == nil or coord == :more_than_one -> coord
        true -> rotate_coord(coord, grid)
      end

    coord =
      cond do
        # didn't find it scanning y so scan x
        coord == nil or coord == :more_than_one ->
          grid
          |> get_smudge_y(old_ys)

        true ->
          coord
      end

    grid = change_coord(coord, grid)

    x =
      grid
      |> rotate()
      |> y_reflection()
      |> Enum.reject(fn i -> MapSet.member?(old_xs, i) end)
      |> Enum.sum()
      |> dbg()

    y =
      grid
      |> y_reflection()
      |> Enum.reject(fn i -> MapSet.member?(old_ys, i) end)
      |> Enum.map(fn y -> y * 100 end)
      |> Enum.sum()
      |> dbg()

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

  defp get_smudge_y(strs, old_set) do
    strs_len = length(strs)

    1..strs_len
    |> Enum.reduce_while(nil, fn i, coord ->
      distance = min(i, strs_len - i)

      top =
        strs
        |> Enum.slice(max(0, i - distance)..min(strs_len, i - 1))

      bottom =
        strs
        |> Enum.slice(i..min(strs_len, i + distance - 1))
        |> Enum.reverse()

      new_coord = get_single_string_diff(top, bottom)

      cond do
        i == strs_len -> {:cont, coord}
        distance == 0 -> {:cont, coord}
        MapSet.member?(old_set, i) -> {:cont, coord}
        new_coord != nil and new_coord != :more_than_one -> {:halt, new_coord}
        true -> {:cont, coord}
      end
    end)
  end

  defp get_single_string_diff(strs1, strs2) do
    IO.puts("")

    if strs1 != strs2 do
      strs1
      |> Enum.zip(strs2)
      |> Enum.with_index()
      |> Enum.reduce(nil, fn {{str1, str2}, y}, coord ->
        String.graphemes(str1)
        |> Enum.zip(String.graphemes(str2))
        |> Enum.with_index()
        |> Enum.reduce(coord, fn {{c1, c2}, x}, coord ->
          cond do
            coord == :more_than_one ->
              coord

            coord != nil and c1 != c2 ->
              IO.puts("second diff found at #{x},#{y} of #{str1} and #{str2}")
              :more_than_one

            coord == nil and c1 != c2 ->
              IO.puts("found diff at #{x},#{y} of #{str1} and #{str2}")
              {x, y}

            true ->
              coord
          end
        end)
      end)
    else
      nil
    end
  end

  defp to_map(grid) do
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
  end

  defp rotate(grid) do
    map =
      grid
      |> to_map()

    max_x = max_x(grid)
    max_y = length(grid)

    0..(max_x - 1)
    |> Enum.map(fn y ->
      (max_y - 1)..0
      |> Enum.reduce("", fn x, str ->
        str <> Map.get(map, "#{y},#{x}")
      end)
    end)
  end

  defp max_x(grid) do
    grid
    |> Enum.at(0)
    |> String.length()
  end

  defp rotate_coord({x, y} = coord, grid) do
    IO.puts("rotating coord #{inspect(coord)}")
    max_y = length(grid)

    {y, max_y - 1 - x}
  end

  defp change_coord({x, y} = coord, grid) do
    IO.puts("changing coord #{inspect(coord)}")

    str = Enum.at(grid, y)

    piece =
      case String.slice(str, x, 1) do
        "." -> "#"
        "#" -> "."
      end

    str_begin = String.slice(str, 0, x)
    str_end = String.slice(str, x + 1, String.length(str))
    new_string = str_begin <> piece <> str_end

    grid
    |> Enum.with_index()
    |> Enum.map(fn {s, i} ->
      cond do
        i == y -> new_string
        true -> s
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
end

Day13Part2.main()
