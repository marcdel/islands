defmodule GameTest do
  @moduledoc false

  use ExUnit.Case

  alias IslandsEngine.{Board, Island, Guesses, Coordinate, Rules}

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
end
