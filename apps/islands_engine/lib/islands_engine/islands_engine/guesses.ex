defmodule IslandsEngine.Guesses do
  @moduledoc """
  Holds the list of guesses on the opponent's board
  """

  alias __MODULE__

  @enforce_keys [:hits, :misses]
  defstruct [:hits, :misses]

  def new do
    %Guesses{hits: MapSet.new(), misses: MapSet.new()}
  end
end
