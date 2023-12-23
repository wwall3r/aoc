defmodule Day19Part2 do
  def main() do
    [workflow_str, part_str] =
      File.read!("sample")
      |> String.trim()
      |> String.split("\n\n")

    workflows =
      workflow_str
      |> parse_workflows()

    ranges = %{"x" => 1..4000, "m" => 1..4000, "a" => 1..4000, "s" => 1..4000}

    "in"
    |> process_workflows(ranges, workflows)
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> dbg()
  end

  defp parse_workflows(str) do
    str
    |> String.trim()
    |> String.split("\n")
    |> Enum.reduce(%{}, fn s, workflows ->
      [name, conditions_str] =
        s
        |> String.replace("}", "")
        |> String.split("{")

      conditions =
        conditions_str
        |> String.split(",")
        |> Enum.map(fn s ->
          if s =~ ":" do
            {
              String.at(s, 0),
              String.at(s, 1),
              s
              |> String.replace(~r/\D/, "")
              |> String.to_integer(),
              s
              |> String.replace(~r/^.*:/, "")
            }
          else
            s
          end
        end)

      Map.put(workflows, name, conditions)
    end)
  end

  defp parse_parts(str) do
    str
    |> String.trim()
    |> String.replace(~r/[{}]/, "")
    |> String.split("\n")
    |> Enum.map(fn s ->
      s
      |> String.split(",")
      |> Enum.reduce(%{}, fn s, part ->
        [field, num] = String.split(s, "=")

        Map.put(part, field, String.to_integer(num))
      end)
    end)
  end

  defp process_workflows("R", ranges, workflows) do
    IO.puts("R condition")
    nil
  end

  defp process_workflows("A", ranges, _), do: ranges

  defp process_workflows(workflow, ranges, workflows) do
    workflows
    |> Map.get(workflow)
    |> Enum.map(fn condition ->
      {ranges, next} =
        case condition do
          {field, op, value, next} ->
            ranges =
              cond do
                op == "<" ->
                  first..last = ranges[field]

                  cond do
                    # whole range is valid
                    last < value ->
                      ranges

                    # intersection
                    first < value ->
                      Map.put(ranges, field, first..(value - 1))

                    true ->
                      nil
                  end

                op == ">" ->
                  first..last = ranges[field]

                  cond do
                    # whole range is valid
                    first > value ->
                      ranges

                    # intersection
                    last > value ->
                      Map.put(ranges, field, (value + 1)..last)

                    true ->
                      nil
                  end
              end

            {ranges, next}

          str ->
            {ranges, str}
        end

      IO.puts("next: #{next} #{inspect(ranges)}")
      result = process_workflows(next, ranges, workflows)
    end)
  end

  defp process_part(workflows, part, "A"), do: true
  defp process_part(workflows, part, "R"), do: false

  defp process_part(workflows, part, workflow) do
    next_workflow =
      workflows
      |> Map.get(workflow)
      |> Enum.reduce_while("", fn condition, next ->
        case condition do
          {field, op, value, w} ->
            cond do
              op == "<" and part[field] < value -> {:halt, w}
              op == ">" and part[field] > value -> {:halt, w}
              true -> {:cont, next}
            end

          str ->
            {:halt, str}
        end
      end)

    process_part(workflows, part, next_workflow)
  end
end

Day19Part2.main()
