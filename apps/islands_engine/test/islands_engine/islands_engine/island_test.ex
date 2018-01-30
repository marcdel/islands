defmodule IslandsEngine.IslandTest do
  @moduledoc false

  use ExUnit.Case
  #  doctest IslandsEngine.Island

  alias IslandsEngine.{Island, Coordinate}

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

  test "can check for overlapping islands" do
    {:ok, square_coordinate} = Coordinate.new(1, 1)
    {:ok, square} = Island.new(:square, square_coordinate)

    {:ok, dot_coordinate} = Coordinate.new(1, 2)
    {:ok, dot} = Island.new(:dot, dot_coordinate)

    {:ok, l_shaped_coordinate} = Coordinate.new(5, 5)
    {:ok, l_shape} = Island.new(:l_shape, l_shaped_coordinate)

    assert Island.overlaps?(square, dot)
    refute Island.overlaps?(square, l_shape)
    refute Island.overlaps?(dot, l_shape)
  end

  test "can guess coordinates on an island" do
    {:ok, island_location} = Coordinate.new(1, 1)
    {:ok, island} = Island.new(:square, island_location)

    {:ok, hit} = Coordinate.new(1, 1)
    {:hit, updated_island} = Island.guess(island, hit)
    assert hit in updated_island.hit_coordinates

    {:ok, miss} = Coordinate.new(3, 1)
    :miss = Island.guess(island, miss)
  end
end
