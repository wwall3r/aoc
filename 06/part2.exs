defmodule Day6Part2 do
  # Elixir uses Big Integer by default. Your numbers don't scare me.

  def main() do
    File.read!("input")
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&parse_number/1)
    |> get_wins()
    |> dbg()
  end

  def parse_number(str) do
    str
    |> String.replace(~r/[^\d]/, "")
    |> String.trim()
    |> String.to_integer()
  end

  # there's probably a quadratic equation solve which can compute this directly,
  # but the numbers in my input set aren't big enough to kill the output
  def get_wins([time, distance]) do
    1..(time - 1)
    |> Enum.reduce(0, fn t, count ->
      cond do
        t * (time - t) > distance -> count + 1
        true -> count
      end
    end)
  end
end

Day6Part2.main()
