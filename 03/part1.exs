defmodule Day3Part1 do
  def main do
    {_, _, sum} =
      File.stream!("input")
      |> Enum.reduce({{[], []}, {[], []}, 0}, &reduceState/2)

    sum
    |> IO.puts()
  end

  defp reduceState(str, {_, current, sum}) do
    {
      current,
      str
      |> String.trim()
      |> to_state(),
      sum
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

    symbols =
      ~r/[^\d.]/
      |> Regex.scan(str, return: :index)
      |> List.flatten()

    {Enum.zip(nums, indexes), symbols}
  end

  defp process_state({last, current, sum}) do
    {last, sum} = process_one(last, elem(current, 1), sum)
    {current, sum} = process_one(current, elem(last, 1), sum)

    {last, current, sum}
  end

  defp process_one({numbers, symbols}, other_symbols, sum) do
    buckets =
      numbers
      |> Enum.group_by(fn {_, num_index} ->
        (symbols ++ other_symbols)
        |> Enum.any?(fn symbol -> in_range?(symbol, num_index) end)
      end)

    {
      {
        Map.get(buckets, false, []),
        symbols
      },
      Map.get(buckets, true, [])
      |> Enum.reduce(sum, fn {n, _}, acc -> acc + n end)
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
end

Day3Part1.main()
