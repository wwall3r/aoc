defmodule CubeGame do
  def main do
    File.stream!("input")
    |> Enum.reduce(0, &reduceNumber/2)
    |> IO.puts()
  end

  defp reduceNumber(str, sum) do
    str
    |> String.trim()
    |> get_possible_game_id()
    |> Kernel.+(sum)
  end

  defp get_possible_game_id(str) do
    str
    |> String.split(":")
    |> Enum.at(1)
    |> String.split(";")
    |> Enum.all?(&is_valid_set?/1)
    |> case do
      true -> get_game_id(str)
      false -> 0
    end
  end

  defp is_valid_set?(str) do
    [
      String.replace(str, ~r/^.*?(\d+) red.*$/, "\\1"),
      String.replace(str, ~r/^.*?(\d+) green.*$/, "\\1"),
      String.replace(str, ~r/^.*?(\d+) blue.*$/, "\\1")
    ]
    |> Enum.map(&whitespace_to_empty/1)
    |> Enum.with_index()
    |> Enum.all?(fn {n, i} ->
      to_integer(n) <= i + 12
    end)
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

  defp get_game_id(str) do
    str
    |> String.split(":")
    |> Enum.at(0)
    |> String.split()
    |> Enum.at(1)
    |> String.to_integer()
  end
end

CubeGame.main()
