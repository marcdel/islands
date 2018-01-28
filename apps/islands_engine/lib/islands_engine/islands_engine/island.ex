defmodule IslandsEngine.Island do
  @moduledoc """
  An Island made up of Coordinates
  """

  alias __MODULE__
  alias IslandsEngine.Coordinate

  @enforce_keys [:coordinates, :hit_coordinates]
  defstruct [:coordinates, :hit_coordinates]

  @doc """
    Given an island type and an initial coordinate, returns an island with
    the list of coordinates making up the island.

    ## Examples:

      iex> IslandsEngine.Island.new(:square, %IslandsEngine.Coordinate{col: 1, row: 1})
      {:ok,
            %IslandsEngine.Island{
              coordinates: #MapSet<[
                %IslandsEngine.Coordinate{col: 1, row: 1},
                %IslandsEngine.Coordinate{col: 1, row: 2},
                %IslandsEngine.Coordinate{col: 2, row: 1},
                %IslandsEngine.Coordinate{col: 2, row: 2}
              ]>,
              hit_coordinates: #MapSet<[]>
            }}
  """
  def new(type, %Coordinate{} = upper_left) do
    with [_ | _] = offsets <- offsets(type),
         %MapSet{} = coordinates <- add_coordinates(offsets, upper_left) do
      {:ok, %Island{coordinates: coordinates, hit_coordinates: MapSet.new()}}
    else
      {:error, :invalid_island_type} = error -> error
      {:error, :invalid_coordinate} = error -> error
      error -> error
    end
  end

  @doc """
  1   1
  1   1
  """
  defp offsets(:square), do: [{0, 0}, {0, 1}, {1, 0}, {1, 1}]
  defp offsets(_), do: {:error, :invalid_island_type}

  defp add_coordinates(offsets, upper_left) do
    Enum.reduce_while(
      offsets,
      MapSet.new(),
      fn offset, acc ->
        add_coordinate(acc, upper_left, offset)
      end
    )
  end

  defp add_coordinate(coordinates, %Coordinate{row: row, col: col}, {row_offset, col_offset}) do
    case Coordinate.new(row + row_offset, col + col_offset) do
      {:ok, coordinate} ->
        {:cont, MapSet.put(coordinates, coordinate)}

      {:error, :invalid_coordinate} ->
        {:halt, {:error, :invalid_coordinate}}
    end
  end
end
