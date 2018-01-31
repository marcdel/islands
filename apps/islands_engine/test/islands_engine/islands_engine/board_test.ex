defmodule IslandsEngine.BoardTest do
  @moduledoc false

  use ExUnit.Case
  doctest IslandsEngine.Board

  alias IslandsEngine.{Board, Island, Coordinate}

  test "can create new list of guesses" do
    %{} = Board.new()
  end

  test "can position islands" do
    board = Board.new()
    {:ok, island_location} = Coordinate.new(1, 1)
    {:ok, island} = Island.new(:square, island_location)
    %{square: %Island{}} = board = Board.position_island(board, :square, island)

    {:ok, island_location_two} = Coordinate.new(3, 3)
    {:ok, island_two} = Island.new(:dot, island_location_two)
    %{square: %Island{}, dot: %Island{}} = board = Board.position_island(board, :dot, island_two)
  end

  test "cannot position overlapping island" do
    board = Board.new()
    {:ok, island_location} = Coordinate.new(1, 1)
    {:ok, island} = Island.new(:square, island_location)
    %{square: %Island{}} = board = Board.position_island(board, :square, island)

    {:ok, island_location_two} = Coordinate.new(2, 2)
    {:ok, island_two} = Island.new(:dot, island_location_two)
    {:error, :overlapping_island} = board = Board.position_island(board, :dot, island_two)
  end

  test "placing an island of the same type overwrites the previous island" do
    board = Board.new()
    {:ok, island_location} = Coordinate.new(1, 1)
    {:ok, island} = Island.new(:square, island_location)
    %{square: %Island{}} = board = Board.position_island(board, :square, island)

    {:ok, island_location_two} = Coordinate.new(2, 2)
    {:ok, island_two} = Island.new(:square, island_location_two)
    %{square: %Island{}} = board = Board.position_island(board, :square, island_two)
  end
end
