defmodule PokemonBattle.Cluster do
  @moduledoc """
  Módulo encargado de manejar funciones básicas de distribución entre nodos.

  Permite:
  - Consultar el nodo actual.
  - Conectar con otros nodos.
  - Listar nodos conectados.
  - Asignar una batalla a un nodo local o remoto.
  """

  alias PokemonBattle.SupervisorBatallas

  def nodo_actual do
    Node.self()
  end

  def nodos_conectados do
    Node.list()
  end

  def conectar_nodo(nombre_nodo) do
    nodo = String.to_atom(nombre_nodo)

    case Node.connect(nodo) do
      true -> {:ok, nodo}
      false -> {:error, :no_se_pudo_conectar}
      :ignored -> {:error, :nodo_no_distribuido}
    end
  end

  def iniciar_batalla(id_sala, jugador_1, jugador_2, tiempo_turno) do
    nodo = seleccionar_nodo_batalla()

    if nodo == Node.self() or nodo == :nonode@nohost do
      iniciar_batalla_local(id_sala, jugador_1, jugador_2, tiempo_turno)
    else
      iniciar_batalla_remota(nodo, id_sala, jugador_1, jugador_2, tiempo_turno)
    end
  end

  defp seleccionar_nodo_batalla do
    case Node.list() do
      [] -> Node.self()
      nodos -> Enum.random(nodos)
    end
  end

  defp iniciar_batalla_local(id_sala, jugador_1, jugador_2, tiempo_turno) do
    case SupervisorBatallas.iniciar_batalla(id_sala, jugador_1, jugador_2, tiempo_turno) do
      {:ok, pid} -> {:ok, pid, Node.self()}
      {:error, razon} -> {:error, razon}
    end
  end

  defp iniciar_batalla_remota(nodo, id_sala, jugador_1, jugador_2, tiempo_turno) do
    respuesta =
      :rpc.call(
        nodo,
        PokemonBattle.SupervisorBatallas,
        :iniciar_batalla,
        [id_sala, jugador_1, jugador_2, tiempo_turno],
        10_000
      )

    case respuesta do
      {:ok, pid} ->
        Process.group_leader(pid, Process.group_leader())
        {:ok, pid, nodo}

      {:error, razon} ->
        {:error, razon}

      {:badrpc, razon} ->
        {:error, {:error_rpc, razon}}

      otro ->
        {:error, {:respuesta_inesperada, otro}}
    end
  end
end
