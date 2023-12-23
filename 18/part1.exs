defmodule Day18Part1 do
  # There may be a fancy way to resolve the corners such that you can use
  # a 2D polygon crossproduct area. However... implementing an outer flood
  # fill and subtracting it is easier.

  def main() do
    File.stream!("input")
    |> Enum.reduce({%{}, {0, 0}}, fn str, state ->
      {dir, amount, color} =
        str
        |> String.trim()
        |> parse_tuple()

      1..amount
      |> Enum.reduce(state, fn _, {map, {x, y} = pos} ->
        new_pos =
          case dir do
            "U" -> {x, y - 1}
            "D" -> {x, y + 1}
            "L" -> {x - 1, y}
            "R" -> {x + 1, y}
          end

        new_map = Map.put(map, "#{inspect(pos)}", {pos, color})

        {new_map, new_pos}
      end)
    end)
    |> elem(0)
    # |> render()
    |> area()
    |> IO.puts()
  end

  defp parse_tuple(str) do
    parts =
      str
      |> String.split(~r/\s+/)

    dir =
      parts
      |> Enum.at(0)

    num =
      parts
      |> Enum.at(1)
      |> String.to_integer()

    color =
      parts
      |> Enum.at(2)
      |> String.replace(~r/[^0-9a-f]/, "")

    {dir, num, color}
  end

  defp limits(map) do
    map
    |> Enum.reduce({nil, nil, nil, nil}, fn {k, {{x, y}, _}}, {min_x, min_y, max_x, max_y} ->
      min_x =
        case min_x do
          nil -> x
          mx -> min(x, mx)
        end

      max_x =
        case max_x do
          nil -> x
          mx -> max(x, mx)
        end

      min_y =
        case min_y do
          nil -> y
          my -> min(y, my)
        end

      max_y =
        case max_y do
          nil -> y
          my -> max(y, my)
        end

      {min_x, min_y, max_x, max_y}
    end)
  end

  defp render(map) do
    {min_x, min_y, max_x, max_y} = limits(map)

    min_y..max_y
    |> Enum.each(fn y ->
      min_x..max_x
      |> Enum.reduce("", fn x, str ->
        str <>
          case Map.has_key?(map, inspect({x, y})) do
            true -> "#"
            false -> "."
          end
      end)
      |> IO.puts()
    end)

    map
  end

  defp area(map) do
    {min_x, min_y, max_x, max_y} = limits = limits(map)

    total_area = (max_x - min_x + 1) * (max_y - min_y + 1)

    flooded =
      min_x..max_x
      |> Enum.reduce(%{}, fn x, flooded ->
        flooded
        |> flood(map, limits, [{x, min_y}])
        |> flood(map, limits, [{x, max_y}])
      end)

    flooded =
      min_y..max_y
      |> Enum.reduce(flooded, fn y, flooded ->
        flooded
        |> flood(map, limits, [{min_x, y}])
        |> flood(map, limits, [{max_x, y}])
      end)

    not_inside = map_size(flooded)

    total_area - not_inside
  end

  defp flood(flooded, map, limits, []) do
    flooded
  end

  defp flood(flooded, map, {min_x, min_y, max_x, max_y} = limits, [{x, y} = coord | coords_tail]) do
    key = inspect(coord)

    if Map.has_key?(map, key) or Map.has_key?(flooded, key) do
      flood(flooded, map, limits, coords_tail)
    else
      flooded = Map.put(flooded, key, true)

      new_coords =
        [
          {x + 1, y},
          {x - 1, y},
          {x, y + 1},
          {x, y - 1}
        ]
        |> Enum.reject(fn {x, y} ->
          x < min_x || x > max_x || y < min_y || y > max_y
        end)

      flood(flooded, map, limits, new_coords ++ coords_tail)
    end
  end
end

Day18Part1.main()
