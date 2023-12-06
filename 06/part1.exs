defmodule Day6Part1 do
  def main() do
    File.read!("input")
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&parse_numbers/1)
    |> Enum.zip()
    |> Enum.map(&get_wins/1)
    |> Enum.product()
    |> dbg()
  end

  def parse_numbers(str) do
    str
    |> String.replace(~r/^.*:/, "")
    |> String.trim()
    |> String.split()
    |> Enum.map(&String.to_integer/1)
  end

  # there's probably a quadratic equation solve which can compute this directly,
  # but the numbers in my input set aren't big enough to kill the output
  def get_wins({time, distance}) do
    1..(time - 1)
    |> Enum.reduce(0, fn t, count ->
      cond do
        t * (time - t) > distance -> count + 1
        true -> count
      end
    end)
  end
end

Day6Part1.main()
