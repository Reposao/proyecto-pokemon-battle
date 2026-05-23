defmodule PokemonBattle.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PokemonBattle.GestorSalas,
      PokemonBattle.SupervisorBatallas,
      PokemonBattle.SupervisorIntercambios,
      PokemonBattle.GestorIntercambios

]

    opts = [strategy: :one_for_one, name: PokemonBattle.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
