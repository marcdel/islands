defmodule GameTest do
  @moduledoc false

  use ExUnit.Case

  alias IslandsEngine.{Guesses, Rules}

  test "can start a new game with a player name" do
    {:ok, game} = Game.start_link("Marc")

    %{
      player_one: %{board: %{}, guesses: %Guesses{}, name: "Marc"},
      player_two: %{board: %{}, guesses: %Guesses{}, name: nil},
      rules: %Rules{
        player_one: :islands_not_set,
        player_two: :islands_not_set,
        state: :initialized
      }
    } = :sys.get_state(game)
  end
end
