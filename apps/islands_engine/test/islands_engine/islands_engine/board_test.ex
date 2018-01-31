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

  test "can check whether all islands have been positioned" do
    {:ok, square_coordinate} = Coordinate.new(1, 1)
    {:ok, dot_coordinate} = Coordinate.new(3, 3)
    {:ok, l_shape_coordinate} = Coordinate.new(4, 1)
    {:ok, atoll_coordinate} = Coordinate.new(5, 5)
    {:ok, s_shape_coordinate} = Coordinate.new(4, 2)

    {:ok, square} = Island.new(:square, square_coordinate)
    {:ok, dot} = Island.new(:dot, dot_coordinate)
    {:ok, l_shape} = Island.new(:l_shape, l_shape_coordinate)
    {:ok, atoll} = Island.new(:atoll, atoll_coordinate)
    {:ok, s_shape} = Island.new(:s_shape, s_shape_coordinate)

    board = Board.new()

    board = Board.position_island(board, :square, square)
    refute Board.all_islands_positioned?(board)

    board = Board.position_island(board, :dot, dot)
    refute Board.all_islands_positioned?(board)

    board = Board.position_island(board, :l_shape, l_shape)
    refute Board.all_islands_positioned?(board)

    board = Board.position_island(board, :atoll, atoll)
    refute Board.all_islands_positioned?(board)

    board = Board.position_island(board, :s_shape, s_shape)
    assert Board.all_islands_positioned?(board)
  end
end
