defmodule Day19Part1 do
  def main() do
    [workflow_str, part_str] =
      File.read!("input")
      |> String.trim()
      |> String.split("\n\n")

    workflows =
      workflow_str
      |> parse_workflows()
      |> dbg()

    parts =
      part_str
      |> parse_parts()
      |> Enum.filter(fn p -> process_part(workflows, p, "in") end)
      |> Enum.map(fn p ->
        p
        |> Enum.reduce(0, fn {_, v}, sum ->
          sum + v
        end)
      end)
      |> Enum.sum()
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

Day19Part1.main()
