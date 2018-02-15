defmodule IslandsEngine.GameSupervisorTest do
  use ExUnit.Case

  alias IslandsEngine.{GameSupervisor, Game, Guesses, Rules}

  setup do
    on_exit(fn ->
      GameSupervisor.stop_game("Player 1")
    end)
  end

  test "supervisor can start new games with a player name" do
    {:ok, game} = GameSupervisor.start_game("Player 1")

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
    } = :sys.get_state(game)
  end

  test "can stop existing games" do
    {:ok, game} = GameSupervisor.start_game("Player 1")
    assert Process.alive?(game)

    assert :ok = GameSupervisor.stop_game("Player 1")
    refute Process.alive?(game)

    assert Game.via_tuple("Player 1") |> GenServer.whereis() == nil
  end

  test "cannot stop non-existent games" do
    assert {:error, _} = GameSupervisor.stop_game("Made up game")
  end

  test "can recover from crashes" do
    {:ok, game} = GameSupervisor.start_game("Player 1")
    Game.add_player(game, "Player 2")

    via = Game.via_tuple("Player 1")

    state = :sys.get_state(via)
    assert state.player_one.name == "Player 1"
    assert state.player_two.name == "Player 2"

    Process.exit(game, :whoops)

    state = :sys.get_state(via)
    assert state.player_one.name == "Player 1"
    assert state.player_two.name == "Player 2"
  end
end
