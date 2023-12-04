defmodule Day3Part2 do
  def main do
    {last, _, sum} =
      File.stream!("input")
      |> Enum.reduce({{[], []}, {[], []}, 0}, &reduce_state/2)

    last
    |> get_gear_ratios()
    |> Kernel.+(sum)
    |> Kernel.inspect()
    |> IO.puts()
  end

  defp reduce_state(str, {last, current, sum}) do
    {
      current,
      str
      |> String.trim()
      |> to_state(),
      sum + get_gear_ratios(last)
    }
    |> process_state()
  end

  defp to_state(str) do
    nums =
      ~r/\d+/
      |> Regex.scan(str)
      |> List.flatten()
      |> Enum.map(&String.to_integer/1)

    indexes =
      ~r/\d+/
      |> Regex.scan(str, return: :index)
      |> List.flatten()

    gears =
      ~r/[*]/
      |> Regex.scan(str, return: :index)
      |> List.flatten()

    {Enum.zip(nums, indexes), Enum.map(gears, fn g -> {g, []} end)}
  end

  defp process_state({last, current, sum}) do
    {
      process_one(last, elem(current, 0)),
      process_one(current, elem(last, 0)),
      sum
    }
  end

  defp process_one({numbers, gears}, other_numbers) do
    {
      numbers,
      gears
      |> Enum.map(fn {gear_index, gear_numbers} ->
        {
          gear_index,
          gear_numbers ++
            ((numbers ++ other_numbers)
             |> Enum.filter(fn {_, num_index} -> in_range?(gear_index, num_index) end))
        }
      end)
    }
  end

  defp in_range?(symbol, _) when is_nil(symbol), do: false
  defp in_range?(_, num_tuple) when is_nil(num_tuple), do: false

  defp in_range?({index, _}, {num_start, num_length}) do
    [
      num_start - index,
      num_start + num_length - index - 1
    ]
    |> Enum.map(&Kernel.abs/1)
    |> Enum.min()
    |> Kernel.<(2)
  end

  defp get_gear_ratios({_, gears}) do
    gears
    |> Enum.map(fn {gear, gear_numbers} ->
      {
        gear,
        gear_numbers
        |> Enum.uniq_by(fn t -> inspect(t) end)
        |> Enum.map(fn {n, _} -> n end)
      }
    end)
    |> Enum.filter(fn {_, gear_numbers} -> length(gear_numbers) == 2 end)
    |> Enum.reduce(0, fn {_, gear_numbers}, sum -> sum + Enum.product(gear_numbers) end)
  end
end

Day3Part2.main()
