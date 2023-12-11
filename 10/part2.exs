defmodule Day10Part2 do
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

    # return loop instead of length
    loop = walk_loop(map, start, next, %{})

    # get the bounds of the loop
    {{_, {_, _, min_y}}, {_, {_, _, max_y}}} =
      loop
      |> Enum.min_max_by(fn {_, {_, _, y}} -> y end)

    {{_, {_, min_x, _}}, {_, {_, max_x, _}}} =
      loop
      |> Enum.min_max_by(fn {_, {_, x, _}} -> x end)

    # replace S with the actual pipe section
    loop = fix_start(loop, start)

    (min_y + 1)..(max_y - 1)
    |> Enum.reduce(0, fn y, sum ->
      {_, _, row_sum} =
        min_x..max_x
        |> Enum.reduce({false, "", 0}, fn x, {is_inside, bend, sum} = state ->
          node = get_node({x, y}, loop)

          c =
            case node do
              nil -> nil
              _ -> elem(node, 0)
            end

          # this might require replacing S with its actual piece?
          cond do
            bend == "F" and c == "J" -> {!is_inside, "", sum}
            bend == "L" and c == "7" -> {!is_inside, "", sum}
            bend != "" and c != "-" -> {is_inside, "", sum}
            c == "|" -> {!is_inside, "", sum}
            c == nil and is_inside -> {is_inside, "", sum + 1}
            c != nil and c =~ ~r/[FJ7L]/ -> {is_inside, c, sum}
            true -> state
          end
        end)

      sum + row_sum
    end)
    |> IO.puts()
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

  defp find_next_from_start(map, start) do
    map
    |> get_start_connections(start)
    |> Enum.at(0)
    |> get_node(map)
  end

  defp get_start_connections(map, {_, x, y} = start) do
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
  end

  defp fix_start(map, {_, sx, sy} = start) do
    [{x0, y0}, {x1, y1}] = get_start_connections(map, start)

    c =
      cond do
        x0 == x1 -> "|"
        y0 == y1 -> "-"
        x0 > x1 and y0 < y1 -> "F"
        x0 < x1 and y0 < y1 -> "7"
        x0 > x1 and y0 > y1 -> "L"
        x0 < x1 and y0 > y1 -> "J"
        true -> nil
      end

    put_node({c, sx, sy}, map)
  end

  defp walk_loop(map, prev, curr, loop_map) do
    loop_map = put_node(curr, loop_map)

    next =
      curr
      |> get_connections(map)
      |> Enum.reject(fn node -> node == prev end)
      |> Enum.at(0)

    if elem(next, 0) == "S" do
      put_node(next, loop_map)
    else
      walk_loop(map, curr, next, loop_map)
    end
  end

  defp get_node(nil, _), do: nil

  defp get_node({x, y}, map) do
    "#{x},#{y}"
    |> get_node(map)
  end

  defp get_node({_, x, y}, map) do
    get_node({x, y}, map)
  end

  defp get_node(key, map) when is_list(key) do
    key
    |> Enum.join(",")
    |> get_node(map)
  end

  defp get_node(key, map) do
    Map.get(map, key)
  end

  defp put_node({_, x, y} = node, map) do
    Map.put(map, "#{x},#{y}", node)
  end
end

Day10Part2.main()
