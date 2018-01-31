defmodule IslandsEngine.GuessesTest do
  @moduledoc false

  use ExUnit.Case
  doctest IslandsEngine.Guesses

  alias IslandsEngine.{Guesses, Coordinate}

  test "can create new list of guesses" do
    %Guesses{hits: hits, misses: misses} = Guesses.new()
    assert MapSet.size(hits) == 0
    assert MapSet.size(misses) == 0
  end

  test "can add hits" do
    guesses = Guesses.new()
    {:ok, hit} = Coordinate.new(1, 1)
    %Guesses{hits: hits} = Guesses.add(guesses, :hit, hit)
    assert hit in hits
  end

  test "can add misses" do
    guesses = Guesses.new()
    {:ok, miss} = Coordinate.new(1, 1)
    %Guesses{misses: misses} = Guesses.add(guesses, :miss, miss)
    assert miss in misses
  end
end
