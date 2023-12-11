defmodule Day8Part2 do
  # I still think there might be a faster way to do this, because this is
  # a bit chunky.

  def main() do
    [dir_str | node_strs] =
      File.read!("input")
      |> String.trim()
      |> String.split(~r/\n+/)

    directions = parse_directions(dir_str)
    nodes = parse_nodes(node_strs)
    starts = get_starts(nodes)
    last_dir_index = elem(directions, 1) - 1

    # from the start nodes, create a map of start nodes to results,
    # where results are the navigate count for each index in the directions
    # list starting at that node.
    lists =
      starts
      |> Enum.reduce(%{}, fn start, map ->
        results =
          0..last_dir_index
          |> Enum.map(fn dir_index ->
            process(directions, nodes, dir_index, start, 0)
          end)

        Map.put(map, start, results)
      end)
      |> Map.values()

    # for each index in the directions, look vertically down the lists
    # and get the lcm of those values. Exit early for nils.
    0..last_dir_index
    |> Enum.map(fn i ->
      lists
      |> Enum.reduce(-1, fn list, m ->
        n = Enum.at(list, i)

        cond do
          m == -1 -> n
          n == nil -> nil
          true -> lcm(m, n)
        end
      end)
    end)
    |> Enum.min()
    |> IO.puts()
  end

  defp parse_directions(str) do
    dirs =
      str
      |> String.trim()
      |> String.replace("L", "0 ")
      |> String.replace("R", "1 ")
      |> String.trim()
      |> String.split()
      |> Enum.map(&String.to_integer/1)

    {dirs, length(dirs)}
  end

  defp parse_nodes(strs) do
    Enum.reduce(strs, %{}, fn str, map ->
      [node, left, right] =
        str
        |> String.trim()
        |> String.replace(~r/[=(),]/, "")
        |> String.split(~r/\s+/)

      Map.put(map, node, [left, right])
    end)
  end

  defp get_starts(nodes) do
    nodes
    |> Map.keys()
    |> Enum.filter(fn s -> String.ends_with?(s, "A") end)
  end

  defp process({dirs, len} = directions, nodes, dir_index, node, count) do
    direction = Enum.at(dirs, dir_index)

    next =
      nodes
      |> Map.get(node)
      |> Enum.at(direction)

    cond do
      next == node -> nil
      String.ends_with?(next, "Z") -> count + 1
      true -> process(directions, nodes, rem(dir_index + 1, len), next, count + 1)
    end
  end

  defp is_destination?(ids) do
    Enum.all?(ids, fn i -> String.ends_with?(i, "Z") end)
  end

  # least common multiple
  defp lcm(a, b) when is_number(a) and is_number(b) do
    a * Integer.floor_div(b, Integer.gcd(a, b))
  end

  defp lcm([head | tail] = list) do
    list
    |> Enum.reduce(head, fn n, prev -> lcm(prev, n) end)
  end
end

Day8Part2.main()
