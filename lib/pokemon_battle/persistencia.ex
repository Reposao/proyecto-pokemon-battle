defmodule PokemonBattle.Persistencia do
  @moduledoc """
  Módulo encargado de leer y guardar la información del proyecto en archivos JSON.

  Aquí se manejan:
  - Entrenadores
  - Pokémon base
  - Movimientos
  - Tienda
  - Registro de batallas
  """

  @trainers_path "data/trainers.json"
  @pokemon_path "data/pokemon.json"
  @moves_path "data/moves.json"
  @tienda_path "data/tienda.json"
  @battles_log_path "data/battles.log"

  def cargar_entrenadores do
    leer_json(@trainers_path, %{})
  end

  def guardar_entrenadores(entrenadores) do
    escribir_json(@trainers_path, entrenadores)
  end

  def cargar_pokemon_base do
    leer_json(@pokemon_path, [])
  end

  def cargar_movimientos do
    leer_json(@moves_path, %{})
  end

  def cargar_tienda do
    leer_json(@tienda_path, [])
  end

  def buscar_especie(especie_id) do
    cargar_pokemon_base()
    |> Enum.find(fn especie -> especie["id"] == especie_id end)
  end

  def registrar_batalla(jugadores, ganador, nodo, duracion, resumen) do
    fecha = DateTime.utc_now() |> DateTime.to_string()

    linea =
      "#{fecha} | Jugadores: #{Enum.join(jugadores, " vs ")} | Ganador: #{ganador} | Nodo: #{nodo} | Duración: #{duracion} | #{resumen}\n"

    File.write!(@battles_log_path, linea, [:append])
  end

  defp leer_json(path, valor_por_defecto) do
    case File.read(path) do
      {:ok, ""} ->
        valor_por_defecto

      {:ok, contenido} ->
        case Jason.decode(contenido) do
          {:ok, datos} -> datos
          {:error, _razon} -> valor_por_defecto
        end

      {:error, _razon} ->
        valor_por_defecto
    end
  end

  defp escribir_json(path, datos) do
    File.mkdir_p!(Path.dirname(path))

    datos
    |> Jason.encode!(pretty: true)
    |> then(fn contenido -> File.write!(path, contenido) end)
  end
end
