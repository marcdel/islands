defmodule IslandsEngine.Game do
  @moduledoc false

  #  @timeout 15_000
  @timeout 60 * 60 * 24 * 1_000

  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient

  alias IslandsEngine.{Board, Island, Guesses, Coordinate, Rules}

  @players [:player_one, :player_two]

  def start_link(player_name) when is_binary(player_name) do
    GenServer.start_link(__MODULE__, player_name, name: via_tuple(player_name))
  end

  def via_tuple(player_name), do: {:via, Registry, {Registry.Game, player_name}}

  def init(player_name) do
    send(self(), {:set_state, player_name})
    {:ok, fresh_state(player_name)}
  end

  def add_player(game, player_name) when is_binary(player_name) do
    GenServer.call(game, {:add_player, player_name})
  end

  def position_island(game, player, key, row, col) when player in @players do
    GenServer.call(game, {:position_island, player, key, row, col})
  end

  def set_islands(game, player) when player in @players do
    GenServer.call(game, {:set_islands, player})
  end

  def guess_coordinate(game, player, row, col) when player in @players do
    GenServer.call(game, {:guess_coordinate, player, row, col})
  end

  def handle_info({:set_state, player_name}, _game_state) do
    game_state =
      case :ets.lookup(:game_state, player_name) do
        [] -> fresh_state(player_name)
        [{_key, state}] -> state
      end

    :ets.insert(:game_state, {player_name, game_state})
    {:noreply, game_state, @timeout}
  end

  def handle_call({:add_player, name}, _from, game_state) do
    with {:ok, rules} <- Rules.check(game_state.rules, :add_player) do
      game_state
      |> set_player_two_name(name)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> reply_error(:error, game_state)
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
      :error -> reply_error(:error, game_state)
      {:error, :invalid_coordinate} -> reply_error({:error, :invalid_coordinate}, game_state)
      {:error, :invalid_island_type} -> reply_error({:error, :invalid_island_type}, game_state)
    end
  end

  def handle_call({:set_islands, player}, _from, game_state) do
    board = player_board(game_state, player)

    with {:ok, rules} <- Rules.check(game_state.rules, {:set_islands, player}),
         true <- Board.all_islands_positioned?(board) do
      game_state
      |> update_rules(rules)
      |> reply_success({:ok, board})
    else
      :error -> reply_error(:error, game_state)
      false -> reply_error({:error, :not_all_islands_positioned}, game_state)
    end
  end

  def handle_call({:guess_coordinate, player, row, col}, _from, game_state) do
    opponent = opponent(player)
    opponent_board = player_board(game_state, opponent)

    with {:ok, rules} <- Rules.check(game_state.rules, {:guess_coordinate, player}),
         {:ok, coordinate} <- Coordinate.new(row, col),
         {hit_or_miss, forested_island, win_status, opponent_board} <-
           Board.guess(opponent_board, coordinate),
         {:ok, rules} <- Rules.check(rules, {:win_check, win_status}) do
      game_state
      |> update_board(opponent, opponent_board)
      |> update_guesses(player, hit_or_miss, coordinate)
      |> update_rules(rules)
      |> reply_success({hit_or_miss, forested_island, win_status})
    else
      :error -> reply_error(:error, game_state)
      {:error, :invalid_coordinate} -> reply_error({:error, :invalid_coordinate}, game_state)
    end
  end

  def handle_info(:timeout, game_state) do
    {:stop, {:shutdown, :timeout}, game_state}
  end

  defp fresh_state(name) do
    player_one = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player_two = %{name: nil, board: Board.new(), guesses: Guesses.new()}
    %{player_one: player_one, player_two: player_two, rules: Rules.new()}
  end

  defp opponent(:player_one), do: :player_two
  defp opponent(:player_two), do: :player_one

  defp player_board(game_state, player), do: Map.get(game_state, player).board

  defp set_player_two_name(game_state, player_name) do
    put_in(game_state.player_two.name, player_name)
  end

  defp update_rules(game_state, rules), do: %{game_state | rules: rules}

  defp update_board(game_state, player, board) do
    Map.update!(game_state, player, fn player -> %{player | board: board} end)
  end

  def update_guesses(game_state, player, hit_or_miss, coordinate) do
    update_in(game_state[player].guesses, fn guesses ->
      Guesses.add(guesses, hit_or_miss, coordinate)
    end)
  end

  defp reply_success(game_state, reply) do
    :ets.insert(:game_state, {game_state.player_one.name, game_state})
    {:reply, reply, game_state, @timeout}
  end

  defp reply_error(reply, game_state), do: {:reply, reply, game_state, @timeout}
end
