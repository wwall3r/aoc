defmodule Day4Part1 do
  def main do
    File.stream!("input")
    |> Enum.reduce(0, &reduce_total/2)
    |> IO.puts()
  end

  defp reduce_total(str, sum) do
    str
    |> String.trim()
    |> to_state()
    |> get_score()
    |> Kernel.+(sum)
  end

  defp to_state(str) do
    str
    |> String.split(":")
    |> Enum.at(1)
    |> String.split("|")
    |> Enum.map(fn num_list ->
      num_list
      |> String.trim()
      |> String.split()
      |> Enum.map(&String.to_integer/1)
      # can the card list have non-unique entries?
      |> MapSet.new()
    end)
  end

  defp get_score([winning, scratched]) do
    winning
    |> MapSet.intersection(scratched)
    |> MapSet.size()
    |> length_to_score()
  end

  defp length_to_score(n) do
    cond do
      n > 0 -> :math.pow(2, n - 1)
      true -> 0
    end
  end
end

Day4Part1.main()
