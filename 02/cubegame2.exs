defmodule CubeGame2 do
  def main do
    File.stream!("input")
    |> Enum.reduce(0, &reduceNumber/2)
    |> IO.puts()
  end

  defp reduceNumber(str, sum) do
    str
    |> String.trim()
    |> get_game_power()
    |> Kernel.+(sum)
  end

  defp get_game_power(str) do
    str
    |> String.split(":")
    |> Enum.at(1)
    |> String.split(";")
    |> Enum.reduce([0, 0, 0], &reduce_min_bag/2)
    |> Enum.reduce(1, fn n, power -> n * power end)
  end

  defp reduce_min_bag(str, maxs) do
    [
      String.replace(str, ~r/^.*?(\d+) red.*$/, "\\1"),
      String.replace(str, ~r/^.*?(\d+) green.*$/, "\\1"),
      String.replace(str, ~r/^.*?(\d+) blue.*$/, "\\1")
    ]
    |> Enum.map(&whitespace_to_empty/1)
    |> Enum.map(&to_integer/1)
    |> Enum.with_index()
    |> Enum.map(fn {n, i} -> max(n, Enum.at(maxs, i)) end)
  end

  defp to_integer(str) do
    case str do
      "" -> 0
      s -> String.to_integer(s)
    end
  end

  defp whitespace_to_empty(str) do
    case String.match?(str, ~r/ /) do
      true -> ""
      false -> str
    end
  end
end

CubeGame2.main()
