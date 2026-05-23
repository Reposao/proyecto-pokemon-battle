defmodule PokemonBattle.GestorIntercambios do
  @moduledoc """
  GenServer encargado de gestionar las salas de intercambio.

  Mantiene en memoria los códigos de sala y el PID del proceso Intercambio.
  """

  use GenServer

  alias PokemonBattle.SupervisorIntercambios
  alias PokemonBattle.Intercambio
  alias PokemonBattle.GestorEquipos
  alias PokemonBattle.GestorSalas

  # =========================
  # API pública
  # =========================

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{salas: %{}, contador: 0}, name: __MODULE__)
  end

  def crear_sala(usuario) do
    GenServer.call(__MODULE__, {:crear_sala, usuario})
  end

  def unirse_sala(codigo, usuario) do
    GenServer.call(__MODULE__, {:unirse_sala, codigo, usuario})
  end

  def ofrecer_pokemon(codigo, usuario, id_pokemon) do
    GenServer.call(__MODULE__, {:ofrecer_pokemon, codigo, usuario, id_pokemon})
  end

  def confirmar_intercambio(codigo, usuario) do
    GenServer.call(__MODULE__, {:confirmar_intercambio, codigo, usuario})
  end

  def cancelar_intercambio(codigo, usuario) do
    GenServer.call(__MODULE__, {:cancelar_intercambio, codigo, usuario})
  end

  def estado_sala(codigo) do
    GenServer.call(__MODULE__, {:estado_sala, codigo})
  end

  def codigo_sala_usuario(usuario) do
    GenServer.call(__MODULE__, {:codigo_sala_usuario, usuario})
  end

  def cancelar_salas_usuario(usuario) do
    GenServer.call(__MODULE__, {:cancelar_salas_usuario, usuario})
  end

  # =========================
  # Callbacks
  # =========================

  @impl true
  def init(estado) do
    {:ok, estado}
  end

  @impl true
  def handle_call({:crear_sala, usuario}, _from, estado) do
    cond do
      usuario_tiene_sala_intercambio?(estado, usuario) ->
        {:reply, {:error, :entrenador_ya_tiene_sala_intercambio}, estado}

      GestorSalas.jugador_en_sala_activa?(usuario) ->
        {:reply, {:error, :entrenador_en_sala_de_batalla}, estado}

      true ->
        contador = estado.contador + 1
        codigo = generar_codigo(contador)

        case SupervisorIntercambios.iniciar_sala(codigo, usuario) do
          {:ok, pid} ->
            salas_actualizadas =
              Map.put(estado.salas, codigo, %{
                codigo: codigo,
                pid: pid,
                creador: usuario
              })

            nuevo_estado =
              estado
              |> Map.put(:salas, salas_actualizadas)
              |> Map.put(:contador, contador)

            {:reply, {:ok, codigo}, nuevo_estado}

          {:error, razon} ->
            {:reply, {:error, razon}, estado}
        end
    end
  end

  @impl true
  def handle_call({:unirse_sala, codigo, usuario}, _from, estado) do
    cond do
      usuario_tiene_sala_intercambio?(estado, usuario) ->
        {:reply, {:error, :entrenador_ya_tiene_sala_intercambio}, estado}

      GestorSalas.jugador_en_sala_activa?(usuario) ->
        {:reply, {:error, :entrenador_en_sala_de_batalla}, estado}

      true ->
        case buscar_sala(estado, codigo) do
          {:error, razon} ->
            {:reply, {:error, razon}, estado}

          {:ok, sala} ->
            respuesta = Intercambio.unirse(sala.pid, usuario)
            {:reply, respuesta, estado}
        end
    end
  end

  @impl true
  def handle_call({:ofrecer_pokemon, codigo, usuario, id_pokemon}, _from, estado) do
    if GestorEquipos.pokemon_en_equipo_activo?(usuario, id_pokemon) do
      {:reply, {:error, :pokemon_en_equipo_activo_no_intercambiable}, estado}
    else
      case buscar_sala(estado, codigo) do
        {:error, razon} ->
          {:reply, {:error, razon}, estado}

        {:ok, sala} ->
          respuesta = Intercambio.ofrecer(sala.pid, usuario, id_pokemon)
          {:reply, respuesta, estado}
      end
    end
  end

  @impl true
  def handle_call({:confirmar_intercambio, codigo, usuario}, _from, estado) do
    case buscar_sala(estado, codigo) do
      {:error, razon} ->
        {:reply, {:error, razon}, estado}

      {:ok, sala} ->
        respuesta = Intercambio.confirmar(sala.pid, usuario)

        nuevo_estado =
          case respuesta do
            {:completado, _resultado, _estado_sala} ->
              eliminar_sala(estado, codigo)

            _ ->
              estado
          end

        {:reply, respuesta, nuevo_estado}
    end
  end

  @impl true
  def handle_call({:cancelar_intercambio, codigo, usuario}, _from, estado) do
    case buscar_sala(estado, codigo) do
      {:error, razon} ->
        {:reply, {:error, razon}, estado}

      {:ok, sala} ->
        respuesta = Intercambio.cancelar(sala.pid, usuario)
        nuevo_estado = eliminar_sala(estado, codigo)
        {:reply, respuesta, nuevo_estado}
    end
  end

  @impl true
  def handle_call({:estado_sala, codigo}, _from, estado) do
    case buscar_sala(estado, codigo) do
      {:error, razon} ->
        {:reply, {:error, razon}, estado}

      {:ok, sala} ->
        respuesta = Intercambio.estado(sala.pid)
        {:reply, respuesta, estado}
    end
  end

  @impl true
  def handle_call({:codigo_sala_usuario, usuario}, _from, estado) do
    case buscar_codigo_sala_usuario(estado, usuario) do
      nil ->
        {:reply, {:error, :sin_sala_intercambio_activa}, estado}

      codigo ->
        {:reply, {:ok, codigo}, estado}
    end
  end

  @impl true
  def handle_call({:cancelar_salas_usuario, usuario}, _from, estado) do
    codigos =
      estado.salas
      |> Enum.filter(fn {_codigo, sala} ->
        case Intercambio.estado(sala.pid) do
          {:ok, estado_sala} ->
            usuario in estado_sala.participantes and estado_sala.estado in [:esperando, :lista]

          _ ->
            false
        end
      end)
      |> Enum.map(fn {codigo, _sala} -> codigo end)

    Enum.each(codigos, fn codigo ->
      sala = Map.get(estado.salas, codigo)

      if sala do
        Intercambio.cancelar(sala.pid, usuario)
      end
    end)

    nuevo_estado =
      Map.put(estado, :salas, Map.drop(estado.salas, codigos))

    {:reply, {:ok, length(codigos)}, nuevo_estado}
  end

  defp usuario_tiene_sala_intercambio?(estado, usuario) do
    estado.salas
    |> Map.values()
    |> Enum.any?(fn sala ->
      case Intercambio.estado(sala.pid) do
        {:ok, estado_sala} ->
          usuario in estado_sala.participantes and estado_sala.estado in [:esperando, :lista]

        _ ->
          false
      end
    end)
  end

  defp buscar_codigo_sala_usuario(estado, usuario) do
    estado.salas
    |> Enum.find_value(fn {codigo, sala} ->
      case Intercambio.estado(sala.pid) do
        {:ok, estado_sala} ->
          if usuario in estado_sala.participantes and estado_sala.estado in [:esperando, :lista] do
            codigo
          else
            nil
          end

        _ ->
          nil
      end
    end)
  end

  defp buscar_sala(estado, codigo) do
    case Map.get(estado.salas, codigo) do
      nil -> {:error, :sala_intercambio_no_encontrada}
      sala -> {:ok, sala}
    end
  end

  defp eliminar_sala(estado, codigo) do
    Map.put(estado, :salas, Map.delete(estado.salas, codigo))
  end

  defp generar_codigo(contador) do
    numero =
      contador
      |> Integer.to_string()
      |> String.pad_leading(3, "0")

    "IC-#{numero}"
  end
end
