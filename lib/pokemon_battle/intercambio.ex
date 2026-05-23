defmodule PokemonBattle.Intercambio do
  @moduledoc """
  GenServer que representa una sala de intercambio entre dos entrenadores.

  Permite:
  - Unirse a una sala.
  - Ofrecer un Pokémon.
  - Confirmar el intercambio.
  - Cancelar la sala.
  - Ejecutar el cambio real de inventarios.
  """

  use GenServer

  alias PokemonBattle.Persistencia

  def start_link(datos) do
    GenServer.start_link(__MODULE__, datos)
  end

  def unirse(pid, usuario) do
    GenServer.call(pid, {:unirse, usuario})
  end

  def ofrecer(pid, usuario, id_pokemon) do
    GenServer.call(pid, {:ofrecer, usuario, id_pokemon})
  end

  def confirmar(pid, usuario) do
    GenServer.call(pid, {:confirmar, usuario})
  end

  def cancelar(pid, usuario) do
    GenServer.call(pid, {:cancelar, usuario})
  end

  def estado(pid) do
    GenServer.call(pid, :estado)
  end

  @impl true
  def init(%{codigo: codigo, creador: creador}) do
    estado = %{
      codigo: codigo,
      participantes: [creador],
      ofertas: %{},
      confirmaciones: %{},
      estado: :esperando
    }

    {:ok, estado}
  end

  @impl true
  def handle_call({:unirse, usuario}, _from, estado) do
    cond do
      usuario in estado.participantes ->
        {:reply, {:error, :no_puedes_unirte_a_tu_propia_sala}, estado}

      length(estado.participantes) >= 2 ->
        {:reply, {:error, :sala_llena}, estado}

      true ->
        nuevo_estado =
          estado
          |> Map.put(:participantes, estado.participantes ++ [usuario])
          |> Map.put(:estado, :lista)

        {:reply, {:ok, nuevo_estado}, nuevo_estado}
    end
  end

  @impl true
  def handle_call({:ofrecer, usuario, id_pokemon}, _from, estado) do
    cond do
      usuario not in estado.participantes ->
        {:reply, {:error, :usuario_no_participa}, estado}

      length(estado.participantes) < 2 ->
        {:reply, {:error, :faltan_participantes}, estado}

      true ->
        case buscar_pokemon_usuario(usuario, id_pokemon) do
          nil ->
            {:reply, {:error, :pokemon_no_encontrado}, estado}

          pokemon ->
            nuevas_ofertas =
              Map.put(estado.ofertas, usuario, pokemon)

            nuevas_confirmaciones =
              Map.put(estado.confirmaciones, usuario, false)

            nuevo_estado =
              estado
              |> Map.put(:ofertas, nuevas_ofertas)
              |> Map.put(:confirmaciones, nuevas_confirmaciones)

            {:reply, {:ok, nuevo_estado}, nuevo_estado}
        end
    end
  end

  @impl true
  def handle_call({:confirmar, usuario}, _from, estado) do
    cond do
      usuario not in estado.participantes ->
        {:reply, {:error, :usuario_no_participa}, estado}

      not Map.has_key?(estado.ofertas, usuario) ->
        {:reply, {:error, :debes_ofrecer_un_pokemon}, estado}

      true ->
        confirmaciones_actualizadas =
          Map.put(estado.confirmaciones, usuario, true)

        estado_confirmado =
          Map.put(estado, :confirmaciones, confirmaciones_actualizadas)

        if listo_para_intercambiar?(estado_confirmado) do
          case ejecutar_intercambio(estado_confirmado) do
            {:ok, resultado} ->
              nuevo_estado =
                estado_confirmado
                |> Map.put(:estado, :completada)

              {:reply, {:completado, resultado, nuevo_estado}, nuevo_estado}

            {:error, razon} ->
              {:reply, {:error, razon}, estado_confirmado}
          end
        else
          {:reply, {:ok, estado_confirmado}, estado_confirmado}
        end
    end
  end

  @impl true
  def handle_call({:cancelar, usuario}, _from, estado) do
    if usuario in estado.participantes do
      nuevo_estado = Map.put(estado, :estado, :cancelada)
      {:reply, {:cancelada, nuevo_estado}, nuevo_estado}
    else
      {:reply, {:error, :usuario_no_participa}, estado}
    end
  end

  @impl true
  def handle_call(:estado, _from, estado) do
    {:reply, {:ok, estado}, estado}
  end

  defp listo_para_intercambiar?(estado) do
    length(estado.participantes) == 2 and
      map_size(estado.ofertas) == 2 and
      Enum.all?(estado.participantes, fn usuario ->
        Map.get(estado.confirmaciones, usuario, false)
      end)
  end

  defp ejecutar_intercambio(estado) do
    [usuario_1, usuario_2] = estado.participantes

    pokemon_1 = Map.get(estado.ofertas, usuario_1)
    pokemon_2 = Map.get(estado.ofertas, usuario_2)

    entrenadores = Persistencia.cargar_entrenadores()

    entrenador_1 = Map.get(entrenadores, usuario_1)
    entrenador_2 = Map.get(entrenadores, usuario_2)

    if is_nil(entrenador_1) or is_nil(entrenador_2) do
      {:error, :entrenador_no_encontrado}
    else
      inventario_1 = Map.get(entrenador_1, "inventario", [])
      inventario_2 = Map.get(entrenador_2, "inventario", [])

      inventario_1_actualizado =
        inventario_1
        |> quitar_pokemon(pokemon_1["id"])
        |> Kernel.++([pokemon_2])

      inventario_2_actualizado =
        inventario_2
        |> quitar_pokemon(pokemon_2["id"])
        |> Kernel.++([pokemon_1])

      entrenador_1_actualizado =
        Map.put(entrenador_1, "inventario", inventario_1_actualizado)

      entrenador_2_actualizado =
        Map.put(entrenador_2, "inventario", inventario_2_actualizado)

      entrenadores_actualizados =
        entrenadores
        |> Map.put(usuario_1, entrenador_1_actualizado)
        |> Map.put(usuario_2, entrenador_2_actualizado)

      Persistencia.guardar_entrenadores(entrenadores_actualizados)

      resultado = %{
        usuario_1: usuario_1,
        usuario_2: usuario_2,
        pokemon_1: pokemon_1,
        pokemon_2: pokemon_2
      }

      {:ok, resultado}
    end
  end

  defp buscar_pokemon_usuario(usuario, id_pokemon) do
    Persistencia.cargar_entrenadores()
    |> Map.get(usuario)
    |> case do
      nil ->
        nil

      entrenador ->
        entrenador
        |> Map.get("inventario", [])
        |> Enum.find(fn pokemon ->
          to_string(pokemon["id"]) == to_string(id_pokemon)
        end)
    end
  end

  defp quitar_pokemon(inventario, id_pokemon) do
    Enum.reject(inventario, fn pokemon ->
      to_string(pokemon["id"]) == to_string(id_pokemon)
    end)
  end
end
