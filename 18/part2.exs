Mix.install([:aja])

defmodule Day18Part2 do
  # Well I suppose now that matters
  alias Aja.Vector

  def main() do
    File.stream!("sample")
    |> Enum.reduce({Vector.new([{0.5, 0.5}]), {0.5, 0.5}}, fn str, {vertices, pos} ->
      new_pos =
        str
        |> String.trim()
        |> parse_line()
        |> move(pos)

      vertices =
        vertices
        |> Vector.append(new_pos)

      {vertices, new_pos}
    end)
    |> elem(0)
    |> Kernel.inspect()
    |> IO.puts()
  end

  defp parse_line(str) do
    # str
    # |> String.split(~r/\s+/)
    # |> Enum.at(2)
    # |> String.replace(~r/[^0-9a-f]/, "")
    # |> String.split_at(5)
    # |> Tuple.to_list()
    # |> Enum.map(fn s -> String.to_integer(s, 16) end)

    str
    |> String.replace("R", "0")
    |> String.replace("D", "1")
    |> String.replace("L", "2")
    |> String.replace("U", "3")
    |> String.split(~r/\s+/)
    |> Enum.slice(0..1)
    |> Enum.map(&String.to_integer/1)
    |> Enum.reverse()
  end

  defp move([amount, dir], {x, y}) do
    # amount = amount + 1

    case dir do
      0 -> {x + amount, y}
      1 -> {x, y + amount}
      2 -> {x - amount, y}
      3 -> {x, y - amount}
    end
  end

  defp limits(vertices) do
    vertices
    |> Vector.reduce({nil, nil, nil, nil}, fn {x, y}, {min_x, min_y, max_x, max_y} ->
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

  defp area(map) do
  end
end

Day18Part2.main()
