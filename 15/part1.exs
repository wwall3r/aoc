defmodule Day15Part1 do
  def main() do
    File.read!("input")
    |> String.replace(~r/\n/, "")
    |> String.split(",")
    |> Enum.map(&hash/1)
    |> Enum.sum()
    |> IO.puts()
  end

  def hash(str) do
    str
    |> String.to_charlist()
    |> Enum.reduce(0, fn i, sum ->
      rem((sum + i) * 17, 256)
    end)
  end
end

Day15Part1.main()
