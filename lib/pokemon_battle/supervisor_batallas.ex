defmodule PokemonBattle.SupervisorBatallas do
  @moduledoc """
  Supervisor dinámico encargado de iniciar procesos de batalla.

  Cada batalla vive en su propio proceso GenServer.
  """

  use DynamicSupervisor

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def iniciar_batalla(id_sala, jugador_1, jugador_2, tiempo_turno) do
    spec = {
      PokemonBattle.Batalla,
      %{
        id_sala: id_sala,
        jugador_1: jugador_1,
        jugador_2: jugador_2,
        tiempo_turno: tiempo_turno
      }
    }

    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
