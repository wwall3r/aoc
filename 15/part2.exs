defmodule Day15Part2 do
  def main() do
    File.read!("input")
    |> String.replace(~r/\n/, "")
    |> String.split(",")
    |> Enum.reduce(%{}, &process/2)
    |> Enum.reduce(0, fn {box_num, list}, sum ->
      sum +
        (list
         |> Enum.with_index()
         |> Enum.map(fn {{k, v}, i} ->
           (box_num + 1) * (i + 1) * v
         end)
         |> Enum.sum())
    end)
    |> IO.puts()
  end

  def process(str, map) do
    {key, value} = item = to_tuple(str)

    hash =
      key
      |> String.to_charlist()
      |> Enum.reduce(0, fn i, sum ->
        rem((sum + i) * 17, 256)
      end)

    cond do
      str =~ "-" -> remove(item, map, hash)
      str =~ "=" -> add(item, map, hash)
    end
  end

  def remove({key, _} = item, map, hash) do
    box = Map.get(map, hash)

    case box do
      # nothing to remove
      nil ->
        map

      list ->
        new_list =
          list
          |> Enum.filter(fn {k, _} ->
            key != k
          end)

        Map.put(map, hash, new_list)
    end
  end

  def add({key, value} = item, map, hash) do
    box = Map.get(map, hash, [])

    case Enum.any?(box, fn {k, _} -> k == key end) do
      # can just map and replace
      true ->
        list =
          box
          |> Enum.map(fn {k, _} = i ->
            case k == key do
              true -> {k, value}
              false -> i
            end
          end)

        Map.put(map, hash, list)

      # add end
      false ->
        Map.put(map, hash, box ++ [{key, value}])
    end
  end

  defp to_tuple(str) do
    list =
      str
      |> String.split(~r/[=-]/)

    {
      Enum.at(list, 0),
      Enum.at(list, 1)
      |> case do
        "" -> nil
        s -> String.to_integer(s)
      end
    }
  end
end

Day15Part2.main()
