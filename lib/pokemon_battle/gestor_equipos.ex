defmodule PokemonBattle.GestorEquipos do
  @moduledoc """
  Módulo encargado de gestionar los equipos predefinidos de cada entrenador.

  Permite:
  - Crear equipos de 1 a 3 Pokémon.
  - Listar equipos guardados.
  - Usar un equipo para la siguiente batalla.
  - Agregar Pokémon a un equipo.
  - Quitar Pokémon de un equipo.
  """

  alias PokemonBattle.GestorEntrenadores

  def crear_equipo(usuario, nombre_equipo, ids_texto) do
    with {:ok, ids} <- convertir_ids(ids_texto),
         :ok <- validar_cantidad(ids),
         {:ok, entrenador} <- obtener_entrenador(usuario),
         :ok <- validar_nombre_disponible(entrenador, nombre_equipo),
         :ok <- validar_pokemon_en_inventario(entrenador, ids) do
      equipos = Map.get(entrenador, "equipos", %{})

      equipo = %{
        "nombre" => nombre_equipo,
        "pokemon_ids" => ids
      }

      entrenador_actualizado =
        Map.put(entrenador, "equipos", Map.put(equipos, nombre_equipo, equipo))

      GestorEntrenadores.actualizar_entrenador(usuario, entrenador_actualizado)

      {:ok, equipo}
    end
  end

  def listar_equipos(usuario) do
    case obtener_entrenador(usuario) do
      {:error, razon} ->
        {:error, razon}

      {:ok, entrenador} ->
        equipos = Map.get(entrenador, "equipos", %{})
        inventario = Map.get(entrenador, "inventario", [])

        if map_size(equipos) == 0 do
          {:ok, "No tienes equipos guardados."}
        else
          mensaje =
            equipos
            |> Enum.map(fn {nombre, equipo} ->
              ids = Map.get(equipo, "pokemon_ids", [])

              nombres =
                ids
                |> Enum.map(fn id ->
                  case buscar_pokemon(inventario, id) do
                    nil -> "[##{id}] No encontrado"
                    pokemon -> "[##{pokemon["id"]}] #{pokemon["nombre"]}"
                  end
                end)
                |> Enum.join(", ")

              "#{nombre} [#{length(ids)}/3]: #{nombres}"
            end)
            |> Enum.join("\n")

          {:ok, "=== Equipos guardados ===\n" <> mensaje}
        end
    end
  end

  def usar_equipo(usuario, nombre_equipo) do
    with {:ok, entrenador} <- obtener_entrenador(usuario),
         {:ok, equipo} <- obtener_equipo(entrenador, nombre_equipo),
         :ok <- validar_pokemon_en_inventario(entrenador, equipo["pokemon_ids"]) do
      entrenador_actualizado =
        Map.put(entrenador, "equipo_activo", nombre_equipo)

      GestorEntrenadores.actualizar_entrenador(usuario, entrenador_actualizado)

      {:ok, equipo}
    end
  end

  def agregar_pokemon_equipo(usuario, nombre_equipo, id_texto) do
    with {:ok, id} <- convertir_id(id_texto),
         {:ok, entrenador} <- obtener_entrenador(usuario),
         {:ok, equipo} <- obtener_equipo(entrenador, nombre_equipo),
         :ok <- validar_pokemon_en_inventario(entrenador, [id]) do
      ids_actuales = Map.get(equipo, "pokemon_ids", [])

      cond do
        length(ids_actuales) >= 3 ->
          {:error, :equipo_lleno}

        Enum.any?(ids_actuales, fn item -> to_string(item) == to_string(id) end) ->
          {:error, :pokemon_duplicado_en_equipo}

        true ->
          equipo_actualizado =
            Map.put(equipo, "pokemon_ids", ids_actuales ++ [id])

          equipos =
            entrenador
            |> Map.get("equipos", %{})
            |> Map.put(nombre_equipo, equipo_actualizado)

          entrenador_actualizado =
            Map.put(entrenador, "equipos", equipos)

          GestorEntrenadores.actualizar_entrenador(usuario, entrenador_actualizado)

          {:ok, equipo_actualizado}
      end
    end
  end

  def quitar_pokemon_equipo(usuario, nombre_equipo, id_texto) do
    with {:ok, id} <- convertir_id(id_texto),
         {:ok, entrenador} <- obtener_entrenador(usuario),
         {:ok, equipo} <- obtener_equipo(entrenador, nombre_equipo) do
      ids_actuales = Map.get(equipo, "pokemon_ids", [])

      cond do
        length(ids_actuales) <= 1 ->
          {:error, :no_se_puede_dejar_equipo_vacio}

        not Enum.any?(ids_actuales, fn item -> to_string(item) == to_string(id) end) ->
          {:error, :pokemon_no_esta_en_equipo}

        Map.get(entrenador, "equipo_activo") == nombre_equipo ->
          {:error, :equipo_activo_no_modificable}

        true ->
          ids_actualizados =
            Enum.reject(ids_actuales, fn item -> to_string(item) == to_string(id) end)

          equipo_actualizado =
            Map.put(equipo, "pokemon_ids", ids_actualizados)

          equipos =
            entrenador
            |> Map.get("equipos", %{})
            |> Map.put(nombre_equipo, equipo_actualizado)

          entrenador_actualizado =
            Map.put(entrenador, "equipos", equipos)

          GestorEntrenadores.actualizar_entrenador(usuario, entrenador_actualizado)

          {:ok, equipo_actualizado}
      end
    end
  end

  def obtener_equipo_activo(usuario) do
    with {:ok, entrenador} <- obtener_entrenador(usuario) do
      nombre_equipo = Map.get(entrenador, "equipo_activo")

      if is_nil(nombre_equipo) do
        {:error, :sin_equipo_activo}
      else
        obtener_equipo(entrenador, nombre_equipo)
      end
    end
  end

  def pokemon_en_equipo_activo?(usuario, id_pokemon) do
  case obtener_entrenador(usuario) do
    {:error, _razon} ->
      false

    {:ok, entrenador} ->
      nombre_equipo = Map.get(entrenador, "equipo_activo")

      if is_nil(nombre_equipo) do
        false
      else
        equipos = Map.get(entrenador, "equipos", %{})
        equipo = Map.get(equipos, nombre_equipo)

        if is_nil(equipo) do
          false
        else
          equipo
          |> Map.get("pokemon_ids", [])
          |> Enum.any?(fn id ->
            to_string(id) == to_string(id_pokemon)
          end)
        end
      end
  end
end

  defp obtener_entrenador(usuario) do
    case GestorEntrenadores.obtener_entrenador(usuario) do
      nil -> {:error, :entrenador_no_encontrado}
      entrenador -> {:ok, entrenador}
    end
  end

  defp obtener_equipo(entrenador, nombre_equipo) do
    equipos = Map.get(entrenador, "equipos", %{})

    case Map.get(equipos, nombre_equipo) do
      nil -> {:error, :equipo_no_encontrado}
      equipo -> {:ok, equipo}
    end
  end

  defp validar_nombre_disponible(entrenador, nombre_equipo) do
    equipos = Map.get(entrenador, "equipos", %{})

    if Map.has_key?(equipos, nombre_equipo) do
      {:error, :equipo_duplicado}
    else
      :ok
    end
  end

  defp validar_cantidad(ids) do
    cond do
      length(ids) < 1 -> {:error, :equipo_sin_pokemon}
      length(ids) > 3 -> {:error, :equipo_supera_limite}
      true -> :ok
    end
  end

  defp validar_pokemon_en_inventario(entrenador, ids) do
    inventario = Map.get(entrenador, "inventario", [])

    faltantes =
      Enum.reject(ids, fn id ->
        Enum.any?(inventario, fn pokemon ->
          to_string(pokemon["id"]) == to_string(id)
        end)
      end)

    if faltantes == [] do
      :ok
    else
      {:error, {:pokemon_no_encontrado, faltantes}}
    end
  end

  defp buscar_pokemon(inventario, id) do
    Enum.find(inventario, fn pokemon ->
      to_string(pokemon["id"]) == to_string(id)
    end)
  end

  defp convertir_ids(ids_texto) do
    ids =
      ids_texto
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)

    if ids == [] do
      {:error, :ids_invalidos}
    else
      convertir_lista_ids(ids, [])
    end
  end

  defp convertir_lista_ids([], acc), do: {:ok, Enum.reverse(acc)}

  defp convertir_lista_ids([head | tail], acc) do
    case Integer.parse(head) do
      {numero, ""} -> convertir_lista_ids(tail, [numero | acc])
      _ -> {:error, :id_invalido}
    end
  end

  defp convertir_id(id_texto) do
    case Integer.parse(id_texto) do
      {numero, ""} -> {:ok, numero}
      _ -> {:error, :id_invalido}
    end
  end
end
