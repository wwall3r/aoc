defmodule Day10Part1 do
  def main() do
    map =
      File.read!("input")
      |> String.trim()
      |> String.split()
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {row, y}, map ->
        row
        |> String.split("")
        |> Enum.filter(fn c -> c != "" end)
        |> Enum.with_index()
        |> Enum.reduce(map, fn {c, x}, map ->
          Map.put(map, "#{x},#{y}", {c, x, y})
        end)
      end)

    start = find_start(map)
    next = find_next_from_start(map, start)
    total_length = walk_loop(map, start, next, 1)

    IO.puts(Integer.floor_div(total_length, 2))
  end

  defp find_start(map) do
    map
    |> Enum.find(fn {_, {c, _, _}} -> c == "S" end)
    |> elem(1)
  end

  defp get_connections(nil, _), do: []

  defp get_connections({_, _} = pos, map) do
    pos
    |> get_node(map)
    |> get_connections(map)
  end

  defp get_connections({c, x, y}, map) do
    case c do
      "|" -> [{x, y - 1}, {x, y + 1}]
      "-" -> [{x + 1, y}, {x - 1, y}]
      "L" -> [{x + 1, y}, {x, y - 1}]
      "J" -> [{x - 1, y}, {x, y - 1}]
      "7" -> [{x - 1, y}, {x, y + 1}]
      "F" -> [{x + 1, y}, {x, y + 1}]
      _ -> []
    end
    |> Enum.map(fn pos -> get_node(pos, map) end)
  end

  defp find_next_from_start(map, {_, x, y} = start) do
    0..8
    |> Enum.map(fn i ->
      {x - 1 + rem(i, 3), y - 1 + Integer.floor_div(i, 3)}
    end)
    |> Enum.filter(fn pos ->
      pos
      |> get_node(map)
      |> get_connections(map)
      |> Enum.any?(fn node -> node == start end)
    end)
    |> Enum.at(0)
    |> get_node(map)
  end

  defp walk_loop(map, prev, curr, count) do
    curr
    |> get_connections(map)
    |> Enum.reject(fn node -> node == prev end)
    |> Enum.at(0)
    |> case do
      {"S", _, _} -> count + 1
      next -> walk_loop(map, curr, next, count + 1)
    end
  end

  defp get_node(nil, _), do: nil

  defp get_node({x, y}, map) do
    "#{x},#{y}"
    |> get_node(map)
  end

  defp get_node(key, map) when is_list(key) do
    key
    |> Enum.join(",")
    |> get_node(map)
  end

  defp get_node(key, map) do
    Map.get(map, key)
  end
end

Day10Part1.main()
