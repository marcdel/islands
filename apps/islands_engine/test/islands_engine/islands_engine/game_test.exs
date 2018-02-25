defmodule GameTest do
  @moduledoc false

  use ExUnit.Case

  alias IslandsEngine.{GameSupervisor, GameState, Game, Island, Guesses, Rules}

  setup do
    on_exit(fn ->
      # This is lazy as hell, but since all the examples are using "Player 1"
      # we can stop them all here rather than in each test.
      GameSupervisor.stop_game("Player 1")
    end)
  end

  test "can start a new game with a player name" do
    Game.start_link("Player 1")

    %{
      player_one: %{
        board: %{},
        guesses: %Guesses{},
        name: "Player 1"
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
    } = GameState.lookup("Player 1")
  end

  test "can add a second player" do
    {:ok, game} = Game.start_link("Player 1")
    :ok = Game.add_player(game, "Player 2")

    %{
      player_two: %{
        name: "Player 2"
      },
      rules: %Rules{
        state: :players_set
      }
    } = GameState.lookup("Player 1")
  end

  describe "position_island/5" do
    setup do
      {:ok, game} = Game.start_link("Player 1")
      :ok = Game.add_player(game, "Player 2")

      [game: game]
    end

    test "players can position islands", %{game: game} do
      :ok = Game.position_island(game, :player_one, :dot, 1, 1)
      :ok = Game.position_island(game, :player_two, :square, 1, 1)

      game_state = GameState.lookup("Player 1")
      assert %Island{} = game_state.player_one.board.dot
      assert %Island{} = game_state.player_two.board.square
    end

    test "handles invalid coordinates", %{game: game} do
      assert {:error, :invalid_coordinate} = Game.position_island(game, :player_one, :dot, 12, 12)
    end

    test "handles overlapping islands", %{game: game} do
      Game.position_island(game, :player_one, :square, 1, 1)
      assert {:error, :overlapping_island} = Game.position_island(game, :player_one, :dot, 1, 1)
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
      {:ok, game} = Game.start_link("Player 1")
      :ok = Game.add_player(game, "Player 2")

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
      {:ok, game} = Game.start_link("Player 1")
      :ok = Game.add_player(game, "Player 2")

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
      {:ok, game} = Game.start_link("Cheater 1")
      Game.add_player(game, "Cheater 2")
      Game.position_island(game, :player_one, :dot, 1, 1)
      Game.position_island(game, :player_two, :square, 1, 1)
      game_state = :sys.get_state(game)

      # Get to the start of the game with only two islands positioned
      :sys.replace_state(game, fn _ ->
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

  test "initializes the game with existing state if it exists" do
    initial_state = %{
      player_one: %{
        board: %{},
        guesses: %Guesses{hits: [], misses: []},
        name: "Player 1"
      },
      player_two: %{
        board: %{},
        guesses: %Guesses{hits: [], misses: []},
        name: "Player 2"
      },
      rules: %Rules{
        player_one: :islands_set,
        player_two: :islands_set,
        state: :player_one_turn
      }
    }

    GameState.insert("Player 1", initial_state)
    Game.start_link("Player 1")

    assert initial_state == GameState.lookup("Player 1")
  end

  test "game state is saved after every successful event" do
    {:ok, game} = Game.start_link("Player 1")
    :ok = Game.add_player(game, "Player 2")

    Game.position_island(game, :player_one, :atoll, 1, 1)
    Game.position_island(game, :player_one, :dot, 1, 4)
    Game.position_island(game, :player_one, :l_shape, 1, 5)
    Game.position_island(game, :player_one, :s_shape, 5, 1)
    Game.position_island(game, :player_one, :square, 5, 5)
    Game.set_islands(game, :player_one)

    state = GameState.lookup("Player 1")
    assert MapSet.size(state.player_one.board.atoll.coordinates) == 5
    assert MapSet.size(state.player_one.board.dot.coordinates) == 1
    assert MapSet.size(state.player_one.board.l_shape.coordinates) == 4
    assert MapSet.size(state.player_one.board.s_shape.coordinates) == 4
    assert MapSet.size(state.player_one.board.square.coordinates) == 4
    assert state.rules.player_one == :islands_set

    Game.position_island(game, :player_two, :atoll, 1, 1)
    Game.position_island(game, :player_two, :dot, 1, 4)
    Game.position_island(game, :player_two, :l_shape, 1, 5)
    Game.position_island(game, :player_two, :s_shape, 5, 1)
    Game.position_island(game, :player_two, :square, 5, 5)
    Game.set_islands(game, :player_two)

    state = GameState.lookup("Player 1")
    assert MapSet.size(state.player_two.board.atoll.coordinates) == 5
    assert MapSet.size(state.player_two.board.dot.coordinates) == 1
    assert MapSet.size(state.player_two.board.l_shape.coordinates) == 4
    assert MapSet.size(state.player_two.board.s_shape.coordinates) == 4
    assert MapSet.size(state.player_two.board.square.coordinates) == 4
    assert state.rules.player_two == :islands_set

    assert state.rules.state == :player_one_turn
  end
end
