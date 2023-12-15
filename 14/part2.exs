defmodule Day13Part2 do
  def main() do
    File.read!("input")
    |> String.trim()
    |> String.split("\n")
    |> parse_map()
    |> cycle()
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

  defp print_map(map) do
    IO.puts("")

    map
    |> to_strs()
    |> Enum.join("\n")
    |> IO.puts()

    map
  end

  defp to_strs(map) do
    maxes = get_max(map)
    to_strs(map, maxes)
  end

  defp to_strs(map, {max_x, max_y}) do
    0..max_y
    |> Enum.map(fn y ->
      0..max_x
      |> Enum.reduce("", fn x, str ->
        str <> Map.get(map, "#{x},#{y}", ".")
      end)
    end)
  end

  defp get_max(map) do
    map
    |> Enum.reduce({0, 0}, fn {k, _}, {max_x, max_y} ->
      [x, y] = to_list(k)
      {max(max_x, x), max(max_y, y)}
    end)
  end

  defp cycle(map) do
    cycles(%{}, %{}, get_max(map), 0, map)
  end

  defp cycles(cycle, seen, {max_x, max_y} = maxes, i, map) do
    map_key =
      map
      |> to_strs(maxes)
      |> Enum.join("\n")

    seen = Map.put(seen, map_key, i)
    cycle = Map.put(cycle, i, count_load(map))

    new_map =
      map
      |> move_rocks_ns(0..max_x, 0..max_y, 1)
      |> move_rocks_ew(0..max_x, 0..max_y, 1)
      |> move_rocks_ns(max_x..0, max_y..0, -1)
      |> move_rocks_ew(max_x..0, max_y..0, -1)

    new_map_key =
      new_map
      |> to_strs(maxes)
      |> Enum.join("\n")

    case Map.get(seen, new_map_key) do
      nil ->
        cycles(cycle, seen, maxes, i + 1, new_map)

      cycle_start ->
        cycle_length = i - cycle_start + 1
        remaining_spins = 1_000_000_000 - i - 1
        position = cycle_start + rem(remaining_spins, cycle_length)

        IO.puts(
          "detected cycle from #{cycle_start} with length #{cycle_length} at spin #{i} ending in position #{position} with remaining spins #{remaining_spins}"
        )

        IO.puts("#{inspect(cycle)}")
        Map.get(cycle, position)
    end
  end

  defp move_rocks_ns(map, range_x, range_y, dir) do
    d = if dir > 0, do: "N", else: "S"

    range_x
    |> Enum.reduce(map, fn x, map ->
      range_y
      |> Enum.reduce({map, nil}, fn y, {map, swap_idx} = state ->
        swap_idx =
          case swap_idx do
            nil -> y
            _ -> swap_idx
          end

        new_key = "#{x},#{y}"

        map
        |> Map.get(new_key, ".")
        |> case do
          "." -> {map, swap_idx}
          "#" -> {map, y + dir}
          "O" -> {swap(map, {x, y}, {x, swap_idx}), swap_idx + dir}
        end
      end)
      |> elem(0)
    end)
  end

  defp move_rocks_ew(map, range_x, range_y, dir) do
    d = if dir < 0, do: "E", else: "W"

    range_y
    |> Enum.reduce(map, fn y, map ->
      range_x
      |> Enum.reduce({map, nil}, fn x, {map, swap_idx} = state ->
        swap_idx =
          case swap_idx do
            nil -> x
            _ -> swap_idx
          end

        new_key = "#{x},#{y}"

        map
        |> Map.get(new_key, ".")
        |> case do
          "." -> {map, swap_idx}
          "#" -> {map, x + dir}
          "O" -> {swap(map, {x, y}, {swap_idx, y}), swap_idx + dir}
        end
      end)
      |> elem(0)
    end)
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

Day13Part2.main()
