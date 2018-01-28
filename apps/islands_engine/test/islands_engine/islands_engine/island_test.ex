defmodule IslandsEngine.IslandTest do
  @moduledoc false

  use ExUnit.Case
  #  doctest IslandsEngine.Island

  alias IslandsEngine.Island
  alias IslandsEngine.Coordinate

  test "can create a square island" do
    {:ok, upper_left} = Coordinate.new(1, 1)
    {:ok, %Island{coordinates: coordinates}} = Island.new(:square, upper_left)
    assert MapSet.member?(coordinates, %IslandsEngine.Coordinate{col: 1, row: 1})
    assert MapSet.member?(coordinates, %IslandsEngine.Coordinate{col: 1, row: 2})
    assert MapSet.member?(coordinates, %IslandsEngine.Coordinate{col: 2, row: 1})
    assert MapSet.member?(coordinates, %IslandsEngine.Coordinate{col: 2, row: 2})
  end

  test "handles invalid island types" do
    {:ok, upper_left} = Coordinate.new(1, 1)
    {:error, :invalid_island_type} = Island.new(:triangle, upper_left)
  end

  test "handles invalid coordinates" do
    {:ok, upper_left} = Coordinate.new(10, 10)
    {:error, :invalid_coordinate} = Island.new(:square, upper_left)
  end
end
