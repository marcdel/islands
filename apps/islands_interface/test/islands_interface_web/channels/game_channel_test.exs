defmodule IslandsInterfaceWeb.GameChannelTest do
  use IslandsInterfaceWeb.ChannelCase

  alias IslandsInterfaceWeb.GameChannel
  alias IslandsEngine.GameSupervisor

  describe "joining a channel" do
    test "players can join a game channel by user name" do
      {:ok, _, socket} =
        socket()
        |> subscribe_and_join(GameChannel, "game:player_one")

      assert socket.topic == "game:player_one"
    end
  end

  setup do
    {:ok, _, socket} =
      socket()
      |> subscribe_and_join(GameChannel, "game:player_one")

    on_exit(fn ->
      GameSupervisor.stop_game("player_one")
    end)

    {:ok, socket: socket}
  end

  test "player can start a new game", %{socket: socket} do
    ref = push(socket, "new_game")
    assert_reply(ref, :ok)
  end

  test "handles starting an already started game", %{socket: socket} do
    push(socket, "new_game")

    ref = push(socket, "new_game")
    assert_reply(ref, :error, %{reason: _reason})
  end

  # test "shout broadcasts to game:lobby", %{socket: socket} do
  #   push socket, "shout", %{"hello" => "all"}
  #   assert_broadcast "shout", %{"hello" => "all"}
  # end
  #
  # test "broadcasts are pushed to the client", %{socket: socket} do
  #   broadcast_from! socket, "broadcast", %{"some" => "data"}
  #   assert_push "broadcast", %{"some" => "data"}
  # end
end
