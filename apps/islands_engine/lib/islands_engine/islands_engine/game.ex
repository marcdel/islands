defmodule Game do
  use GenServer

  alias IslandsEngine.{Board, Guesses, Rules}

  def start_link(player_name) when is_binary(player_name) do
    GenServer.start_link(__MODULE__, player_name, [])
  end

  def init(name) do
    player_one = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player_two = %{name: nil, board: Board.new(), guesses: Guesses.new()}

    {:ok, %{player_one: player_one, player_two: player_two, rules: Rules.new()}}
  end
end
