defmodule GameTest do
  @moduledoc false

  use ExUnit.Case

  alias IslandsEngine.{Game, Board, Island, Guesses, Coordinate, Rules}

  test "can start a new game with a player name" do
    {:ok, game} = Game.start_link("Marc")

    %{
      player_one: %{
        board: %{},
        guesses: %Guesses{},
        name: "Marc"
      },
      player_two: %{
        board: %{},
        guesses: %Guesses{},
        name: nil
      },
      rules: %Rules{
        player_one: :islands_not_set,
        player_two: :islands_not_set,
        state: :initialized
      }
    } = :sys.get_state(game)
  end

  test "can add a second player" do
    {:ok, game} = Game.start_link("Marc")
    :ok = Game.add_player(game, "Jackie")

    %{
      player_two: %{
        name: "Jackie"
      },
      rules: %Rules{
        state: :players_set
      }
    } = :sys.get_state(game)
  end

  describe "position_island/5" do
    setup do
      {:ok, game} = Game.start_link("Marc")
      :ok = Game.add_player(game, "Jackie")

      [game: game]
    end

    test "players can position islands", %{game: game} do
      :ok = Game.position_island(game, :player_one, :dot, 1, 1)
      :ok = Game.position_island(game, :player_two, :square, 1, 1)

      game_state = :sys.get_state(game)
      assert %Island{} = game_state.player_one.board.dot
      assert %Island{} = game_state.player_two.board.square
    end

    test "handles invalid coordinates", %{game: game} do
      assert {:error, :invalid_coordinate} = Game.position_island(game, :player_one, :dot, 12, 12)
    end

    test "handles invalid island types", %{game: game} do
      assert {:error, :invalid_island_type} =
               Game.position_island(game, :player_one, :invalid_island, 1, 1)
    end

    test "handles invalid island positions", %{game: game} do
      assert {:error, :invalid_coordinate} =
               Game.position_island(game, :player_one, :l_shape, 10, 10)
    end

    test "handles rule violations", %{game: game} do
      # We shouldn't be able to position islands when it's a player's turn.
      :sys.replace_state(game, fn game_state ->
        %{game_state | rules: %Rules{state: :player_one_turn}}
      end)

      assert :error = Game.position_island(game, :player_one, :dot, 1, 1)
    end
  end

  describe "set_islands/2" do
    setup do
      {:ok, game} = Game.start_link("Marc")
      :ok = Game.add_player(game, "Jackie")

      [game: game]
    end

    test "players can set their islands", %{game: game} do
      Game.position_island(game, :player_one, :atoll, 1, 1)
      Game.position_island(game, :player_one, :dot, 1, 4)
      Game.position_island(game, :player_one, :l_shape, 1, 5)
      Game.position_island(game, :player_one, :s_shape, 5, 1)
      Game.position_island(game, :player_one, :square, 5, 5)

      assert {:ok, _board} = Game.set_islands(game, :player_one)

      Game.position_island(game, :player_two, :atoll, 1, 1)
      Game.position_island(game, :player_two, :dot, 1, 4)
      Game.position_island(game, :player_two, :l_shape, 1, 5)
      Game.position_island(game, :player_two, :s_shape, 5, 1)
      Game.position_island(game, :player_two, :square, 5, 5)

      assert {:ok, _board} = Game.set_islands(game, :player_two)
    end

    test "player cannot set islands unless they're all positioned", %{game: game} do
      Game.position_island(game, :player_one, :atoll, 1, 1)

      assert {:error, :not_all_islands_positioned} = Game.set_islands(game, :player_one)
    end

    test "handles rule violations", %{game: game} do
      # We shouldn't be able to set islands when it's a player's turn.
      :sys.replace_state(game, fn game_state ->
        %{game_state | rules: %Rules{state: :player_one_turn}}
      end)

      assert :error = Game.set_islands(game, :player_one)
    end
  end

  describe "guess_coordinate/4" do
    setup do
      {:ok, game} = Game.start_link("Marc")
      :ok = Game.add_player(game, "Jackie")

      Game.position_island(game, :player_one, :atoll, 1, 1)
      Game.position_island(game, :player_one, :dot, 1, 4)
      Game.position_island(game, :player_one, :l_shape, 1, 5)
      Game.position_island(game, :player_one, :s_shape, 5, 1)
      Game.position_island(game, :player_one, :square, 5, 5)
      Game.set_islands(game, :player_one)

      Game.position_island(game, :player_two, :atoll, 1, 1)
      Game.position_island(game, :player_two, :dot, 1, 4)
      Game.position_island(game, :player_two, :l_shape, 1, 5)
      Game.position_island(game, :player_two, :s_shape, 5, 1)
      Game.position_island(game, :player_two, :square, 5, 5)
      Game.set_islands(game, :player_two)

      [game: game]
    end

    test "players can guess coordinates" do
      {:ok, game} = Game.start_link("Marc")
      Game.add_player(game, "Jackie")
      Game.position_island(game, :player_one, :dot, 1, 1)
      Game.position_island(game, :player_two, :square, 1, 1)
      game_state = :sys.get_state(game)

      # Get to the start of the game with only two islands positioned
      game_state =
        :sys.replace_state(game, fn data ->
          %{game_state | rules: %Rules{state: :player_one_turn}}
        end)

      assert {:hit, :none, :no_win} = Game.guess_coordinate(game, :player_one, 1, 1)
      assert :error = Game.guess_coordinate(game, :player_one, 1, 1)
      assert {:miss, :none, :no_win} = Game.guess_coordinate(game, :player_two, 2, 2)
      assert {:hit, :none, :no_win} = Game.guess_coordinate(game, :player_one, 2, 2)
      assert {:hit, :dot, :win} = Game.guess_coordinate(game, :player_two, 1, 1)
    end

    test "handles rule violations", %{game: game} do
      assert :error = Game.guess_coordinate(game, :player_two, 1, 1)
    end

    test "handles invalid coordinates", %{game: game} do
      assert {:error, :invalid_coordinate} = Game.guess_coordinate(game, :player_one, 11, 11)
    end
  end
end
