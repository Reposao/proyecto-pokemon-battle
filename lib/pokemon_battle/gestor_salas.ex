defmodule PokemonBattle.GestorSalas do
  @moduledoc """
  GenServer encargado de gestionar las salas de batalla.

  Este módulo mantiene en memoria las salas creadas mientras la aplicación está
  ejecutándose. Permite crear salas, listar salas disponibles y unir jugadores.
  """

  use GenServer

  # =========================
  # API pública
  # =========================

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{salas: %{}, contador: 1000}, name: __MODULE__)
  end

  def crear_sala(creador, tiempo_turno \\ 20) do
    GenServer.call(__MODULE__, {:crear_sala, creador, tiempo_turno})
  end

  def listar_salas do
    GenServer.call(__MODULE__, :listar_salas)
  end

  def unirse_sala(id_sala, jugador) do
    GenServer.call(__MODULE__, {:unirse_sala, id_sala, jugador})
  end

  def obtener_sala(id_sala) do
    GenServer.call(__MODULE__, {:obtener_sala, id_sala})
  end

  def marcar_en_batalla(id_sala) do
    GenServer.call(__MODULE__, {:marcar_en_batalla, id_sala})
  end

  def finalizar_sala(id_sala) do
    GenServer.call(__MODULE__, {:finalizar_sala, id_sala})
  end

  def jugador_en_sala_activa?(jugador) do
    GenServer.call(__MODULE__, {:jugador_en_sala_activa, jugador})
  end

  # =========================
  # Callbacks GenServer
  # =========================

  @impl true
  def init(estado) do
    {:ok, estado}
  end

  @impl true
  def handle_call({:crear_sala, creador, tiempo_turno}, _from, estado) do
    contador = estado.contador + 1
    id_sala = "S-#{contador}"

    sala = %{
      "id" => id_sala,
      "creador" => creador,
      "jugadores" => [creador],
      "estado" => "esperando",
      "tiempo_turno" => tiempo_turno
    }

    salas_actualizadas =
      Map.put(estado.salas, id_sala, sala)

    nuevo_estado =
      estado
      |> Map.put(:salas, salas_actualizadas)
      |> Map.put(:contador, contador)

    {:reply, {:ok, sala}, nuevo_estado}
  end

  @impl true
  def handle_call(:listar_salas, _from, estado) do
    salas =
      estado.salas
      |> Map.values()
      |> Enum.sort_by(fn sala -> sala["id"] end)

    {:reply, {:ok, salas}, estado}
  end

  @impl true
  def handle_call({:unirse_sala, id_sala, jugador}, _from, estado) do
    case Map.get(estado.salas, id_sala) do
      nil ->
        {:reply, {:error, :sala_no_encontrada}, estado}

      sala ->
        jugadores = sala["jugadores"]

        cond do
          jugador in jugadores ->
            {:reply, {:error, :ya_estas_en_la_sala}, estado}

          length(jugadores) >= 2 ->
            {:reply, {:error, :sala_llena}, estado}

          sala["estado"] != "esperando" ->
            {:reply, {:error, :sala_no_disponible}, estado}

          true ->
            sala_actualizada =
              sala
              |> Map.put("jugadores", jugadores ++ [jugador])
              |> Map.put("estado", "lista")

            salas_actualizadas =
              Map.put(estado.salas, id_sala, sala_actualizada)

            nuevo_estado =
              Map.put(estado, :salas, salas_actualizadas)

            {:reply, {:ok, sala_actualizada}, nuevo_estado}
        end
    end
  end

  @impl true
  def handle_call({:obtener_sala, id_sala}, _from, estado) do
    case Map.get(estado.salas, id_sala) do
      nil -> {:reply, {:error, :sala_no_encontrada}, estado}
      sala -> {:reply, {:ok, sala}, estado}
    end
  end

  @impl true
  def handle_call({:marcar_en_batalla, id_sala}, _from, estado) do
    case Map.get(estado.salas, id_sala) do
      nil ->
        {:reply, {:error, :sala_no_encontrada}, estado}

      sala ->
        sala_actualizada =
          Map.put(sala, "estado", "en_batalla")

        salas_actualizadas =
          Map.put(estado.salas, id_sala, sala_actualizada)

        nuevo_estado =
          Map.put(estado, :salas, salas_actualizadas)

        {:reply, {:ok, sala_actualizada}, nuevo_estado}
    end
  end

  @impl true
  def handle_call({:finalizar_sala, id_sala}, _from, estado) do
    nuevo_estado =
      Map.put(estado, :salas, Map.delete(estado.salas, id_sala))

    {:reply, :ok, nuevo_estado}
  end

  @impl true
  def handle_call({:jugador_en_sala_activa, jugador}, _from, estado) do
    esta_en_sala =
      estado.salas
      |> Map.values()
      |> Enum.any?(fn sala ->
        jugador in sala["jugadores"] and sala["estado"] in ["esperando", "lista", "en_batalla"]
      end)

    {:reply, esta_en_sala, estado}
  end
end
