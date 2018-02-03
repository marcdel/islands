defmodule IslandsEngine.RulesTest do
  @moduledoc false

  use ExUnit.Case
  doctest IslandsEngine.Board

  alias IslandsEngine.Rules

  test "can create a new rules object" do
    %Rules{} = Rules.new()
  end

  describe ":initialized" do
    test "can add a second player" do
      rules = Rules.new()
      :error = Rules.check(rules, :some_invalid_action)
      {:ok, %Rules{state: :players_set}} = Rules.check(rules, :add_player)
    end

    test "cannot add a third player" do
      rules = Rules.new()
      rules = Rules.check(rules, :add_player)
      :error = Rules.check(rules, :add_player)
    end
  end

  describe ":players_set" do
    setup do
      [rules: %Rules{state: :players_set}]
    end

    test "can position islands without changing state", %{rules: rules} do
      {:ok, %Rules{state: :players_set} = rules} = Rules.check(rules, {:position_islands, :player_one})
      {:ok, %Rules{state: :players_set}} = Rules.check(rules, {:position_islands, :player_two})
    end

    test "each player can set their islands", %{rules: rules} do
      {:ok, %Rules{state: :players_set} = rules} = Rules.check(rules, {:set_islands, :player_one})
      {:ok, %Rules{state: :player_one_turn}} = Rules.check(rules, {:set_islands, :player_two})
    end

    test "player cannot position their islands after they've been set", %{rules: rules} do
      {:ok, rules} = Rules.check(rules, {:set_islands, :player_one})
      :error = Rules.check(rules, {:position_islands, :player_one})

      {:ok, rules} = Rules.check(rules, {:position_islands, :player_two})
      {:ok, rules} = Rules.check(rules, {:set_islands, :player_two})
      :error = Rules.check(rules, {:position_islands, :player_two})
    end
  end

  describe ":player_one_turn" do
    setup do
      [rules: %Rules{state: :player_one_turn}]
    end

    test "player_one can guess a coordinate", %{rules: rules} do
      {:ok, %Rules{state: :player_two_turn}} = Rules.check(rules, {:guess_coordinate, :player_one})
    end

    test "player_two cannot guess", %{rules: rules} do
      :error = Rules.check(rules, {:guess_coordinate, :player_two})
    end
  end


  describe ":player_two_turn" do
    setup do
      [rules: %Rules{state: :player_two_turn}]
    end

    test "player_two can guess a coordinate", %{rules: rules} do
      {:ok, %Rules{state: :player_one_turn}} = Rules.check(rules, {:guess_coordinate, :player_two})
    end

    test "player_one cannot guess", %{rules: rules} do
      :error = Rules.check(rules, {:guess_coordinate, :player_one})
    end
  end
end
