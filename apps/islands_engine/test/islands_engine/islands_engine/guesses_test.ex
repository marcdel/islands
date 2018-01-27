defmodule IslandsEngine.GuessesTest do
  @moduledoc false

  use ExUnit.Case
  doctest IslandsEngine.Guesses

  alias IslandsEngine.Guesses

  test "can create new list of guesses" do
    %Guesses{hits: hits, misses: misses} = Guesses.new()
    assert MapSet.size(hits) == 0
    assert MapSet.size(misses) == 0
  end
end
