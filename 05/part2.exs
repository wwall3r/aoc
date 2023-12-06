defmodule Day5Part2 do
  # Note: adapting part1 directly and iterating seed ranges is way too slow for
  # the number sizes which are in the input

  def main do
    sections =
      File.read!("input")
      |> String.split("\n\n")
      |> Enum.map(&parse_section/1)

    seed_intervals =
      Enum.at(sections, 0)
      |> MapSet.new()

    maps = List.delete_at(sections, 0)

    maps
    |> Enum.reduce(seed_intervals, &reduce_map_to_intervals/2)
    |> Enum.map(fn {s, _} -> s end)
    |> Enum.min()
    |> IO.puts()
  end

  defp parse_section(str) do
    if String.match?(str, ~r/ map:/) do
      parse_map(str)
    else
      parse_seed_list(str)
    end
  end

  # parses seed ranges to a list of {start, end} intervals
  defp parse_seed_list(str) do
    str
    |> String.trim()
    |> String.replace(~r/seeds\s*:\s*/, "")
    |> String.replace(~r/(\d+ \d+)/, "\\1|")
    |> String.split("|")
    |> Enum.reject(fn s -> s == "" end)
    |> Enum.map(fn s ->
      s
      |> String.trim()
      |> String.split()
      |> Enum.map(&String.to_integer/1)
      |> list_to_interval()
    end)
  end

  defp list_to_interval(start, len) when is_integer(start) and is_integer(len) do
    {start, start + len - 1}
  end

  defp list_to_interval([start, len]) do
    list_to_interval(start, len)
  end

  # parses maps to a list of tuples {source, dest} of intervals {start, end}
  defp parse_map(str) do
    str
    |> String.split("\n")
    |> List.delete_at(0)
    |> Enum.reject(fn s -> s == "" end)
    |> Enum.map(fn s ->
      s
      |> String.split()
      |> Enum.map(&String.to_integer/1)
    end)
    |> Enum.map(fn [dest, source, len] ->
      {
        list_to_interval(source, len),
        list_to_interval(dest, len)
      }
    end)
  end

  defp reduce_map_to_intervals(map_entries, intervals) do
    intersections =
      map_entries
      |> Enum.reduce([], fn {source, dest}, list ->
        [
          intervals
          |> Enum.map(fn i -> {i, Interval.intersection(i, source), source, dest} end)
          |> Enum.reject(fn {_, i, _, _} -> is_nil(i) end)
          | list
        ]
      end)
      |> List.flatten()
      |> MapSet.new()

    intersects =
      intersections
      |> Enum.map(fn {i, _, _, _} -> i end)
      |> MapSet.new()

    disjoints =
      intervals
      |> MapSet.new()
      |> MapSet.difference(intersects)

    intersection_hits =
      intersections
      |> Enum.map(fn {_, i, _, _} -> i end)

    splits =
      intersections
      |> Enum.map(fn {original, _, _, _} ->
        intersection_hits
        |> Enum.reduce([original], fn i, curr ->
          curr
          |> Enum.map(fn c -> Interval.split(c, i) end)
          |> List.flatten()
        end)
      end)
      |> List.flatten()
      |> Interval.combine()
      |> MapSet.new()

    transformed =
      intersections
      |> Enum.map(fn {_, i, source, dest} ->
        source_to_dest(i, source, dest)
      end)
      |> MapSet.new()

    disjoints
    |> MapSet.union(transformed)
    |> MapSet.union(splits)
  end

  defp source_to_dest({i1, i2}, {s1, _}, {d1, _}) do
    {d1 + i1 - s1, d1 + i2 - s1}
  end

  def test() do
    {11, 12} = source_to_dest({1, 2}, {0, 5}, {10, 15})

    {1, 2} = Interval.intersection({1, 2}, {0, 5})
    {1, 2} = Interval.intersection({0, 5}, {1, 2})
    {3, 5} = Interval.intersection({0, 5}, {3, 10})
    {3, 5} = Interval.intersection({3, 10}, {0, 5})

    # left
    [{4, 4}] = Interval.split({4, 6}, {5, 7})
    # right
    [{8, 8}] = Interval.split({6, 8}, {5, 7})
    # surrounding
    [{4, 4}, {8, 8}] = Interval.split({4, 8}, {5, 7})
    # contained
    [] = Interval.split({6, 6}, {5, 7})
    # disjoint
    [{1, 10}] = Interval.split({1, 10}, {20, 30})

    [{3, 4}] = Interval.split({3, 6}, {5, 7})
    [{8, 9}] = Interval.split({6, 9}, {5, 7})
    [{3, 4}, {8, 9}] = Interval.split({3, 9}, {5, 7})

    [{1, 4}, {6, 12}] = Interval.combine([{1, 1}, {1, 3}, {2, 4}, {6, 10}, {11, 11}, {6, 12}])
    [{1, 12}] = Interval.combine([{1, 1}, {1, 3}, {2, 4}, {5, 10}, {11, 11}, {6, 12}])
    [{6, 13}] = Interval.combine([{8, 13}, {6, 11}])

    # barely disjoint left
    [{3, 4}] =
      reduce_map_to_intervals([{{5, 7}, {10, 12}}], [{3, 4}])
      |> MapSet.to_list()

    # barely disjoint right
    [{13, 14}] =
      reduce_map_to_intervals([{{5, 7}, {10, 12}}], [{13, 14}])
      |> MapSet.to_list()

    # overlap left edge
    [{4, 4}, {10, 11}] =
      reduce_map_to_intervals([{{5, 7}, {10, 12}}], [{4, 6}])
      |> MapSet.to_list()

    # overlap right edge
    [{8, 8}, {11, 12}] =
      reduce_map_to_intervals([{{5, 7}, {10, 12}}], [{6, 8}])
      |> MapSet.to_list()

    # completely inside map
    [{11, 11}] =
      reduce_map_to_intervals([{{5, 7}, {10, 12}}], [{6, 6}])
      |> MapSet.to_list()

    # completely surrounds map
    [{4, 4}, {8, 8}, {10, 12}] =
      reduce_map_to_intervals([{{5, 7}, {10, 12}}], [{4, 8}])
      |> MapSet.to_list()

    # exactly the same as map
    [{10, 12}] =
      reduce_map_to_intervals([{{5, 7}, {10, 12}}], [{5, 7}])
      |> MapSet.to_list()

    # overlaps two map entries
    IO.puts("overlaps two map entries")

    #  [{6, 7}, {8, 11}, {12, 13}]
    #     |                 |
    # [{11, 12}, {8, 11}, {20, 21}]

    [{8, 12}, {20, 21}] =
      [
        [{{5, 7}, {10, 12}}, {{12, 14}, {20, 22}}]
      ]
      |> Enum.reduce([{6, 13}], &reduce_map_to_intervals/2)
      |> Interval.combine()
  end
end

defmodule Interval do
  def combine(enumerable) do
    enumerable
    |> Enum.sort(&sort_intervals/2)
    |> Enum.reduce([nil, []], fn {s, e} = item, [curr, list] ->
      cond do
        curr == nil -> [item, list]
        elem(curr, 1) + 1 >= s -> [union(curr, item), list]
        true -> [item, [curr | list]]
      end
    end)
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.sort(&sort_intervals/2)
  end

  def union({a1, a2}, {b1, b2}) do
    {min(a1, b1), max(a2, b2)}
  end

  def intersects?({a1, a2}, {b1, b2}) do
    !(a2 < b1 || b2 < a1)
  end

  def intersection(a, b) do
    case intersects?(a, b) do
      true -> get_intersection(a, b)
      _ -> nil
    end
  end

  defp get_intersection({a1, a2}, {b1, b2}) do
    {max(a1, b1), min(a2, b2)}
  end

  def split({i0, i1} = interval, {r0, r1} = to_remove) do
    cond do
      # disjoint
      i1 < r0 or i0 > r1 -> [interval]
      # remove covers entire interval
      r0 <= i0 and i1 <= r1 -> []
      # remove middle intersection
      i0 < r0 and r1 < i1 -> [{i0, r0 - 1}, {r1 + 1, i1}]
      # remove right intersection
      i0 < r0 and i1 <= r1 -> [{i0, r0 - 1}]
      # remove left intersection
      i1 >= r0 and r1 < i1 -> [{r1 + 1, i1}]
    end
  end

  defp sort_intervals({a1, a2}, {b1, b2}) do
    a1 < b2 || a2 <= b2
  end
end

# Day5Part2.test()

Day5Part2.main()
