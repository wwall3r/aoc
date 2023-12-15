defmodule Day13Part1 do
  def main() do
    File.read!("input")
    |> String.trim()
    |> String.split("\n")
    |> parse_map()
    |> process()
    |> IO.puts()
  end

  defp parse_map(grid) do
    grid
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {row_str, y}, map ->
      row_str
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.reduce(map, fn {grapheme, x}, map ->
        case grapheme do
          "." -> map
          c -> Map.put(map, "#{x},#{y}", c)
        end
      end)
    end)
  end

  defp process(map) do
    map
    |> print_map()
    |> move_rocks()
    |> print_map()
    |> count_load()
  end

  defp print_map(map) do
    IO.puts("")

    {max_x, max_y} = get_max(map)

    0..max_y
    |> Enum.each(fn y ->
      0..max_x
      |> Enum.reduce("", fn x, str ->
        str <> Map.get(map, "#{x},#{y}", ".")
      end)
      |> IO.puts()
    end)

    map
  end

  defp get_max(map) do
    map
    |> Enum.reduce({0, 0}, fn {k, _}, {max_x, max_y} ->
      [x, y] = to_list(k)
      {max(max_x, x), max(max_y, y)}
    end)
  end

  defp move_rocks(map) do
    {max_x, max_y} = get_max(map)

    0..max_x
    |> Enum.reduce(map, fn x, map ->
      0..max_y
      |> Enum.reduce({map, 0}, fn y, {map, swap_idx} = state ->
        new_key = "#{x},#{y}"

        map
        |> Map.get(new_key, ".")
        |> case do
          "." -> state
          "#" -> {map, y + 1}
          "O" -> {swap(map, {x, y}, {x, swap_idx}), swap_idx + 1}
        end
      end)
      |> dbg()
      |> elem(0)
    end)
    |> dbg()
  end

  defp count_load(map) do
    {_, max_y} = get_max(map)

    map
    |> Enum.reduce(0, fn {key, v}, sum ->
      [_, y] = to_list(key)

      case v do
        "O" ->
          sum + max_y - y + 1

        _ ->
          sum
      end
    end)
  end

  defp swap(map, pos1, pos2) when is_tuple(pos1) and is_tuple(pos2) do
    key1 = to_key(pos1)
    key2 = to_key(pos2)

    v1 = Map.get(map, key1)
    v2 = Map.get(map, key2)

    map =
      cond do
        v2 != nil -> Map.put(map, key1, v2)
        true -> Map.delete(map, key1)
      end

    cond do
      v1 != nil -> Map.put(map, key2, v1)
      true -> Map.delete(map, key2)
    end
  end

  defp to_key({x, y}) do
    "#{x},#{y}"
  end

  defp to_list(key) when is_bitstring(key) do
    key
    |> String.split(",")
    |> Enum.map(&String.to_integer/1)
  end
end

Day13Part1.main()
