defmodule Day11Part12 do
  # part 1
  # @factor 2

  # part 2
  @factor 1_000_000

  def main() do
    File.read!("input")
    |> String.trim()
    |> String.split("\n")
    |> Enum.with_index()
    |> Enum.reduce([], fn {row, y}, galaxies ->
      row
      |> String.split("")
      |> Enum.filter(fn c -> c != "" end)
      |> Enum.with_index()
      |> Enum.reduce(galaxies, fn {c, x}, galaxies ->
        case c do
          "#" -> [{x, y} | galaxies]
          _ -> galaxies
        end
      end)
    end)
    |> gravitational_nonsense()
    |> distance_of_all_pairs()
    |> IO.puts()
  end

  defp gravitational_nonsense(galaxies) do
    {galaxies, _, _} =
      galaxies
      |> sort_y()
      |> Enum.with_index()
      |> Enum.reduce({[], 0, 0}, fn {{x, y}, i} = galaxy, {galaxies, y_idx, replaced} ->
        replaced =
          cond do
            i === 0 and y > 0 -> y
            y - y_idx > 1 -> replaced + y - y_idx - 1
            true -> replaced
          end

        {[{x, y - replaced + replaced * @factor} | galaxies], y, replaced}
      end)

    {galaxies, _, _} =
      galaxies
      |> sort_x()
      |> Enum.with_index()
      |> Enum.reduce({[], 0, 0}, fn {{x, y}, i}, {galaxies, x_idx, replaced} ->
        replaced =
          cond do
            i == 0 and x > 0 -> x
            x - x_idx > 1 -> replaced + x - x_idx - 1
            true -> replaced
          end

        {[{x - replaced + replaced * @factor, y} | galaxies], x, replaced}
      end)

    galaxies
  end

  defp distance_of_all_pairs(galaxies) do
    galaxies
    |> Enum.with_index()
    |> Enum.reduce(0, fn {g1, i}, sum ->
      galaxies
      |> Enum.split(i + 1)
      |> elem(1)
      |> Enum.reduce(sum, fn g2, sum ->
        sum + distance(g1, g2)
      end)
    end)
  end

  defp distance({x0, y0}, {x1, y1}) do
    abs(x1 - x0) + abs(y1 - y0)
  end

  defp sort_y(galaxies) do
    galaxies
    |> Enum.sort(fn {_, y0}, {_, y1} -> y0 < y1 end)
  end

  defp sort_x(galaxies) do
    galaxies
    |> Enum.sort(fn {x0, _}, {x1, _} -> x0 < x1 end)
  end
end

Day11Part12.main()
