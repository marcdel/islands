defmodule IslandsEngine.GameSupervisor do
  @moduledoc false

  use Supervisor

  alias IslandsEngine.{Game, GameState}

  def start_link(_options) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Supervisor.init([Game], strategy: :simple_one_for_one)
  end

  def start_game(player_name) do
    Supervisor.start_child(__MODULE__, [player_name])
  end

  def stop_game(player_name) do
    GameState.delete(player_name)
    Supervisor.terminate_child(__MODULE__, pid_from_name(player_name))
  end

  defp pid_from_name(player_name) do
    player_name
    |> Game.via_tuple()
    |> GenServer.whereis()
  end
end
