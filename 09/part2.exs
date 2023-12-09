defmodule Day8Part2 do
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
      {new_list, _} =
        list
        |> Enum.reverse()
        |> Enum.reduce({[], nil}, fn n, {list, last} ->
          case last do
            nil -> {list, n}
            _ -> {[last - n | list], n}
          end
        end)

      head - get_next_value(new_list)
    end
  end
end

Day8Part2.main()
