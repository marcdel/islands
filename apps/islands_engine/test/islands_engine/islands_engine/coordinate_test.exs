defmodule IslandsEngine.CoordinateTest do
  @moduledoc false

  use ExUnit.Case
  doctest IslandsEngine.Coordinate

  alias IslandsEngine.Coordinate

  test "can create valid coordinates" do
    {:ok, %Coordinate{row: 1, col: 1}} = Coordinate.new(1, 1)
    {:ok, %Coordinate{row: 10, col: 10}} = Coordinate.new(10, 10)
  end

  test "cannot create invalid coordinates" do
    {:error, :invalid_coordinate} = Coordinate.new(-1, -1)
    {:error, :invalid_coordinate} = Coordinate.new(11, 11)
  end
end
