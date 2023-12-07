defmodule Day7Part2 do
  @cards ~c"J23456789TQKA"

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
    |> handle_jokers()
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

  defp handle_jokers(map) do
    j_key = Enum.at(@cards, 0)
    j_count = Map.get(map, j_key, 0)

    {best_card, count} =
      map
      |> Enum.sort(fn {a, _}, {b, _} ->
        # hacky way of converting char/integer() back to string
        str_a = List.to_string([a])
        str_b = List.to_string([b])
        compare_cards(str_a, str_b)
      end)
      |> Enum.reduce({0, 0}, fn {k, v} = item, {_, max} = state ->
        cond do
          k == j_key -> state
          v >= max -> item
          state == nil -> item
          true -> state
        end
      end)

    {best_card, count} =
      cond do
        # got five Js
        best_card == 0 and count == 0 -> {j_key, j_count}
        true -> {best_card, count + j_count}
      end

    map
    |> Map.delete(j_key)
    |> Map.put(best_card, count)
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

Day7Part2.main()
