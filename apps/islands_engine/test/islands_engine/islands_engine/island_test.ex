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

  test "can create an atoll island" do
    {:ok, upper_left} = Coordinate.new(1, 1)
    {:ok, %Island{coordinates: coordinates}} = Island.new(:atoll, upper_left)

    assert MapSet.member?(coordinates, %IslandsEngine.Coordinate{col: 1, row: 1})
    assert MapSet.member?(coordinates, %IslandsEngine.Coordinate{col: 1, row: 3})
    assert MapSet.member?(coordinates, %IslandsEngine.Coordinate{col: 2, row: 1})
    assert MapSet.member?(coordinates, %IslandsEngine.Coordinate{col: 2, row: 2})
    assert MapSet.member?(coordinates, %IslandsEngine.Coordinate{col: 2, row: 3})
  end

  test "can create a dot island" do
    {:ok, upper_left} = Coordinate.new(1, 1)
    {:ok, %Island{coordinates: coordinates}} = Island.new(:dot, upper_left)

    assert MapSet.member?(coordinates, %IslandsEngine.Coordinate{col: 1, row: 1})
  end

  test "can create an l-shape island" do
    {:ok, upper_left} = Coordinate.new(1, 1)
    {:ok, %Island{coordinates: coordinates}} = Island.new(:l_shape, upper_left)

    assert MapSet.member?(coordinates, %IslandsEngine.Coordinate{col: 1, row: 1})
    assert MapSet.member?(coordinates, %IslandsEngine.Coordinate{col: 1, row: 2})
    assert MapSet.member?(coordinates, %IslandsEngine.Coordinate{col: 1, row: 3})
    assert MapSet.member?(coordinates, %IslandsEngine.Coordinate{col: 2, row: 3})
  end

  test "can create an s-shape island" do
    {:ok, upper_left} = Coordinate.new(1, 1)
    {:ok, %Island{coordinates: coordinates}} = Island.new(:s_shape, upper_left)

    assert MapSet.member?(coordinates, %IslandsEngine.Coordinate{col: 1, row: 2})
    assert MapSet.member?(coordinates, %IslandsEngine.Coordinate{col: 2, row: 1})
    assert MapSet.member?(coordinates, %IslandsEngine.Coordinate{col: 2, row: 2})
    assert MapSet.member?(coordinates, %IslandsEngine.Coordinate{col: 3, row: 1})
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
