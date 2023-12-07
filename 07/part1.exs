defmodule Day7Part1 do
  @cards ~c"23456789TJQKA"

  def main() do
    File.read!("input")
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&parse_hand/1)
    |> Enum.sort(&sort_hands/2)
    |> Enum.with_index()
    |> Enum.reduce(0, fn {{_, bid, _}, i}, sum ->
      sum + bid * (i + 1)
    end)
    |> IO.puts()
  end

  def parse_hand(str) do
    [hand, bid] =
      str
      |> String.trim()
      |> String.split(" ")

    {
      hand,
      String.to_integer(bid),
      to_hand_type(hand)
    }
  end

  defp to_hand_type(hand) do
    hand
    |> String.to_charlist()
    |> Enum.reduce(%{}, fn c, map ->
      prev = Map.get(map, c, 0)
      Map.put(map, c, prev + 1)
    end)
    |> Map.values()
    |> Enum.sort()
    |> case do
      [5] -> 1
      [1, 4] -> 2
      [2, 3] -> 3
      [1, 1, 3] -> 4
      [1, 2, 2] -> 5
      [1, 1, 1, 2] -> 6
      [1, 1, 1, 1, 1] -> 7
    end
  end

  defp sort_hands({hand1, _, type1}, {hand2, _, type2}) do
    cond do
      type1 > type2 -> true
      type1 < type2 -> false
      type1 == type2 -> compare_cards(hand1, hand2)
      true -> true
    end
  end

  defp compare_cards(hand1, hand2) do
    hand1
    |> to_values()
    |> Enum.zip(to_values(hand2))
    |> Enum.reduce_while(false, fn {v1, v2}, _ ->
      cond do
        v1 > v2 -> {:halt, false}
        v1 < v2 -> {:halt, true}
        true -> {:cont, false}
      end
    end)
  end

  defp to_values(hand) do
    hand
    |> String.to_charlist()
    |> Enum.map(fn c ->
      Enum.find_index(@cards, fn i -> c == i end)
    end)
  end
end

Day7Part1.main()
