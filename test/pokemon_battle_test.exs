defmodule PokemonBattleTest do
  use ExUnit.Case

  alias PokemonBattle.MotorCombate
  alias PokemonBattle.GestorEntrenadores
  alias PokemonBattle.SistemaSobres
  alias PokemonBattle.GestorIntercambios
  alias PokemonBattle.Persistencia

  @trainers_path "data/trainers.json"

  setup do
    contenido_original =
      if File.exists?(@trainers_path) do
        File.read!(@trainers_path)
      else
        "{}"
      end

    File.write!(@trainers_path, "{}")

    on_exit(fn ->
      File.write!(@trainers_path, contenido_original)
    end)

    :ok
  end

  test "calcula efectividad fuerte, debil y neutra" do
    assert MotorCombate.calcular_efectividad("Eléctrico", ["Agua"]) == 2.0
    assert MotorCombate.calcular_efectividad("Agua", ["Eléctrico"]) == 0.5
    assert MotorCombate.calcular_efectividad("Normal", ["Agua"]) == 1.0
  end

  test "ordena el turno por velocidad" do
    pikachu = %{
      "id" => 1,
      "nombre" => "Pikachu",
      "velocidad" => 104
    }

    squirtle = %{
      "id" => 2,
      "nombre" => "Squirtle",
      "velocidad" => 46
    }

    [primero, segundo] =
      MotorCombate.ordenar_por_velocidad(squirtle, pikachu)

    assert primero["nombre"] == "Pikachu"
    assert segundo["nombre"] == "Squirtle"
  end

  test "asigna monedas al ganador y al perdedor de una batalla" do
    entrenadores = %{
      "ana" => crear_entrenador_base(),
      "luis" => crear_entrenador_base()
    }

    Persistencia.guardar_entrenadores(entrenadores)

    GestorEntrenadores.registrar_victoria("ana")
    GestorEntrenadores.sumar_monedas("ana", 100)
    GestorEntrenadores.sumar_monedas("luis", 30)

    datos = Persistencia.cargar_entrenadores()

    assert datos["ana"]["victorias"] == 1
    assert datos["ana"]["monedas_actuales"] == 100
    assert datos["ana"]["monedas_acumuladas"] == 100
    assert datos["luis"]["monedas_actuales"] == 30
    assert datos["luis"]["monedas_acumuladas"] == 30
  end

  test "compra y abre un sobre correctamente" do
    entrenadores = %{
      "ana" =>
        crear_entrenador_base()
        |> Map.put("monedas_actuales", 300)
        |> Map.put("monedas_acumuladas", 300)
    }

    Persistencia.guardar_entrenadores(entrenadores)

    assert {:ok, sobre} = SistemaSobres.comprar_sobre("ana", "basico")
    assert sobre["tipo"] == "basico"

    assert {:ok, nuevos_pokemon} = SistemaSobres.abrir_sobre("ana", "ultimo")

    assert length(nuevos_pokemon) == 3

    Enum.each(nuevos_pokemon, fn pokemon ->
      assert pokemon["dueño_original"] == "ana"
      assert pokemon["rareza"] in ["comun", "raro", "epico"]
      assert length(pokemon["movimientos"]) == 4
      assert pokemon["ataque"] > 0
      assert pokemon["defensa"] > 0
      assert pokemon["velocidad"] > 0
    end)
  end

  test "intercambia pokemon entre dos entrenadores conservando sus datos" do
    pokemon_ana = %{
      "id" => 11111,
      "especie" => "pikachu",
      "nombre" => "Pikachu",
      "tipos" => ["Eléctrico"],
      "dueño_original" => "ana",
      "rareza" => "raro",
      "ataque" => 63,
      "defensa" => 46,
      "velocidad" => 104,
      "movimientos" => [
        %{"nombre" => "impactrueno", "tipo" => "Eléctrico", "poder_base" => 65},
        %{"nombre" => "chispa", "tipo" => "Eléctrico", "poder_base" => 50},
        %{"nombre" => "ataque_rapido", "tipo" => "Normal", "poder_base" => 40},
        %{"nombre" => "ráfaga", "tipo" => "Volador", "poder_base" => 60}
      ]
    }

    pokemon_luis = %{
      "id" => 22222,
      "especie" => "charmander",
      "nombre" => "Charmander",
      "tipos" => ["Fuego"],
      "dueño_original" => "luis",
      "rareza" => "comun",
      "ataque" => 55,
      "defensa" => 45,
      "velocidad" => 68,
      "movimientos" => [
        %{"nombre" => "ascuas", "tipo" => "Fuego", "poder_base" => 30},
        %{"nombre" => "lanzallamas", "tipo" => "Fuego", "poder_base" => 80},
        %{"nombre" => "placaje", "tipo" => "Normal", "poder_base" => 35},
        %{"nombre" => "picadura", "tipo" => "Bicho", "poder_base" => 32}
      ]
    }

    entrenadores = %{
      "ana" =>
        crear_entrenador_base()
        |> Map.put("inventario", [pokemon_ana]),

      "luis" =>
        crear_entrenador_base()
        |> Map.put("inventario", [pokemon_luis])
    }

    Persistencia.guardar_entrenadores(entrenadores)

    assert {:ok, codigo} = GestorIntercambios.crear_sala("ana")
    assert {:ok, _estado} = GestorIntercambios.unirse_sala(codigo, "luis")
    assert {:ok, _estado} = GestorIntercambios.ofrecer_pokemon(codigo, "ana", 11111)
    assert {:ok, _estado} = GestorIntercambios.ofrecer_pokemon(codigo, "luis", 22222)
    assert {:ok, _estado} = GestorIntercambios.confirmar_intercambio(codigo, "ana")
    assert {:completado, _resultado, _estado} = GestorIntercambios.confirmar_intercambio(codigo, "luis")

    datos = Persistencia.cargar_entrenadores()

    inventario_ana = datos["ana"]["inventario"]
    inventario_luis = datos["luis"]["inventario"]

    assert Enum.any?(inventario_ana, fn pokemon -> pokemon["id"] == 22222 end)
    assert Enum.any?(inventario_luis, fn pokemon -> pokemon["id"] == 11111 end)

    pokemon_recibido_ana =
      Enum.find(inventario_ana, fn pokemon -> pokemon["id"] == 22222 end)

    assert pokemon_recibido_ana["dueño_original"] == "luis"
    assert pokemon_recibido_ana["rareza"] == "comun"
    assert length(pokemon_recibido_ana["movimientos"]) == 4
  end

  test "no permite crear sala de intercambio si el entrenador esta en sala de batalla" do
    usuario = "jugador_batalla_#{System.unique_integer([:positive])}"

    entrenadores = %{
      usuario => crear_entrenador_base()
    }

    Persistencia.guardar_entrenadores(entrenadores)

    assert {:ok, _sala} = PokemonBattle.GestorSalas.crear_sala(usuario, 20)

    assert {:error, :entrenador_en_sala_de_batalla} =
             PokemonBattle.GestorIntercambios.crear_sala(usuario)
  end

  test "no permite que un entrenador tenga dos salas de intercambio activas" do
    usuario = "jugador_intercambio_#{System.unique_integer([:positive])}"

    entrenadores = %{
      usuario => crear_entrenador_base()
    }

    Persistencia.guardar_entrenadores(entrenadores)

    assert {:ok, _codigo} = PokemonBattle.GestorIntercambios.crear_sala(usuario)

    assert {:error, :entrenador_ya_tiene_sala_intercambio} =
             PokemonBattle.GestorIntercambios.crear_sala(usuario)
  end

  test "no permite ofrecer en intercambio un pokemon del equipo activo" do
    usuario_1 = "ana_intercambio_#{System.unique_integer([:positive])}"
    usuario_2 = "luis_intercambio_#{System.unique_integer([:positive])}"

    pokemon_ana = %{
      "id" => 11111,
      "especie" => "pikachu",
      "nombre" => "Pikachu",
      "tipos" => ["Eléctrico"],
      "dueño_original" => usuario_1,
      "rareza" => "raro",
      "ataque" => 63,
      "defensa" => 46,
      "velocidad" => 104,
      "movimientos" => [
        %{"nombre" => "impactrueno", "tipo" => "Eléctrico", "poder_base" => 65},
        %{"nombre" => "chispa", "tipo" => "Eléctrico", "poder_base" => 50},
        %{"nombre" => "ataque_rapido", "tipo" => "Normal", "poder_base" => 40},
        %{"nombre" => "ráfaga", "tipo" => "Volador", "poder_base" => 60}
      ]
    }

    pokemon_luis = %{
      "id" => 22222,
      "especie" => "charmander",
      "nombre" => "Charmander",
      "tipos" => ["Fuego"],
      "dueño_original" => usuario_2,
      "rareza" => "comun",
      "ataque" => 55,
      "defensa" => 45,
      "velocidad" => 68,
      "movimientos" => [
        %{"nombre" => "ascuas", "tipo" => "Fuego", "poder_base" => 30},
        %{"nombre" => "lanzallamas", "tipo" => "Fuego", "poder_base" => 80},
        %{"nombre" => "placaje", "tipo" => "Normal", "poder_base" => 35},
        %{"nombre" => "picadura", "tipo" => "Bicho", "poder_base" => 32}
      ]
    }

    entrenadores = %{
      usuario_1 =>
        crear_entrenador_base()
        |> Map.put("inventario", [pokemon_ana])
        |> Map.put("equipos", %{
          "rapido" => %{
            "nombre" => "rapido",
            "pokemon_ids" => [11111]
          }
        })
        |> Map.put("equipo_activo", "rapido"),

      usuario_2 =>
        crear_entrenador_base()
        |> Map.put("inventario", [pokemon_luis])
    }

    Persistencia.guardar_entrenadores(entrenadores)

    assert {:ok, codigo} = PokemonBattle.GestorIntercambios.crear_sala(usuario_1)
    assert {:ok, _estado} = PokemonBattle.GestorIntercambios.unirse_sala(codigo, usuario_2)

    assert {:error, :pokemon_en_equipo_activo_no_intercambiable} =
             PokemonBattle.GestorIntercambios.ofrecer_pokemon(codigo, usuario_1, 11111)
  end

  defp crear_entrenador_base do
    %{
      "clave" => "1234",
      "victorias" => 0,
      "monedas_actuales" => 0,
      "monedas_acumuladas" => 0,
      "inventario" => [],
      "sobres" => [],
      "equipos" => %{}
    }
  end
end
