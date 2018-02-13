defmodule IslandsEngine.GameSupervisorTest do
  use ExUnit.Case

  alias IslandsEngine.GameSupervisor

  test "can start a new GameSupervisor" do
    assert {:ok, pid} = GameSupervisor.start_link(:bleh)
  end
end
