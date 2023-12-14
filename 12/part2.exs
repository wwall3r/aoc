defmodule Day12Part2 do
  def main() do
    File.stream!("sample2")
    |> Enum.reduce(0, &sum_line/2)
    |> IO.puts()
  end

  defp sum_line(str, sum) do
    [springs, criteria] =
      str
      |> String.trim()
      |> String.split(" ")

    # re-enable after reproducing part 1 results with new method
    # springs =
    #   [springs, springs, springs, springs, springs]
    #   |> Enum.join("?")
    #
    # criteria =
    #   [criteria, criteria, criteria, criteria, criteria]
    #   |> Enum.join(",")
    #
    criteria =
      criteria
      |> String.split(",")
      |> Enum.map(&String.to_integer/1)

    # way over thinking this
    # - scan by char
    # - if matched, count++ and split off rest of string with next section

    # first thought is
    # - scan for section i fit
    # - at idx of fit, scan subsequent sections in same manner
    # - if fit, increment
    # - try scan at next idx

    # next thought is to create the min match from the criteria
    # and then compute from that

    line_sum =
      criteria
      |> get_regexes()
      |> process(springs, criteria)
      |> dbg()

    sum + line_sum
  end

  # defp process(
  #        [{grapheme, i} | grapheme_tail] = graphemes,
  #        [criterion | criteria_tail] = criteria,
  #        [[{c, len, status} = found | found_tail] = state | state_tail]
  #      ) do
  #   c =
  #     if c == -1 do
  #       case grapheme do
  #         "?" -> i
  #         "#" -> i
  #         _ -> c
  #       end
  #     end
  #
  #   len =
  #     cond do
  #       c != -1 ->
  #         case grapheme do
  #           "?" -> len + 1
  #           "#" -> len + 1
  #           _ -> len
  #         end
  #
  #       true ->
  #         0
  #     end
  #
  #   status =
  #     if c > -1 do
  #       case grapheme do
  #         "." -> :complete
  #         _ -> :processing
  #       end
  #     end
  #
  #   add? = len == criterion
  #
  #   state =
  #     case status do
  #       :complete and add? -> [{-1, -1, :processing}, {c, len, status}] ++ found_tail
  #       :complete -> [{-1, -1, :processing} | found_tail]
  #       :processing -> [{c, len, status} | found_tail]
  #     end
  #
  #   # state = case grapheme do
  #   #   "?" -> {built,
  #   #   "#" ->
  #   #   "." ->
  # end

  defp get_regexes(criteria) do
    last_crit = length(criteria) - 1

    criteria
    |> Enum.with_index()
    |> Enum.map(fn {l, i} ->
      case i == last_crit do
        true -> "(?<no>\.)(?<yes>[#?]{#{l}})(?<no2>[^#]*$)"
        false -> "(?<no>^|\.)(?<yes>[#?]{#{l}}\.)"
      end
      |> Regex.compile!()
    end)
  end

  defp process(regexes, springs, criteria) do
    last_regexes_idx = length(regexes) - 1
    springs_len = String.length(springs)

    # dbg()

    regexes
    |> Enum.with_index()
    |> Enum.map(fn {regex, i} ->
      0..(springs_len - 1)
      |> Enum.map(fn n ->
        list =
          regex
          |> Regex.named_captures(springs, return: :index, offset: n)
          |> case do
            nil -> %{}
            map -> map
          end
          |> Map.get("yes")
          |> List.wrap()
          |> List.flatten()
      end)
      |> List.flatten()
      |> Enum.reject(&is_nil/1)
      |> Enum.dedup()
    end)
    |> Enum.filter(fn list -> list != [] end)
    # all combinations of those
    |> combine()
    # filter out any of those which have intersecting values
    |> Enum.filter(fn parts ->
      parts
      |> Enum.reduce({true, -1}, fn {i, len}, {passing, min} ->
        {passing and i > min, i + len - 1}
      end)
      |> elem(0)
    end)
    |> MapSet.new()
    |> MapSet.size()
  end

  def combine([head | tail]) do
    case tail do
      [] -> head
      _ -> combine(head, combine(tail))
    end
  end

  def combine(list1, list2) do
    for x <- list1,
        y <- list2,
        do: List.flatten([x, y])
  end

  defp fits_criteria(springs, criteria) when is_list(springs) do
    springs
    |> Enum.join("")
    |> fits_criteria(criteria)
  end

  defp fits_criteria(springs, criteria) when is_bitstring(springs) do
    criteria ==
      springs
      |> String.split(~r/\.+/)
      |> Enum.filter(fn s -> s != "" end)
      |> Enum.map(&String.length/1)
  end

  # def test() do
  #   # [["A", "B", "C"], ["1", "2"], ["X", "Y"]]
  #   # |> combine()
  #   # |> dbg()
  #   build(3, 3)
  #   |> dbg()
  # end
end

# Day12Part2.test()

Day12Part2.main()
