defmodule IslandsInterfaceWeb.GameChannelTest do
  use IslandsInterfaceWeb.ChannelCase

  alias IslandsInterfaceWeb.{GameChannel, Presence}
  alias IslandsEngine.{GameSupervisor, GameState, Island}

  setup do
    {:ok, _, socket} =
      socket()
      |> subscribe_and_join(GameChannel, "game:PlayerOne", %{"screen_name" => "PlayerOne"})

    on_exit(fn ->
      GameSupervisor.stop_game("PlayerOne")
    end)

    {:ok, socket: socket}
  end

  describe "join" do
    test "adds user to the list of presence subscribers", %{socket: socket} do
      assert %{"PlayerOne" => %{metas: [%{online_at: _, phx_ref: _}]}} = Presence.list(socket)
    end

    test "no more than two players can join a game", %{socket: socket} do
      assert {:ok, _reply, _socket} =
               subscribe_and_join(socket, GameChannel, "game:PlayerOne", %{
                 "screen_name" => "PlayerTwo"
               })

      assert {:error, %{reason: "unauthorized"}} =
               subscribe_and_join(socket, GameChannel, "game:PlayerOne", %{
                 "screen_name" => "PlayerThree"
               })
    end

    test "two players with the same screen_name cannot join the same game", %{socket: socket} do
      assert {:error, %{reason: "unauthorized"}} =
               subscribe_and_join(socket, GameChannel, "game:PlayerOne", %{
                 "screen_name" => "PlayerOne"
               })
    end
  end

  describe "show_subscribers" do
    test "can list all presence subscribers", %{socket: socket} do
      push(socket, "show_subscribers")

      assert_broadcast("subscribers", %{"PlayerOne" => %{metas: [%{online_at: _, phx_ref: _}]}})
    end
  end

  describe "new_game" do
    test "player can start a new game", %{socket: socket} do
      ref = push(socket, "new_game")

      assert_reply(ref, :ok)

      game_state = GameState.lookup("PlayerOne")
      assert game_state.player_one.name == "PlayerOne"
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

      push(socket, "add_player", "PlayerTwo")

      assert_broadcast("player_added", %{message: "A new player just joined: PlayerTwo"})
      assert_push("player_added", %{message: "A new player just joined: PlayerTwo"})

      game_state = GameState.lookup("PlayerOne")
      assert game_state.player_one.name == "PlayerOne"
      assert game_state.player_two.name == "PlayerTwo"
    end

    test "errors are only sent to the user who pushed the message", %{socket: socket} do
      push(socket, "new_game")
      # add a player so that adding a third will fail
      push(socket, "add_player", "PlayerTwo")

      ref = push(socket, "add_player", "PlayerThree")

      assert_reply(ref, :error)
    end
  end

  describe "position_island" do
    test "players receive a reply when they position their islands", %{socket: socket} do
      push(socket, "new_game")
      push(socket, "add_player", "PlayerTwo")

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

      game_state = GameState.lookup("PlayerOne")
      assert %{square: %Island{}} = game_state.player_one.board
      assert %{square: %Island{}} = game_state.player_two.board
    end

    test "replies to each player when there is an error", %{socket: socket} do
      push(socket, "new_game")
      push(socket, "add_player", "PlayerTwo")

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

  describe "set_islands" do
    test "both players receive a broacast when a player sets their islands", %{socket: socket} do
      position_all_islands(socket)

      push(socket, "set_islands", "player_one")
      assert_broadcast("player_set_islands", %{player: :player_one})
      assert_push("player_set_islands", %{player: :player_one})
      assert GameState.lookup("PlayerOne").rules.state == :players_set

      push(socket, "set_islands", "player_two")
      assert_broadcast("player_set_islands", %{player: :player_two})
      assert_push("player_set_islands", %{player: :player_two})
      assert GameState.lookup("PlayerOne").rules.state == :player_one_turn
    end

    test "player receives a reply with their board when positioning islands", %{socket: socket} do
      position_all_islands(socket)

      ref = push(socket, "set_islands", "player_two")

      assert_reply(ref, :ok, %{board: _board})
    end

    test "errors are only sent to the player attempting to set their islands", %{socket: socket} do
      push(socket, "new_game")

      ref = push(socket, "set_islands", "player_two")

      assert_reply(ref, :error)
    end
  end

  describe "guess_coordinate" do
    test "broadcasts hits and misses to both players", %{socket: socket} do
      position_all_islands(socket)

      push(socket, "set_islands", "player_one")
      push(socket, "set_islands", "player_two")

      push(socket, "guess_coordinate", %{"player" => "player_one", "row" => 1, "col" => 1})

      assert_broadcast("player_guessed_coordinate", %{
        player: :player_one,
        row: 1,
        col: 1,
        result: %{hit: true, island: :none, win: :no_win}
      })

      push(socket, "guess_coordinate", %{"player" => "player_two", "row" => 10, "col" => 10})

      assert_broadcast("player_guessed_coordinate", %{
        player: :player_two,
        row: 10,
        col: 10,
        result: %{hit: false, island: :none, win: :no_win}
      })
    end

    test "rule errors are only sent to the player", %{socket: socket} do
      position_all_islands(socket)

      push(socket, "set_islands", "player_one")
      push(socket, "set_islands", "player_two")

      ref = push(socket, "guess_coordinate", %{"player" => "player_two", "row" => 1, "col" => 1})
      assert_reply(ref, :error, %{player: :player_two, reason: "Not your turn."})
    end

    test "game errors are only sent to the player", %{socket: socket} do
      position_all_islands(socket)

      push(socket, "set_islands", "player_one")
      push(socket, "set_islands", "player_two")

      ref =
        push(socket, "guess_coordinate", %{"player" => "player_one", "row" => 11, "col" => 11})

      assert_reply(ref, :error)
    end
  end

  defp position_all_islands(socket) do
    push(socket, "new_game")
    push(socket, "add_player", "player_two")

    push(socket, "position_island", %{
      "player" => "player_one",
      "island" => "atoll",
      "row" => 1,
      "col" => 1
    })

    push(socket, "position_island", %{
      "player" => "player_one",
      "island" => "dot",
      "row" => 1,
      "col" => 4
    })

    push(socket, "position_island", %{
      "player" => "player_one",
      "island" => "l_shape",
      "row" => 1,
      "col" => 5
    })

    push(socket, "position_island", %{
      "player" => "player_one",
      "island" => "s_shape",
      "row" => 5,
      "col" => 1
    })

    push(socket, "position_island", %{
      "player" => "player_one",
      "island" => "square",
      "row" => 5,
      "col" => 5
    })

    push(socket, "position_island", %{
      "player" => "player_two",
      "island" => "atoll",
      "row" => 1,
      "col" => 1
    })

    push(socket, "position_island", %{
      "player" => "player_two",
      "island" => "dot",
      "row" => 1,
      "col" => 4
    })

    push(socket, "position_island", %{
      "player" => "player_two",
      "island" => "l_shape",
      "row" => 1,
      "col" => 5
    })

    push(socket, "position_island", %{
      "player" => "player_two",
      "island" => "s_shape",
      "row" => 5,
      "col" => 1
    })

    push(socket, "position_island", %{
      "player" => "player_two",
      "island" => "square",
      "row" => 5,
      "col" => 5
    })
  end
end
