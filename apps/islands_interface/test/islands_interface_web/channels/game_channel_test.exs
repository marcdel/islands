defmodule IslandsInterfaceWeb.GameChannelTest do
  use IslandsInterfaceWeb.ChannelCase

  alias IslandsInterfaceWeb.GameChannel
  alias IslandsEngine.{GameSupervisor}

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
    end

    test "handles starting an already started game", %{socket: socket} do
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
    end

    test "errors are only sent to the user who pushed the message", %{socket: socket} do
      push(socket, "new_game")
      # add a player so that adding a third will fail
      push(socket, "add_player", "player_two")

      ref = push(socket, "add_player", "player_three")

      assert_reply(ref, :error)
    end
  end
end
