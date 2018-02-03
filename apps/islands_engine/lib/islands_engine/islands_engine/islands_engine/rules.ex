defmodule IslandsEngine.Rules do
  @moduledoc false

  alias __MODULE__

  defstruct state: :initialized,
            player_one: :islands_not_set,
            player_two: :islands_not_set

  def new() do
    %Rules{}
  end

  def check(%Rules{state: :initialized} = rules, :add_player) do
    {:ok, %Rules{rules | state: :players_set}}
  end

  def check(%Rules{state: :players_set} = rules, {:position_islands, player}) do
    case Map.fetch!(rules, player) do
      :islands_set -> :error
      :islands_not_set -> {:ok, rules}
    end
  end

  def check(%Rules{state: players_set} = rules, {:set_islands, player}) do
    rules = Map.put(rules, player, :islands_set)
    case both_players_islands_set?(rules) do
      true -> {:ok, %Rules{rules | state: :player_one_turn}}
      false -> {:ok, rules}
    end
  end

  def check(%Rules{state: :player_one_turn} = rules, {:guess_coordinate, :player_one}) do
    {:ok, %Rules{rules | state: :player_two_turn}}
  end

  def check(%Rules{state: :player_two_turn} = rules, {:guess_coordinate, :player_two}) do
    {:ok, %Rules{rules | state: :player_one_turn}}
  end

  def check(_rules, _action), do: :error

  defp both_players_islands_set?(rules) do
    rules.player_one == :islands_set && rules.player_two == :islands_set
  end
end
