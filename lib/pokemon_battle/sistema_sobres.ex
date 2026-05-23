defmodule PokemonBattle.SistemaSobres do
  @moduledoc """
  Módulo encargado de la tienda y los sobres.

  Aquí se controla:
  - Listar tienda
  - Comprar sobres
  - Abrir sobres
  - Sortear rareza
  - Crear instancias de Pokémon
  - Asignar movimientos aleatorios
  """

  alias PokemonBattle.Persistencia

  def listar_tienda do
    tienda = Persistencia.cargar_tienda()

    mensaje =
      tienda
      |> Enum.map(fn sobre ->
        probabilidades = sobre["probabilidades"]

        """
        Tipo: #{sobre["tipo"]}
        Precio: #{sobre["precio"]} monedas
        Probabilidades:
          Común: #{probabilidades["comun"] * 100}%
          Raro: #{probabilidades["raro"] * 100}%
          Épico: #{probabilidades["epico"] * 100}%
        """
      end)
      |> Enum.join("\n")

    {:ok, "=== Tienda de sobres ===\n" <> mensaje}
  end

  def comprar_sobre(usuario, tipo_sobre) do
    entrenadores = Persistencia.cargar_entrenadores()
    tienda = Persistencia.cargar_tienda()

    case Map.get(entrenadores, usuario) do
      nil ->
        {:error, :entrenador_no_encontrado}

      entrenador ->
        case Enum.find(tienda, fn sobre -> sobre["tipo"] == tipo_sobre end) do
          nil ->
            {:error, :tipo_sobre_no_existe}

          sobre ->
            precio = sobre["precio"]
            monedas_actuales = Map.get(entrenador, "monedas_actuales", 0)

            if monedas_actuales < precio do
              {:error, :monedas_insuficientes}
            else
              nuevo_sobre = %{
                "id" => generar_id(),
                "tipo" => tipo_sobre
              }

              sobres_actuales = Map.get(entrenador, "sobres", [])

              entrenador_actualizado =
                entrenador
                |> Map.put("monedas_actuales", monedas_actuales - precio)
                |> Map.put("sobres", sobres_actuales ++ [nuevo_sobre])

              entrenadores_actualizados =
                Map.put(entrenadores, usuario, entrenador_actualizado)

              Persistencia.guardar_entrenadores(entrenadores_actualizados)

              {:ok, nuevo_sobre}
            end
        end
    end
  end

  def abrir_sobre(usuario, "ultimo") do
    entrenadores = Persistencia.cargar_entrenadores()

    case Map.get(entrenadores, usuario) do
      nil ->
        {:error, :entrenador_no_encontrado}

      entrenador ->
        sobres = Map.get(entrenador, "sobres", [])

        if sobres == [] do
          {:error, :sin_sobres_pendientes}
        else
          sobre = List.last(sobres)
          abrir_sobre_por_id(usuario, sobre["id"])
        end
    end
  end

  def abrir_sobre(usuario, id_sobre) do
    abrir_sobre_por_id(usuario, id_sobre)
  end

  defp abrir_sobre_por_id(usuario, id_sobre) do
    entrenadores = Persistencia.cargar_entrenadores()
    tienda = Persistencia.cargar_tienda()
    pokemon_base = Persistencia.cargar_pokemon_base()
    movimientos = Persistencia.cargar_movimientos()

    case Map.get(entrenadores, usuario) do
      nil ->
        {:error, :entrenador_no_encontrado}

      entrenador ->
        sobres = Map.get(entrenador, "sobres", [])

        sobre =
          Enum.find(sobres, fn sobre ->
            to_string(sobre["id"]) == to_string(id_sobre)
          end)

        if is_nil(sobre) do
          {:error, :sobre_no_encontrado}
        else
          configuracion_sobre =
            Enum.find(tienda, fn item -> item["tipo"] == sobre["tipo"] end)

          if is_nil(configuracion_sobre) do
            {:error, :configuracion_sobre_no_encontrada}
          else
            nuevos_pokemon =
              Enum.map(1..3, fn _ ->
                crear_pokemon_aleatorio(
                  usuario,
                  configuracion_sobre,
                  pokemon_base,
                  movimientos
                )
              end)

            inventario_actual = Map.get(entrenador, "inventario", [])

            sobres_actualizados =
              Enum.reject(sobres, fn item ->
                to_string(item["id"]) == to_string(id_sobre)
              end)

            entrenador_actualizado =
              entrenador
              |> Map.put("inventario", inventario_actual ++ nuevos_pokemon)
              |> Map.put("sobres", sobres_actualizados)

            entrenadores_actualizados =
              Map.put(entrenadores, usuario, entrenador_actualizado)

            Persistencia.guardar_entrenadores(entrenadores_actualizados)

            {:ok, nuevos_pokemon}
          end
        end
    end
  end

  defp crear_pokemon_aleatorio(usuario, configuracion_sobre, pokemon_base, movimientos) do
    especie = Enum.random(pokemon_base)
    rareza = sortear_rareza(configuracion_sobre["probabilidades"])
    factor = sortear_factor_rareza(rareza)

    ataque =
      especie["ataque_base"]
      |> calcular_estadistica(factor)

    defensa =
      especie["defensa_base"]
      |> calcular_estadistica(factor)

    velocidad =
      especie["velocidad_base"]
      |> calcular_estadistica(factor)

    movimientos_asignados =
      asignar_movimientos(especie["tipos"], movimientos)

    %{
      "id" => generar_id(),
      "especie" => especie["id"],
      "nombre" => especie["nombre"],
      "tipos" => especie["tipos"],
      "dueño_original" => usuario,
      "rareza" => rareza,
      "ataque" => ataque,
      "defensa" => defensa,
      "velocidad" => velocidad,
      "movimientos" => movimientos_asignados
    }
  end

  defp calcular_estadistica(base, factor) do
    round(base * (1 + factor / 100))
  end

  defp sortear_rareza(probabilidades) do
    numero = :rand.uniform()

    comun = probabilidades["comun"]
    raro = probabilidades["raro"]

    cond do
      numero <= comun -> "comun"
      numero <= comun + raro -> "raro"
      true -> "epico"
    end
  end

  defp sortear_factor_rareza("comun"), do: Enum.random(2..8)
  defp sortear_factor_rareza("raro"), do: Enum.random(10..20)
  defp sortear_factor_rareza("epico"), do: Enum.random(25..40)

  defp asignar_movimientos(tipos, movimientos) do
    obligatorios =
      case tipos do
        [tipo1, tipo2] ->
          [
            movimientos |> Map.get(tipo1, []) |> Enum.random(),
            movimientos |> Map.get(tipo2, []) |> Enum.random()
          ]

        [tipo1] ->
          movimientos
          |> Map.get(tipo1, [])
          |> Enum.take_random(2)

        _ ->
          []
      end

    todos_movimientos =
      movimientos
      |> Map.values()
      |> List.flatten()

    nombres_obligatorios =
      Enum.map(obligatorios, fn mov -> mov["nombre"] end)

    adicionales =
      todos_movimientos
      |> Enum.reject(fn mov -> mov["nombre"] in nombres_obligatorios end)
      |> Enum.take_random(4 - length(obligatorios))

    (obligatorios ++ adicionales)
    |> Enum.uniq_by(fn mov -> mov["nombre"] end)
    |> Enum.take(4)
  end

  defp generar_id do
    :rand.uniform(90_000) + 10_000
  end
end
