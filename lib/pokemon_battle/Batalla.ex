defmodule PokemonBattle.Batalla do
  @moduledoc """
  GenServer que representa una batalla Pokémon 1v1.

  Esta versión maneja:
  - Batalla por turnos.
  - Visualización del estado al inicio de cada turno.
  - Acciones: ataque, cambiar y rendirse.
  - Orden por velocidad.
  - Daño con STAB, efectividad y factor aleatorio.
  - Cambio automático o manual de Pokémon debilitado.
  - Recompensas de monedas.
  - Registro en battles.log.
  """

  use GenServer

  alias PokemonBattle.GestorEntrenadores
  alias PokemonBattle.GestorEquipos
  alias PokemonBattle.MotorCombate
  alias PokemonBattle.Persistencia

  # =========================
  # API pública
  # =========================

  def start_link(datos) do
    GenServer.start_link(__MODULE__, datos)
  end

  def estado(pid) do
    GenServer.call(pid, :estado)
  end

  def resolver_batalla(pid) do
    GenServer.call(pid, :resolver_batalla, :infinity)
  end

  # =========================
  # Callbacks
  # =========================

  @impl true
  def init(datos) do
    jugador_1 = datos.jugador_1
    jugador_2 = datos.jugador_2

    with {:ok, equipo_1} <- cargar_equipo_completo(jugador_1),
         {:ok, equipo_2} <- cargar_equipo_completo(jugador_2) do
      estado = %{
        id_sala: datos.id_sala,
        jugador_1: jugador_1,
        jugador_2: jugador_2,
        equipo_1: equipo_1,
        equipo_2: equipo_2,
        activo_1: obtener_id_primer_vivo(equipo_1),
        activo_2: obtener_id_primer_vivo(equipo_2),
        tiempo_turno: datos.tiempo_turno,
        turno: 1,
        terminado: false,
        ganador: nil,
        resumen: []
      }

      {:ok, estado}
    else
      {:error, razon} ->
        {:stop, razon}
    end
  end

  @impl true
  def handle_call(:estado, _from, estado) do
    {:reply, {:ok, generar_estado_batalla(estado)}, estado}
  end

  @impl true
  def handle_call(:resolver_batalla, _from, estado) do
    estado_final = ejecutar_batalla_interactiva(estado)

    actualizar_recompensas(estado_final)
    registrar_log(estado_final)

    {:reply, {:ok, estado_final.ganador, estado_final.resumen}, estado_final}
  end

  # =========================
  # Flujo principal de batalla
  # =========================

  defp ejecutar_batalla_interactiva(estado) do
    cond do
      todos_debilitados?(estado.equipo_1) ->
        %{estado | terminado: true, ganador: estado.jugador_2}

      todos_debilitados?(estado.equipo_2) ->
        %{estado | terminado: true, ganador: estado.jugador_1}

      estado.turno > 100 ->
        ganador = decidir_ganador_por_salud(estado)

        agregar_resumen(
          %{estado | terminado: true, ganador: ganador},
          "La batalla superó el límite de turnos. Ganador por salud restante: #{ganador}."
        )

      true ->
        estado_preparado = preparar_activos(estado)

        if estado_preparado.terminado do
          estado_preparado
        else
          nuevo_estado = ejecutar_turno_interactivo(estado_preparado)
          ejecutar_batalla_interactiva(%{nuevo_estado | turno: nuevo_estado.turno + 1})
        end
    end
  end

  defp ejecutar_turno_interactivo(estado) do
    IO.puts("\n════════════════════════════════════")
    IO.puts("              TURNO #{estado.turno}")
    IO.puts("════════════════════════════════════")

    mostrar_estado_turno(estado, 1)
    accion_1 = pedir_accion_valida(estado, 1)

    mostrar_estado_turno(estado, 2)
    accion_2 = pedir_accion_valida(estado, 2)

    pokemon_1 = pokemon_activo(estado.equipo_1, estado.activo_1)
    pokemon_2 = pokemon_activo(estado.equipo_2, estado.activo_2)

    orden =
      MotorCombate.ordenar_por_velocidad(
        Map.put(pokemon_1, "numero_jugador", 1),
        Map.put(pokemon_2, "numero_jugador", 2)
      )

    [primero, segundo] = orden

    accion_primero =
      if primero["numero_jugador"] == 1, do: accion_1, else: accion_2

    accion_segundo =
      if segundo["numero_jugador"] == 1, do: accion_1, else: accion_2

    estado_despues_primero =
      resolver_accion(estado, primero["numero_jugador"], accion_primero)

    if estado_despues_primero.terminado do
      estado_despues_primero
    else
      segundo_actual =
        if segundo["numero_jugador"] == 1 do
          pokemon_activo(estado_despues_primero.equipo_1, estado_despues_primero.activo_1)
        else
          pokemon_activo(estado_despues_primero.equipo_2, estado_despues_primero.activo_2)
        end

      if is_nil(segundo_actual) or MotorCombate.debilitado?(segundo_actual) do
        agregar_resumen(
          estado_despues_primero,
          "El segundo Pokémon no ejecuta acción porque quedó debilitado antes de actuar."
        )
      else
        resolver_accion(estado_despues_primero, segundo["numero_jugador"], accion_segundo)
      end
    end
  end

  # =========================
  # Acciones de turno
  # =========================

  defp resolver_accion(estado, numero_jugador, :pasar) do
    jugador = obtener_nombre_jugador(estado, numero_jugador)
    agregar_resumen(estado, "[#{jugador}] no realizó acción este turno.")
  end

  defp resolver_accion(estado, numero_jugador, :rendirse) do
    jugador = obtener_nombre_jugador(estado, numero_jugador)
    ganador = obtener_nombre_jugador(estado, jugador_contrario(numero_jugador))

    estado
    |> agregar_resumen("[#{jugador}] se rindió. Ganador: #{ganador}.")
    |> Map.put(:terminado, true)
    |> Map.put(:ganador, ganador)
  end

  defp resolver_accion(estado, numero_jugador, {:cambiar, id_pokemon}) do
    jugador = obtener_nombre_jugador(estado, numero_jugador)

    case obtener_pokemon_por_id(estado, numero_jugador, id_pokemon) do
      nil ->
        agregar_resumen(estado, "[#{jugador}] intentó cambiar a un Pokémon no válido.")

      pokemon ->
        estado_actualizado =
          if numero_jugador == 1 do
            Map.put(estado, :activo_1, pokemon["id"])
          else
            Map.put(estado, :activo_2, pokemon["id"])
          end

        agregar_resumen(
          estado_actualizado,
          "[#{jugador}] cambió a #{pokemon["nombre"]} ##{pokemon["id"]}."
        )
    end
  end

  defp resolver_accion(estado, numero_jugador, {:ataque, movimiento}) do
    especies = Persistencia.cargar_pokemon_base()

    atacante =
      if numero_jugador == 1 do
        pokemon_activo(estado.equipo_1, estado.activo_1)
      else
        pokemon_activo(estado.equipo_2, estado.activo_2)
      end

    defensor =
      if numero_jugador == 1 do
        pokemon_activo(estado.equipo_2, estado.activo_2)
      else
        pokemon_activo(estado.equipo_1, estado.activo_1)
      end

    if is_nil(atacante) or is_nil(defensor) do
      estado
    else
      dano =
        MotorCombate.calcular_dano(
          atacante,
          defensor,
          movimiento,
          especies
        )

      defensor_actualizado =
        MotorCombate.aplicar_dano(defensor, dano)

      estado_actualizado =
        actualizar_defensor(estado, numero_jugador, defensor_actualizado)

      jugador_atacante = obtener_nombre_jugador(estado, numero_jugador)
      jugador_defensor = obtener_nombre_jugador(estado, jugador_contrario(numero_jugador))

      mensaje_ataque =
        "[#{jugador_atacante}] #{atacante["nombre"]} ##{atacante["id"]} usó #{movimiento["nombre"]} " <>
          "e hizo #{dano} de daño a [#{jugador_defensor}] #{defensor["nombre"]} ##{defensor["id"]}. " <>
          "Salud restante: #{defensor_actualizado["salud_actual"]}/100."

      estado_con_mensaje =
        agregar_resumen(estado_actualizado, mensaje_ataque)

      if MotorCombate.debilitado?(defensor_actualizado) do
        estado_con_debilitado =
          agregar_resumen(
            estado_con_mensaje,
            "[#{jugador_defensor}] #{defensor["nombre"]} ##{defensor["id"]} quedó debilitado."
          )

        cond do
          numero_jugador == 1 and todos_debilitados?(estado_con_debilitado.equipo_2) ->
            estado_con_debilitado
            |> Map.put(:terminado, true)
            |> Map.put(:ganador, estado.jugador_1)

          numero_jugador == 2 and todos_debilitados?(estado_con_debilitado.equipo_1) ->
            estado_con_debilitado
            |> Map.put(:terminado, true)
            |> Map.put(:ganador, estado.jugador_2)

          true ->
            estado_con_debilitado
        end
      else
        estado_con_mensaje
      end
    end
  end

  defp actualizar_defensor(estado, numero_atacante, defensor_actualizado) do
    if numero_atacante == 1 do
      equipo_2_actualizado =
        actualizar_pokemon_en_equipo(estado.equipo_2, defensor_actualizado)

      Map.put(estado, :equipo_2, equipo_2_actualizado)
    else
      equipo_1_actualizado =
        actualizar_pokemon_en_equipo(estado.equipo_1, defensor_actualizado)

      Map.put(estado, :equipo_1, equipo_1_actualizado)
    end
  end

  # =========================
  # Entrada por consola
  # =========================

  defp pedir_accion_valida(estado, numero_jugador) do
    jugador = obtener_nombre_jugador(estado, numero_jugador)

    case leer_linea_con_timeout("[#{jugador}] Acción > ", estado.tiempo_turno) do
      :timeout ->
        IO.puts("Tiempo agotado. La acción será pasar.")
        :pasar

      nil ->
        IO.puts("No se recibió entrada. La acción será rendirse.")
        :rendirse

      entrada ->
        case interpretar_accion(entrada, estado, numero_jugador) do
          {:ok, accion} ->
            accion

          {:error, mensaje} ->
            IO.puts("Acción inválida: #{mensaje}")
            pedir_accion_valida(estado, numero_jugador)
        end
    end
  end

  defp interpretar_accion(entrada, estado, numero_jugador) do
    partes = String.split(String.trim(entrada), " ", trim: true)

    case partes do
      ["pasar"] ->
        {:ok, :pasar}

      ["rendirse"] ->
        {:ok, :rendirse}

      ["ataque", nombre_movimiento] ->
        validar_ataque(estado, numero_jugador, nombre_movimiento)

      ["cambiar", id_texto] ->
        validar_cambio(estado, numero_jugador, id_texto)

      _ ->
        {:error, "usa ataque <movimiento>, cambiar <id_pokemon>, pasar o rendirse"}
    end
  end

  defp validar_ataque(estado, numero_jugador, nombre_movimiento) do
    pokemon =
      if numero_jugador == 1 do
        pokemon_activo(estado.equipo_1, estado.activo_1)
      else
        pokemon_activo(estado.equipo_2, estado.activo_2)
      end

    movimiento =
      pokemon["movimientos"]
      |> Enum.find(fn mov -> mov["nombre"] == nombre_movimiento end)

    case movimiento do
      nil -> {:error, "ese movimiento no pertenece al Pokémon activo"}
      movimiento -> {:ok, {:ataque, movimiento}}
    end
  end

  defp validar_cambio(estado, numero_jugador, id_texto) do
    case Integer.parse(id_texto) do
      {id_pokemon, ""} ->
        pokemon = obtener_pokemon_por_id(estado, numero_jugador, id_pokemon)
        activo = obtener_activo_id(estado, numero_jugador)

        cond do
          is_nil(pokemon) ->
            {:error, "el Pokémon no está en tu equipo"}

          to_string(id_pokemon) == to_string(activo) ->
            {:error, "ese Pokémon ya está activo"}

          MotorCombate.debilitado?(pokemon) ->
            {:error, "no puedes cambiar a un Pokémon debilitado"}

          true ->
            {:ok, {:cambiar, id_pokemon}}
        end

      _ ->
        {:error, "el id debe ser numérico"}
    end
  end

  defp leer_linea_con_timeout(prompt, tiempo_segundos) do
  task =
    Task.async(fn ->
      IO.gets(prompt)
    end)

  case Task.yield(task, tiempo_segundos * 1000) || Task.shutdown(task, :brutal_kill) do
    {:ok, nil} ->
      nil

    {:ok, linea} when is_binary(linea) ->
      String.trim(linea)

    {:ok, {:error, _razon}} ->
      :timeout

    {:ok, _otro} ->
      :timeout

    nil ->
      :timeout
  end
end

  # =========================
  # Visualización de turno
  # =========================

  defp mostrar_estado_turno(estado, numero_jugador) do
    jugador = obtener_nombre_jugador(estado, numero_jugador)
    rival = obtener_nombre_jugador(estado, jugador_contrario(numero_jugador))

    pokemon =
      if numero_jugador == 1 do
        pokemon_activo(estado.equipo_1, estado.activo_1)
      else
        pokemon_activo(estado.equipo_2, estado.activo_2)
      end

    pokemon_rival =
      if numero_jugador == 1 do
        pokemon_activo(estado.equipo_2, estado.activo_2)
      else
        pokemon_activo(estado.equipo_1, estado.activo_1)
      end

    equipo =
      if numero_jugador == 1 do
        estado.equipo_1
      else
        estado.equipo_2
      end

    equipo_rival =
      if numero_jugador == 1 do
        estado.equipo_2
      else
        estado.equipo_1
      end

    IO.puts("\n--- Turno de #{jugador} ---")
    IO.puts("Rival: #{rival}")
    IO.puts("Pokémon rival: #{formato_pokemon_estado(pokemon_rival)}")
    IO.puts("Equipo rival: #{formato_equipo(equipo_rival, pokemon_rival["id"])}")
    IO.puts("Tu Pokémon: #{formato_pokemon_estado(pokemon)}")
    IO.puts("Tu equipo: #{formato_equipo(equipo, pokemon["id"])}")

    IO.puts("Movimientos:")

    pokemon["movimientos"]
    |> Enum.with_index(1)
    |> Enum.each(fn {mov, index} ->
      IO.puts(" #{index}. #{mov["nombre"]} (#{mov["tipo"]}, poder #{mov["poder_base"]})")
    end)

    IO.puts("Acciones: ataque <movimiento> | cambiar <id_pokemon> | pasar | rendirse")
  end

  defp formato_pokemon_estado(nil), do: "Sin Pokémon disponible"

  defp formato_pokemon_estado(pokemon) do
    tipos = pokemon |> Map.get("tipos", []) |> Enum.join("/")

    "[##{pokemon["id"]}] #{pokemon["nombre"]} (#{tipos}) | Salud: #{pokemon["salud_actual"]}/100 | Vel: #{pokemon["velocidad"]}"
  end

  defp formato_equipo(equipo, activo_id) do
    equipo
    |> Enum.map(fn pokemon ->
      estado =
        cond do
          to_string(pokemon["id"]) == to_string(activo_id) -> "activo"
          MotorCombate.debilitado?(pokemon) -> "debilitado"
          true -> "vivo"
        end

      "[##{pokemon["id"]}] #{pokemon["nombre"]} (#{estado})"
    end)
    |> Enum.join(" | ")
  end

  # =========================
  # Preparar Pokémon activos
  # =========================

  defp preparar_activos(estado) do
    estado
    |> preparar_activo_jugador(1)
    |> preparar_activo_jugador(2)
  end

  defp preparar_activo_jugador(estado, numero_jugador) do
    equipo =
      if numero_jugador == 1 do
        estado.equipo_1
      else
        estado.equipo_2
      end

    activo_id = obtener_activo_id(estado, numero_jugador)
    activo = pokemon_activo(equipo, activo_id)

    cond do
      todos_debilitados?(equipo) ->
        ganador = obtener_nombre_jugador(estado, jugador_contrario(numero_jugador))
        %{estado | terminado: true, ganador: ganador}

      is_nil(activo) or MotorCombate.debilitado?(activo) ->
        seleccionar_reemplazo(estado, numero_jugador)

      true ->
        estado
    end
  end

  defp seleccionar_reemplazo(estado, numero_jugador) do
    jugador = obtener_nombre_jugador(estado, numero_jugador)

    equipo =
      if numero_jugador == 1 do
        estado.equipo_1
      else
        estado.equipo_2
      end

    disponibles =
      Enum.reject(equipo, fn pokemon ->
        MotorCombate.debilitado?(pokemon)
      end)

    IO.puts("\n[#{jugador}] Debes elegir tu siguiente Pokémon.")
    IO.puts("Disponibles:")

    disponibles
    |> Enum.each(fn pokemon ->
      IO.puts("[##{pokemon["id"]}] #{pokemon["nombre"]} | Salud: #{pokemon["salud_actual"]}/100")
    end)

    elegido =
      case leer_linea_con_timeout("[#{jugador}] ID del Pokémon > ", estado.tiempo_turno) do
        :timeout ->
          hd(disponibles)

        nil ->
          hd(disponibles)

        texto ->
          case Integer.parse(texto) do
            {id, ""} ->
              Enum.find(disponibles, fn pokemon ->
                to_string(pokemon["id"]) == to_string(id)
              end) || hd(disponibles)

            _ ->
              hd(disponibles)
          end
      end

    estado_actualizado =
      if numero_jugador == 1 do
        Map.put(estado, :activo_1, elegido["id"])
      else
        Map.put(estado, :activo_2, elegido["id"])
      end

    agregar_resumen(
      estado_actualizado,
      "[#{jugador}] envió a #{elegido["nombre"]} ##{elegido["id"]} al combate."
    )
  end

  # =========================
  # Utilidades de equipos
  # =========================

  defp cargar_equipo_completo(usuario) do
    with {:ok, equipo} <- GestorEquipos.obtener_equipo_activo(usuario) do
      entrenador = GestorEntrenadores.obtener_entrenador(usuario)
      inventario = Map.get(entrenador, "inventario", [])
      ids = Map.get(equipo, "pokemon_ids", [])

      pokemon_equipo =
        ids
        |> Enum.map(fn id ->
          Enum.find(inventario, fn pokemon ->
            to_string(pokemon["id"]) == to_string(id)
          end)
        end)

      if Enum.any?(pokemon_equipo, &is_nil/1) do
        {:error, :equipo_con_pokemon_faltante}
      else
        equipo_preparado =
          Enum.map(pokemon_equipo, fn pokemon ->
            pokemon
            |> Map.put("salud_actual", 100)
            |> Map.put("jugador", usuario)
          end)

        {:ok, equipo_preparado}
      end
    end
  end

  defp pokemon_activo(equipo, activo_id) do
    pokemon =
      Enum.find(equipo, fn pokemon ->
        to_string(pokemon["id"]) == to_string(activo_id)
      end)

    cond do
      is_nil(pokemon) ->
        Enum.find(equipo, fn pokemon -> not MotorCombate.debilitado?(pokemon) end)

      MotorCombate.debilitado?(pokemon) ->
        Enum.find(equipo, fn pokemon -> not MotorCombate.debilitado?(pokemon) end)

      true ->
        pokemon
    end
  end

  defp obtener_pokemon_por_id(estado, numero_jugador, id_pokemon) do
    equipo =
      if numero_jugador == 1 do
        estado.equipo_1
      else
        estado.equipo_2
      end

    Enum.find(equipo, fn pokemon ->
      to_string(pokemon["id"]) == to_string(id_pokemon)
    end)
  end

  defp obtener_id_primer_vivo(equipo) do
    equipo
    |> Enum.find(fn pokemon -> not MotorCombate.debilitado?(pokemon) end)
    |> Map.get("id")
  end

  defp obtener_activo_id(estado, 1), do: estado.activo_1
  defp obtener_activo_id(estado, 2), do: estado.activo_2

  defp todos_debilitados?(equipo) do
    Enum.all?(equipo, &MotorCombate.debilitado?/1)
  end

  defp actualizar_pokemon_en_equipo(equipo, pokemon_actualizado) do
    Enum.map(equipo, fn pokemon ->
      if to_string(pokemon["id"]) == to_string(pokemon_actualizado["id"]) do
        pokemon_actualizado
      else
        pokemon
      end
    end)
  end

  # =========================
  # Ganador, recompensas y log
  # =========================

  defp decidir_ganador_por_salud(estado) do
    salud_1 = sumar_salud(estado.equipo_1)
    salud_2 = sumar_salud(estado.equipo_2)

    if salud_1 >= salud_2 do
      estado.jugador_1
    else
      estado.jugador_2
    end
  end

  defp sumar_salud(equipo) do
    Enum.sum_by(equipo, fn pokemon ->
      Map.get(pokemon, "salud_actual", 0)
    end)
  end

  defp actualizar_recompensas(%{ganador: nil}), do: :ok

  defp actualizar_recompensas(%{ganador: ganador, jugador_1: j1, jugador_2: j2}) do
    perdedor = if ganador == j1, do: j2, else: j1

    GestorEntrenadores.registrar_victoria(ganador)
    GestorEntrenadores.sumar_monedas(ganador, 100)
    GestorEntrenadores.sumar_monedas(perdedor, 30)

    :ok
  end

  defp registrar_log(estado) do
    resumen =
      estado.resumen
      |> Enum.join(" | ")

    Persistencia.registrar_batalla(
      [estado.jugador_1, estado.jugador_2],
      estado.ganador,
      Node.self() |> Atom.to_string(),
      "#{estado.turno} turnos",
      resumen
    )
  end

  # =========================
  # Utilidades generales
  # =========================

  defp obtener_nombre_jugador(estado, 1), do: estado.jugador_1
  defp obtener_nombre_jugador(estado, 2), do: estado.jugador_2

  defp jugador_contrario(1), do: 2
  defp jugador_contrario(2), do: 1

  defp agregar_resumen(estado, mensaje) do
    IO.puts(mensaje)
    Map.put(estado, :resumen, estado.resumen ++ [mensaje])
  end

  defp generar_estado_batalla(estado) do
    """
    === Batalla #{estado.id_sala} ===
    Jugador 1: #{estado.jugador_1}
    Jugador 2: #{estado.jugador_2}
    Turno actual: #{estado.turno}
    Terminada: #{estado.terminado}
    Ganador: #{inspect(estado.ganador)}
    """
  end
end
