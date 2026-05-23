defmodule PokemonBattle.SupervisorIntercambios do
  @moduledoc """
  Supervisor dinámico encargado de iniciar salas de intercambio.

  Cada sala de intercambio vive en su propio proceso GenServer.
  """

  use DynamicSupervisor

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def iniciar_sala(codigo, creador) do
    spec = {
      PokemonBattle.Intercambio,
      %{
        codigo: codigo,
        creador: creador
      }
    }

    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
