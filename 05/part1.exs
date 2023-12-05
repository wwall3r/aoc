defmodule Day5Part1 do
  def main do
    File.read!("input")
    |> String.split("\n\n")
    |> Enum.map(&parse_section/1)
    |> Enum.reduce(nil, &reduce_locations/2)
    |> Enum.min()
    |> IO.puts()
  end

  defp parse_section(str) do
    if String.match?(str, ~r/ map:/) do
      parse_map(str)
    else
      parse_seed_list(str)
    end
  end

  defp parse_seed_list(str) do
    IO.puts("parse seeds")

    str
    |> String.trim()
    |> String.replace(~r/seeds\s*:\s*/, "")
    |> String.split()
    |> Enum.map(&String.to_integer/1)
  end

  defp parse_map(str) do
    IO.puts("parse_map")

    str
    |> String.split("\n")
    |> List.delete_at(0)
    |> Enum.reject(fn s -> s == "" end)
    |> Enum.map(fn s ->
      s
      |> String.split()
      |> Enum.map(&String.to_integer/1)
    end)
  end

  defp get_next_from_map_entry(n, [dest, source, len]) when is_integer(n) do
    if source <= n and n < source + len do
      dest + n - source
    else
      nil
    end
  end

  defp reduce_locations(item, values) when is_nil(values) do
    item
  end

  defp reduce_locations(next_ranges, values) do
    values
    |> Enum.map(fn v ->
      next_ranges
      |> Enum.reduce(nil, fn r, acc ->
        case acc do
          nil -> get_next_from_map_entry(v, r)
          _ -> acc
        end
      end)
      |> case do
        nil -> v
        i -> i
      end
    end)
  end
end

Day5Part1.main()
