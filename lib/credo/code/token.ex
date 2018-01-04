defmodule Credo.Code.Token do
  @moduledoc """
  This module provides helper functions to analyse tokens.
  """

  @doc """
  Returns the position of a token in the form `{line_no, col_start, col_end}`
  """
  def position(token)

  if Version.match?(System.version(), ">= 1.6.0-rc") do
    # Elixir >= 1.6.0
    defdelegate position(token), to: __MODULE__.Elixir1_6_0
  else
    # Elixir <= 1.5.x
    defdelegate position(token), to: __MODULE__.ElixirPre1_6_0
  end

  defmodule Elixir1_6_0 do
    @moduledoc false

    # Elixir >= 1.6.0
    @doc false
    def position({_, {line_no, col_start, _}, atom_or_charlist, _, _, _}) do
      position_tuple(atom_or_charlist, line_no, col_start)
    end

    def position({_, {line_no, col_start, _}, atom_or_charlist, _, _}) do
      position_tuple(atom_or_charlist, line_no, col_start)
    end

    def position({_, {line_no, col_start, _}, atom_or_charlist, _}) do
      position_tuple(atom_or_charlist, line_no, col_start)
    end

    def position({:bin_string, {line_no, col_start, _}, atom_or_charlist}) do
      position_tuple_for_quoted_string(atom_or_charlist, line_no, col_start)
    end

    def position({:bin_heredoc, {line_no, col_start, _}, atom_or_charlist}) do
      position_tuple_for_heredoc(atom_or_charlist, line_no, col_start)
    end

    def position({:atom_unsafe, {line_no, col_start, _}, atom_or_charlist}) do
      position_tuple_for_quoted_string(atom_or_charlist, line_no, col_start)
    end

    def position({_, {line_no, col_start, _}, atom_or_charlist}) do
      position_tuple(atom_or_charlist, line_no, col_start)
    end

    def position({atom_or_charlist, {line_no, col_start, _}}) do
      position_tuple(atom_or_charlist, line_no, col_start)
    end

    # interpolation
    def position({{line_no, col_start, _}, list}) when is_list(list) do
      {line_no, col_start, col_end} =
        position_tuple_for_quoted_string(list, line_no, col_start)

      {line_no, col_start, col_end}
    end

    defp position_tuple(list, line_no, col_start) when is_list(list) do
      binary = to_string(list)
      col_end = col_start + String.length(binary)

      {line_no, col_start, col_end}
    end

    defp position_tuple(atom, line_no, col_start) when is_atom(atom) do
      binary = to_string(atom)
      col_end = col_start + String.length(binary)

      {line_no, col_start, col_end}
    end

    defp position_tuple(number, line_no, col_start) when is_number(number) do
      binary = to_string([number])
      col_end = col_start + String.length(binary)

      {line_no, col_start, col_end}
    end

    defp position_tuple(_, _line_no, _col_start), do: nil

    defp position_tuple_for_heredoc(list, line_no, col_start) when is_list(list) do
      # add 3 for """ (closing double quote)
      col_end = convert_to_col_end(col_start, list) + 3

      {line_no, col_start, col_end}
    end

    defp position_tuple_for_quoted_string(list, line_no, col_start)
         when is_list(list) do
      # add 1 for " (closing double quote)
      col_end = convert_to_col_end(col_start, list) + 1

      {line_no, col_start, col_end}
    end

    defp convert_to_col_end(col_start, value) when is_list(value) do
      Enum.reduce(value, col_start, fn value, current_col_start ->
        convert_to_col_end(current_col_start, value)
      end)
    end

    # {{1, 25, 32}, [{:identifier, {1, 27, 31}, :name}]}
    defp convert_to_col_end(_col_start, {{_line_no, col_start, _}, list}) do
      # add 1 for } (closing parens of interpolation)
      convert_to_col_end(col_start, list) + 1
    end

    defp convert_to_col_end(_col_start, {value, {_line_no, col_start, _}}) do
      to_col_end(col_start, value)
    end

    defp convert_to_col_end(
           _col_start,
           {:bin_string, {_line_no, col_start, nil}, value}
         ) do
      # add 2 for opening and closing "
      to_col_end(col_start, value, 2)
    end

    defp convert_to_col_end(_col_start, {_, {_line_no, col_start, nil}, value}) do
      to_col_end(col_start, value)
    end

    defp convert_to_col_end(
           _col_start,
           {_, {_line_no, col_start, value}, _value}
         ) do
      to_col_end(col_start, value)
    end

    defp convert_to_col_end(col_start, value), do: to_col_end(col_start, value)

    def to_col_end(col_start, value, add \\ 0) do
      col_start + String.length(to_string(value)) + add
    end
  end

  defmodule ElixirPre1_6_0 do
    @moduledoc false

    @doc false
    def position({_, pos, _, _, _, _}), do: pos
    def position({_, pos, _, _, _}), do: pos
    def position({_, pos, _, _}), do: pos
    def position({_, pos, _}), do: pos
    def position({pos, list}) when is_list(list), do: pos
    def position({pos, list}) when is_list(list), do: pos
    def position({atom, pos}) when is_atom(atom), do: pos
  end
end