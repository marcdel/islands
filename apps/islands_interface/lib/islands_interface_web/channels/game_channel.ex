defmodule IslandsInterfaceWeb.GameChannel do
  use IslandsInterfaceWeb, :channel

  alias IslandsEngine.{Game, GameSupervisor}

  def join("game:" <> _player, payload, socket) do
    {:ok, socket}
  end

  def handle_in("new_game", _payload, socket) do
    "game:" <> player_name = socket.topic

    case(GameSupervisor.start_game(player_name)) do
      {:ok, _pid} ->
        {:reply, :ok, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: inspect(reason)}}, socket}
    end
  end

  def handle_in("add_player", player_name, socket) do
    case Game.add_player(via(socket.topic), player_name) do
      :ok ->
        broadcast!(socket, "player_added", %{message: "A new player just joined: " <> player_name})

        {:noreply, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: inspect(reason)}}, socket}

      :error ->
        {:reply, :error, socket}
    end
  end

  defp via("game:" <> player_name), do: Game.via_tuple(player_name)
end
