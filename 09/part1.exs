defmodule Day8Part1 do
  def main() do
    File.stream!("input")
    |> Enum.map(&process_one/1)
    |> Enum.sum()
    |> IO.puts()
  end

  defp process_one(str) do
    str
    |> String.trim()
    |> String.split()
    |> Enum.map(&String.to_integer/1)
    |> get_next_value()
  end

  defp get_next_value([head | _] = list) do
    if Enum.all?(list, fn n -> n == 0 end) do
      0
    else
      reversed = Enum.reverse(list)

      {new_list, _} =
        Enum.reduce(reversed, {[], nil}, fn n, {list, last} ->
          case last do
            nil -> {list, n}
            _ -> {[last - n | list], n}
          end
        end)

      Enum.at(reversed, 0) + get_next_value(new_list)
    end
  end
end

Day8Part1.main()
