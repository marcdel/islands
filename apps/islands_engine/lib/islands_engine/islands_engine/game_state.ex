defmodule IslandsEngine.GameState do
  @moduledoc false

  @table :game_state

  def new do
    :ets.new(@table, [:public, :named_table])
  end

  def insert(key, game_state) do
    :ets.insert(@table, {key, game_state})
  end

  def lookup(key) do
    case :ets.lookup(@table, key) do
      [{^key, game_state}] -> game_state
      [] -> nil
    end
  end

  def delete(key) do
    :ets.delete(@table, key)
  end
end
