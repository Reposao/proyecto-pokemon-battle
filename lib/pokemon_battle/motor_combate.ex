defmodule PokemonBattle.MotorCombate do
  @moduledoc """
  Módulo encargado de las reglas principales del combate Pokémon.

  Aquí se calcula:
  - Efectividad de tipos
  - STAB
  - Daño final
  - Orden de turno según velocidad
  """

  @efectividades %{
    "Fuego" => ["Planta", "Hielo", "Bicho"],
    "Agua" => ["Fuego", "Roca", "Tierra"],
    "Planta" => ["Agua", "Roca", "Tierra"],
    "Eléctrico" => ["Agua", "Volador"],
    "Roca" => ["Fuego", "Hielo", "Volador", "Bicho"]
  }

  def calcular_dano(atacante, defensor, movimiento, especies, factor_aleatorio \\ :aleatorio) do
    tipos_atacante = obtener_tipos(atacante, especies)
    tipos_defensor = obtener_tipos(defensor, especies)

    poder = movimiento["poder_base"]
    tipo_movimiento = movimiento["tipo"]
    ataque = atacante["ataque"]
    defensa = defensor["defensa"]

    dano_base =
      trunc((poder * (ataque / defensa)) / 5 + 2)

    modificador_efectividad =
      calcular_efectividad(tipo_movimiento, tipos_defensor)

    modificador_stab =
      calcular_stab(tipo_movimiento, tipos_atacante)

    factor =
      obtener_factor_aleatorio(factor_aleatorio)

    dano_final =
      trunc(dano_base * modificador_efectividad * modificador_stab * factor)

    max(dano_final, 1)
  end

  def calcular_efectividad(tipo_movimiento, tipos_defensor) do
    tipos_defensor
    |> Enum.map(fn tipo_defensor ->
      efectividad_individual(tipo_movimiento, tipo_defensor)
    end)
    |> Enum.reduce(1.0, fn modificador, acc -> acc * modificador end)
  end

  def calcular_stab(tipo_movimiento, tipos_atacante) do
    if tipo_movimiento in tipos_atacante do
      1.5
    else
      1.0
    end
  end

  def ordenar_por_velocidad(pokemon_1, pokemon_2) do
    velocidad_1 = pokemon_1["velocidad"]
    velocidad_2 = pokemon_2["velocidad"]

    cond do
      velocidad_1 > velocidad_2 ->
        [pokemon_1, pokemon_2]

      velocidad_2 > velocidad_1 ->
        [pokemon_2, pokemon_1]

      true ->
        Enum.shuffle([pokemon_1, pokemon_2])
    end
  end

  def aplicar_dano(pokemon, dano) do
    salud_actual = Map.get(pokemon, "salud_actual", 100)

    nueva_salud =
      salud_actual - dano
      |> max(0)

    Map.put(pokemon, "salud_actual", nueva_salud)
  end

  def debilitado?(pokemon) do
    Map.get(pokemon, "salud_actual", 100) <= 0
  end

  defp efectividad_individual(tipo_movimiento, tipo_defensor) do
    cond do
      fuerte_contra?(tipo_movimiento, tipo_defensor) ->
        2.0

      fuerte_contra?(tipo_defensor, tipo_movimiento) ->
        0.5

      true ->
        1.0
    end
  end

  defp fuerte_contra?(tipo_movimiento, tipo_defensor) do
    tipo_movimiento
    |> tipos_fuertes()
    |> Enum.member?(tipo_defensor)
  end

  defp tipos_fuertes(tipo) do
    Map.get(@efectividades, tipo, [])
  end

  defp obtener_tipos(pokemon, especies) do
    especie_id = pokemon["especie"]

    especie =
      Enum.find(especies, fn item ->
        item["id"] == especie_id
      end)

    case especie do
      nil -> Map.get(pokemon, "tipos", [])
      especie -> Map.get(especie, "tipos", [])
    end
  end

  defp obtener_factor_aleatorio(:aleatorio) do
    0.85 + :rand.uniform() * 0.15
  end

  defp obtener_factor_aleatorio(valor), do: valor
end
