defmodule IslandsEngine.GameState do
  @moduledoc false

  def new() do
    :ets.new(:game_state, [:public, :named_table])
  end

  def insert(key, game_state) do
    :ets.insert(:game_state, {key, game_state})
  end

  def lookup(key) do
    :ets.lookup(:game_state, key)
  end

  def delete(key) do
    :ets.delete(:game_state, key)
  end
end
