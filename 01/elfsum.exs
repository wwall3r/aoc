defmodule ElfSum do
  @digits ~w[ one two three four five six seven eight nine ]

  def main do
    File.stream!("input")
    |> Enum.reduce(0, &reduceNumber/2)
    |> IO.puts()
  end

  defp reduceNumber(str, sum) do
    str
    |> String.trim()
    |> get_number()
    |> String.to_integer()
    |> Kernel.+(sum)
  end

  defp get_number(str) do
    # grab a list of the first and last digit/word
    [
      String.replace(
        str,
        # there's probably a way to compile a regex from the @digits list but fuck it
        ~r/^.*?([0-9]|one|two|three|four|five|six|seven|eight|nine).*$/,
        "\\1"
      ),
      String.replace(
        str,
        ~r/^.*([0-9]|one|two|three|four|five|six|seven|eight|nine).*?$/,
        "\\1"
      )
    ]
    |> Enum.map(&convert_words_to_digits/1)
    |> Enum.join()
  end

  defp convert_words_to_digits(str) do
    @digits
    |> Enum.reduce(str, fn pattern, str ->
      String.replace(str, pattern, fn _ ->
        @digits
        |> Enum.find_index(fn n -> n == pattern end)
        |> Kernel.+(1)
        |> Integer.to_string()
      end)
    end)
  end
end

ElfSum.main()
