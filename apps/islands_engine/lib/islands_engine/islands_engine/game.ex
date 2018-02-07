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

  def add_player(game, player_name) when is_binary(player_name) do
    GenServer.call(game, {:add_player, player_name})
  end

  def handle_call({:add_player, name}, _from, game_state) do
    with {:ok, rules} <- Rules.check(game_state.rules, :add_player) do
      game_state
      |> set_player_two_name(name)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> {:reply, :error, game_state}
    end
  end

  defp set_player_two_name(game_state, player_name) do
    put_in(game_state.player_two.name, player_name)
  end

  defp update_rules(game_state, rules), do: %{game_state | rules: rules}

  defp reply_success(game_state, reply), do: {:reply, reply, game_state}
end
