defmodule Day8Part1 do
  def main() do
    [dir_str | node_strs] =
      File.read!("input")
      |> String.trim()
      |> String.split(~r/\n+/)

    directions = parse_directions(dir_str)
    nodes = parse_nodes(node_strs)

    {"ZZZ", count} =
      process(directions, nodes, {"AAA", 0})
      |> dbg()
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

  defp process({dirs, len} = directions, nodes, {id, count}) do
    direction = Enum.at(dirs, rem(count, len))

    next =
      nodes
      |> Map.get(id)
      |> Enum.at(direction)

    case next do
      "ZZZ" -> {next, count + 1}
      _ -> process(directions, nodes, {next, count + 1})
    end
  end
end

Day8Part1.main()
