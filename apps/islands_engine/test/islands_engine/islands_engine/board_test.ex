defmodule IslandsEngine.BoardTest do
  @moduledoc false

  use ExUnit.Case
  doctest IslandsEngine.Board

  alias IslandsEngine.Board

  test "can create new list of guesses" do
    %{} = Board.new()
  end
end
