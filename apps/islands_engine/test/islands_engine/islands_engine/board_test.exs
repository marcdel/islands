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
    %{square: %Island{}, dot: %Island{}} = Board.position_island(board, :dot, island_two)
  end

  test "cannot position overlapping island" do
    board = Board.new()
    {:ok, island_location} = Coordinate.new(1, 1)
    {:ok, island} = Island.new(:square, island_location)
    %{square: %Island{}} = board = Board.position_island(board, :square, island)

    {:ok, island_location_two} = Coordinate.new(2, 2)
    {:ok, island_two} = Island.new(:dot, island_location_two)
    {:error, :overlapping_island} = Board.position_island(board, :dot, island_two)
  end

  test "placing an island of the same type overwrites the previous island" do
    board = Board.new()
    {:ok, island_location} = Coordinate.new(1, 1)
    {:ok, island} = Island.new(:square, island_location)
    %{square: %Island{}} = board = Board.position_island(board, :square, island)

    {:ok, island_location_two} = Coordinate.new(2, 2)
    {:ok, island_two} = Island.new(:square, island_location_two)
    %{square: %Island{}} = Board.position_island(board, :square, island_two)
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

  describe "guess/2" do
    setup do
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
      board = Board.position_island(board, :dot, dot)
      board = Board.position_island(board, :l_shape, l_shape)
      board = Board.position_island(board, :atoll, atoll)
      board = Board.position_island(board, :s_shape, s_shape)

      [board: board, islands: [dot, square, l_shape, atoll, s_shape]]
    end

    test "responds to missed guesses", %{board: board} do
      {:ok, coordinate} = Coordinate.new(10, 10)
      {:miss, :none, :no_win, _board} = Board.guess(board, coordinate)
    end

    test "responds to hit guesses", %{board: board} do
      {:ok, coordinate} = Coordinate.new(1, 1)
      {:hit, :none, :no_win, _board} = Board.guess(board, coordinate)
    end

    test "returns the island type if a guess forests an island", %{board: board} do
      {:ok, coordinate} = Coordinate.new(3, 3)
      {:hit, :dot, :no_win, _board} = Board.guess(board, coordinate)
    end

    test "returns win if all islands have been forested", %{board: board, islands: islands} do
      # Pull off the first island, which is a dot so we can guess that separately
      {[dot], rest} = Enum.split(islands, 1)

      # Guess all other coordinates, using the board as the accumulator,
      # and verify that a win isn't returned yet.
      board =
        rest
        |> Enum.flat_map(fn island -> island.coordinates end)
        |> Enum.reduce(board, fn coordinate, acc ->
          {:hit, _, :no_win, updated_board} = Board.guess(acc, coordinate)
          updated_board
        end)

      # Last guess (the single dot coordinate) results in a win
      {:hit, :dot, :win, _board} = Board.guess(board, Enum.fetch!(dot.coordinates, 0))
    end
  end
end
