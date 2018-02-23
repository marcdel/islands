defmodule IslandsInterfaceWeb.GameChannelTest do
  use IslandsInterfaceWeb.ChannelCase

  alias IslandsInterfaceWeb.GameChannel
  alias IslandsEngine.{GameSupervisor, GameState, Island}

  setup do
    {:ok, _, socket} =
      socket()
      |> subscribe_and_join(GameChannel, "game:player_one")

    on_exit(fn ->
      GameSupervisor.stop_game("player_one")
    end)

    {:ok, socket: socket}
  end

  describe "new_game" do
    test "player can start a new game", %{socket: socket} do
      ref = push(socket, "new_game")

      assert_reply(ref, :ok)

      game_state = GameState.lookup("player_one")
      assert game_state.player_one.name == "player_one"
      assert game_state.player_two.name == nil
    end

    test "replies an error when starting an already started game", %{socket: socket} do
      push(socket, "new_game")

      ref = push(socket, "new_game")

      assert_reply(ref, :error, %{reason: _reason})
    end
  end

  describe "add_player" do
    test "adding a player to an existing game broadcasts to both players", %{socket: socket} do
      push(socket, "new_game")

      push(socket, "add_player", "player_two")

      assert_broadcast("player_added", %{message: "A new player just joined: player_two"})
      assert_push("player_added", %{message: "A new player just joined: player_two"})

      game_state = GameState.lookup("player_one")
      assert game_state.player_one.name == "player_one"
      assert game_state.player_two.name == "player_two"
    end

    test "errors are only sent to the user who pushed the message", %{socket: socket} do
      push(socket, "new_game")
      # add a player so that adding a third will fail
      push(socket, "add_player", "player_two")

      ref = push(socket, "add_player", "player_three")

      assert_reply(ref, :error)
    end
  end

  describe "position_island" do
    test "replies to each player, individually when they position islands", %{socket: socket} do
      push(socket, "new_game")
      push(socket, "add_player", "player_two")

      player_one_ref =
        push(socket, "position_island", %{
          "player" => "player_one",
          "island" => "square",
          "row" => 1,
          "col" => 1
        })

      assert_reply(player_one_ref, :ok)

      player_two_ref =
        push(socket, "position_island", %{
          "player" => "player_two",
          "island" => "square",
          "row" => 1,
          "col" => 1
        })

      assert_reply(player_two_ref, :ok)

      game_state = GameState.lookup("player_one")
      assert %{square: %Island{}} = game_state.player_one.board
      assert %{square: %Island{}} = game_state.player_two.board
    end

    test "replies to each player when there is an error", %{socket: socket} do
      push(socket, "new_game")
      push(socket, "add_player", "player_two")

      ref =
        push(socket, "position_island", %{
          "player" => "player_one",
          "island" => "square",
          "row" => 11,
          "col" => 11
        })

      assert_reply(ref, :error)
    end
  end
end
