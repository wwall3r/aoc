defmodule Day5Part2 do
  # Note: way too slow

  def main do
    sections =
      File.read!("input")
      |> String.split("\n\n")
      |> Enum.map(&parse_section/1)

    seeds = Enum.at(sections, 0)
    maps = List.delete_at(sections, 0)
    IO.puts("maps #{inspect(maps)}")

    seeds
    |> Enum.reduce(:infinity, fn seed_range, location ->
      seed_range
      |> Enum.reduce(location, fn seed, location ->
        l = get_location(seed, maps)

        min(location, l)
      end)
    end)
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
    |> String.replace(~r/(\d+ \d+)/, "\\1|")
    |> String.split("|")
    |> Enum.reject(fn s -> s == "" end)
    |> Enum.map(fn s ->
      s
      |> String.trim()
      |> String.split()
      |> Enum.map(&String.to_integer/1)
      |> list_to_range()
    end)
    |> print_thing()
  end

  defp list_to_range([start, len]) do
    start..(start + len - 1)
    |> print_thing()
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

  defp get_location(v, maps) when is_integer(v) do
    maps
    |> Enum.reduce(v, fn map, value ->
      get_next_value(value, map)
    end)
  end

  defp get_next_value(v, map) do
    map
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
  end

  defp print_thing(n) do
    IO.puts(inspect(n))
    n
  end
end

Day5Part2.main()
