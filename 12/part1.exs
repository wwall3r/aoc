defmodule Day12Part1 do
  def main() do
    File.stream!("input")
    |> Enum.reduce(0, &sum_line/2)
    |> IO.puts()
  end

  defp sum_line(str, sum) do
    [springs, criteria] =
      str
      |> String.trim()
      |> String.split(" ")

    criteria =
      criteria
      |> String.split(",")
      |> Enum.map(&String.to_integer/1)

    # utter dog shit brute force version:
    # just generate all the permutations and check them
    #
    # $10 says part 2 makes us kick this to the curb
    sum +
      (springs
       |> get_permutations()
       |> Enum.filter(fn springs -> fits_criteria(springs, criteria) end)
       |> length())
  end

  defp get_permutations(str) when is_bitstring(str) do
    get_permutations([str])
  end

  defp get_permutations(list) when is_list(list) do
    list
    |> Enum.reduce([], fn str, new_list ->
      str
      |> String.contains?("?")
      |> case do
        true ->
          [
            String.replace(str, "?", ".", global: false),
            String.replace(str, "?", "#", global: false)
          ]
          |> get_permutations()
          |> Kernel.++(new_list)

        false ->
          [str | new_list]
      end
    end)
  end

  defp fits_criteria(springs, criteria) when is_list(springs) do
    springs
    |> Enum.join("")
    |> fits_criteria(criteria)
  end

  defp fits_criteria(springs, criteria) when is_bitstring(springs) do
    criteria ==
      springs
      |> String.split(~r/\.+/)
      |> Enum.filter(fn s -> s != "" end)
      |> Enum.map(&String.length/1)
  end
end

Day12Part1.main()
