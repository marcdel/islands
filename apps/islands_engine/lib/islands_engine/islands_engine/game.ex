defmodule Game do
  @moduledoc false

  use GenServer

  alias IslandsEngine.{Board, Island, Guesses, Coordinate, Rules}

  @players [:player_one, :player_two]

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

  def position_island(game, player, key, row, col) when player in @players do
    GenServer.call(game, {:position_island, player, key, row, col})
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

  def handle_call({:position_island, player, key, row, col}, _from, game_state) do
    board = player_board(game_state, player)

    with {:ok, rules} <- Rules.check(game_state.rules, {:position_islands, player}),
         {:ok, coordinate} <- Coordinate.new(row, col),
         {:ok, island} <- Island.new(key, coordinate),
         %{} = board <- Board.position_island(board, key, island) do
      game_state
      |> update_board(player, board)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> {:reply, :error, game_state}
      {:error, :invalid_coordinate} -> {:reply, {:error, :invalid_coordinate}, game_state}
      {:error, :invalid_island_type} -> {:reply, {:error, :invalid_island_type}, game_state}
    end
  end

  defp player_board(game_state, player), do: Map.get(game_state, player).board

  defp set_player_two_name(game_state, player_name) do
    put_in(game_state.player_two.name, player_name)
  end

  defp update_rules(game_state, rules), do: %{game_state | rules: rules}

  defp update_board(game_state, player, board) do
    Map.update!(game_state, player, fn player -> %{player | board: board} end)
  end

  defp reply_success(game_state, reply), do: {:reply, reply, game_state}
end
