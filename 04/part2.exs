defmodule Day4Part2 do
  def main do
    card_map =
      File.stream!("input")
      |> Enum.reduce(%{}, &reduce_map/2)
      |> Enum.reduce(%{}, &reduce_to_copied_cards/2)

    1..map_size(card_map)
    |> Enum.reduce(0, fn i, sum -> sum + count_card(i, card_map) end)
    |> IO.puts()
  end

  defp reduce_map(str, state) do
    card =
      str
      |> String.trim()
      |> to_card()

    Map.put(state, elem(card, 0), card)
  end

  defp to_card(str) do
    [winning, scratched] = get_winning_and_scratched(str)
    id = get_id(str)
    {id, winning, scratched}
  end

  defp get_id(str) do
    str
    |> String.replace(~r/^Card\s+(\d+):.*$/, "\\1")
    |> String.to_integer()
  end

  defp get_winning_and_scratched(str) do
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

  defp reduce_to_copied_cards({_, {id, winning, scratched}}, card_map) do
    Map.put(
      card_map,
      id,
      case get_win_count(winning, scratched) do
        0 -> []
        n -> (id + 1)..(id + n)
      end
    )
  end

  defp get_win_count(winning, scratched) do
    winning
    |> MapSet.intersection(scratched)
    |> MapSet.size()
  end

  defp count_card(i, card_map) do
    1 +
      (Map.get(card_map, i)
       |> Enum.map(fn i -> count_card(i, card_map) end)
       |> Enum.sum())
  end
end

Day4Part2.main()
