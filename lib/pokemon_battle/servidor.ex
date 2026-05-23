defmodule PokemonBattle.Servidor do
  @moduledoc """
  Módulo principal de consola.

  Desde aquí el usuario puede ejecutar comandos como:
  - iniciar usuario clave
  - perfil
  - tienda
  - comprar_sobre basico
  - abrir_sobre ultimo
  - inventario
  - clasificacion
  - salir
  - cerrar
  """

  alias PokemonBattle.GestorEntrenadores
  alias PokemonBattle.SistemaSobres
  alias PokemonBattle.GestorEquipos
  alias PokemonBattle.GestorSalas
  alias PokemonBattle.Batalla
  alias PokemonBattle.GestorIntercambios
  alias PokemonBattle.Cluster

  def main do
    IO.puts("====================================")
    IO.puts("   Bienvenido a Pokémon Battle")
    IO.puts("====================================")
    IO.puts("Escribe ayuda para ver los comandos disponibles.")
    loop(nil)
  end

  defp loop(usuario_actual) do
  mostrar_prompt(usuario_actual)

  entrada =
    IO.gets("")
    |> validar_entrada()

  case entrada do
    :cerrar ->
      IO.puts("Aplicación finalizada.")

    comando ->
      case ejecutar_comando(comando, usuario_actual) do
        :cerrar ->
          IO.puts("Aplicación finalizada.")

        nuevo_usuario ->
          loop(nuevo_usuario)
      end
  end
end

  defp validar_entrada(nil), do: :cerrar

  defp validar_entrada(entrada) do
    entrada
    |> String.trim()
  end

  defp mostrar_prompt(nil), do: IO.write("> ")
  defp mostrar_prompt(usuario), do: IO.write("[#{usuario}] > ")

  defp ejecutar_comando("", usuario_actual), do: usuario_actual

  defp ejecutar_comando("ayuda", usuario_actual) do
  IO.puts("""
  ========== Comandos disponibles ==========

  iniciar <usuario> <clave>
    Inicia sesión. Si el usuario no existe, lo registra automáticamente.

  perfil
    Muestra monedas, sobres pendientes, cantidad de Pokémon y victorias.

  tienda
    Muestra los sobres disponibles.

  comprar_sobre <basico|avanzado>
    Compra un sobre usando monedas.

  abrir_sobre ultimo
    Abre el último sobre pendiente.

  abrir_sobre <id_sobre>
    Abre un sobre específico por id.

  inventario
    Lista todos tus Pokémon con atributos, dueño original y movimientos.

  clasificacion
    Muestra la clasificación global.

  salir
    Cierra la sesión actual.

  cerrar
    Cierra completamente la aplicación.

  ---------- Equipos ----------

  crear_equipo <nombre> <id1,id2,id3>
    Crea un equipo con entre 1 y 3 Pokémon de tu inventario.

  listar_equipos
    Muestra los equipos guardados.

  usar_equipo <nombre>
    Selecciona un equipo para la siguiente batalla.

  agregar_pokemon_equipo <nombre_equipo> <id_pokemon>
    Agrega un Pokémon del inventario a un equipo.

  quitar_pokemon_equipo <nombre_equipo> <id_pokemon>
    Quita un Pokémon de un equipo.

  ---------- Salas de batalla ----------

  crear_sala
    Crea una sala de batalla con tiempo por defecto de 20 segundos.

  crear_sala tiempo_turno=20
    Crea una sala con tiempo de turno personalizado.

  listar_salas
    Lista las salas disponibles.

  unirse_sala <id_sala>
    Permite unirse a una sala existente.

  iniciar_batalla <id_sala>
    Inicia una batalla interactiva por turnos entre los dos jugadores.

  Durante la batalla puedes usar:
    ataque <movimiento>
    cambiar <id_pokemon>
    pasar
    rendirse

  ---------- Intercambios ----------

  crear_sala_intercambio
    Crea una sala de intercambio y genera un código.

  unirse_sala_intercambio <codigo>
    Permite unirse a una sala de intercambio existente.

  ofrecer_pokemon <id_pokemon>
    Ofrece un Pokémon en tu sala de intercambio activa.

  ofrecer_pokemon <codigo> <id_pokemon>
    Ofrece un Pokémon usando el código de la sala.

  confirmar_intercambio
    Confirma el intercambio en tu sala activa.

  confirmar_intercambio <codigo>
    Confirma el intercambio usando el código de la sala.

  cancelar_intercambio
    Cancela tu sala de intercambio activa.

  cancelar_intercambio <codigo>
    Cancela una sala de intercambio usando el código.

  estado_intercambio
    Muestra el estado de tu sala activa.

  estado_intercambio <codigo>
    Muestra el estado de una sala por código.

  ---------- Nodos ----------

  nodo
    Muestra el nodo actual donde corre la aplicación.

  nodos
    Muestra los nodos conectados.

  conectar_nodo <nombre_nodo>
    Conecta la aplicación con otro nodo Elixir.

  ==========================================
  """)

  usuario_actual
end

  defp ejecutar_comando("cerrar", _usuario_actual), do: :cerrar

  defp ejecutar_comando("salir", nil) do
    IO.puts("No hay ninguna sesión activa.")
    nil
  end

  defp ejecutar_comando("salir", usuario_actual) do
    GestorIntercambios.cancelar_salas_usuario(usuario_actual)
    IO.puts("Sesión cerrada.")
    nil
  end

  defp ejecutar_comando(comando, usuario_actual) do
    partes = String.split(comando, " ", trim: true)
    procesar_comando(partes, usuario_actual)
  end

  defp procesar_comando(["iniciar", usuario, clave], _usuario_actual) do
    case GestorEntrenadores.iniciar_sesion(usuario, clave) do
      {:ok, :registrado, usuario, _entrenador} ->
        IO.puts("Cuenta creada correctamente.")
        IO.puts("Recibiste 1 sobre básico gratis.")
        usuario

      {:ok, :sesion_iniciada, usuario, _entrenador} ->
        IO.puts("Sesión iniciada correctamente.")
        usuario

      {:error, :clave_incorrecta} ->
        IO.puts("La clave ingresada es incorrecta.")
        nil
    end
  end

  defp procesar_comando(["iniciar" | _], usuario_actual) do
    IO.puts("Uso correcto: iniciar <usuario> <clave>")
    usuario_actual
  end

  defp procesar_comando(["perfil"], nil) do
    IO.puts("Primero debes iniciar sesión.")
    nil
  end

  defp procesar_comando(["perfil"], usuario_actual) do
    case GestorEntrenadores.perfil(usuario_actual) do
      {:ok, mensaje} -> IO.puts(mensaje)
      {:error, razon} -> IO.puts("Error: #{inspect(razon)}")
    end

    usuario_actual
  end

  defp procesar_comando(["inventario"], nil) do
    IO.puts("Primero debes iniciar sesión.")
    nil
  end

  defp procesar_comando(["inventario"], usuario_actual) do
    case GestorEntrenadores.inventario(usuario_actual) do
      {:ok, mensaje} -> IO.puts(mensaje)
      {:error, razon} -> IO.puts("Error: #{inspect(razon)}")
    end

    usuario_actual
  end

  defp procesar_comando(["tienda"], usuario_actual) do
    {:ok, mensaje} = SistemaSobres.listar_tienda()
    IO.puts(mensaje)

    usuario_actual
  end

  defp procesar_comando(["comprar_sobre", _tipo], nil) do
    IO.puts("Primero debes iniciar sesión.")
    nil
  end

  defp procesar_comando(["comprar_sobre", tipo], usuario_actual) do
    case SistemaSobres.comprar_sobre(usuario_actual, tipo) do
      {:ok, sobre} ->
        IO.puts("Sobre comprado correctamente.")
        IO.puts("ID del sobre: #{sobre["id"]}")
        IO.puts("Tipo: #{sobre["tipo"]}")

      {:error, razon} ->
        IO.puts("Error al comprar sobre: #{inspect(razon)}")
    end

    usuario_actual
  end

  defp procesar_comando(["abrir_sobre", _id_sobre], nil) do
    IO.puts("Primero debes iniciar sesión.")
    nil
  end

  defp procesar_comando(["abrir_sobre", id_sobre], usuario_actual) do
    case SistemaSobres.abrir_sobre(usuario_actual, id_sobre) do
      {:ok, nuevos_pokemon} ->
        IO.puts("¡Sobre abierto! Obtuviste:")
        mostrar_pokemon_obtenidos(nuevos_pokemon)

      {:error, razon} ->
        IO.puts("Error al abrir sobre: #{inspect(razon)}")
    end

    usuario_actual
  end

  defp procesar_comando(["abrir_sobre"], nil) do
    IO.puts("Primero debes iniciar sesión.")
    nil
  end

  defp procesar_comando(["abrir_sobre"], usuario_actual) do
    case SistemaSobres.abrir_sobre(usuario_actual, "ultimo") do
      {:ok, nuevos_pokemon} ->
        IO.puts("¡Sobre abierto! Obtuviste:")
        mostrar_pokemon_obtenidos(nuevos_pokemon)

      {:error, razon} ->
        IO.puts("Error al abrir sobre: #{inspect(razon)}")
    end

    usuario_actual
  end

  defp procesar_comando(["clasificacion"], usuario_actual) do
    GestorEntrenadores.clasificacion()
    |> IO.puts()

    usuario_actual
  end
    defp procesar_comando(["crear_equipo", _nombre, _ids], nil) do
    IO.puts("Primero debes iniciar sesión.")
    nil
  end

  defp procesar_comando(["crear_equipo", nombre, ids], usuario_actual) do
    case GestorEquipos.crear_equipo(usuario_actual, nombre, ids) do
      {:ok, equipo} ->
        IO.puts("Equipo creado correctamente.")
        IO.puts("Nombre: #{equipo["nombre"]}")
        IO.puts("Pokémon: #{Enum.join(equipo["pokemon_ids"], ", ")}")

      {:error, razon} ->
        IO.puts("Error al crear equipo: #{inspect(razon)}")
    end

    usuario_actual
  end

  defp procesar_comando(["crear_equipo" | _], usuario_actual) do
    IO.puts("Uso correcto: crear_equipo <nombre> <id1,id2,id3>")
    usuario_actual
  end

  defp procesar_comando(["listar_equipos"], nil) do
    IO.puts("Primero debes iniciar sesión.")
    nil
  end

  defp procesar_comando(["listar_equipos"], usuario_actual) do
    case GestorEquipos.listar_equipos(usuario_actual) do
      {:ok, mensaje} -> IO.puts(mensaje)
      {:error, razon} -> IO.puts("Error: #{inspect(razon)}")
    end

    usuario_actual
  end

  defp procesar_comando(["usar_equipo", _nombre], nil) do
    IO.puts("Primero debes iniciar sesión.")
    nil
  end

  defp procesar_comando(["usar_equipo", nombre], usuario_actual) do
    case GestorEquipos.usar_equipo(usuario_actual, nombre) do
      {:ok, equipo} ->
        IO.puts("Equipo seleccionado correctamente.")
        IO.puts("Equipo activo: #{equipo["nombre"]}")

      {:error, razon} ->
        IO.puts("Error al usar equipo: #{inspect(razon)}")
    end

    usuario_actual
  end

  defp procesar_comando(["usar_equipo" | _], usuario_actual) do
    IO.puts("Uso correcto: usar_equipo <nombre>")
    usuario_actual
  end

  defp procesar_comando(["agregar_pokemon_equipo", _nombre, _id], nil) do
    IO.puts("Primero debes iniciar sesión.")
    nil
  end

  defp procesar_comando(["agregar_pokemon_equipo", nombre, id], usuario_actual) do
    case GestorEquipos.agregar_pokemon_equipo(usuario_actual, nombre, id) do
      {:ok, equipo} ->
        IO.puts("Pokémon agregado correctamente.")
        IO.puts("Equipo: #{equipo["nombre"]}")
        IO.puts("Pokémon: #{Enum.join(equipo["pokemon_ids"], ", ")}")

      {:error, razon} ->
        IO.puts("Error al agregar Pokémon: #{inspect(razon)}")
    end

    usuario_actual
  end

  defp procesar_comando(["agregar_pokemon_equipo" | _], usuario_actual) do
    IO.puts("Uso correcto: agregar_pokemon_equipo <nombre_equipo> <id_pokemon>")
    usuario_actual
  end

  defp procesar_comando(["quitar_pokemon_equipo", _nombre, _id], nil) do
    IO.puts("Primero debes iniciar sesión.")
    nil
  end

  defp procesar_comando(["quitar_pokemon_equipo", nombre, id], usuario_actual) do
    case GestorEquipos.quitar_pokemon_equipo(usuario_actual, nombre, id) do
      {:ok, equipo} ->
        IO.puts("Pokémon quitado correctamente.")
        IO.puts("Equipo: #{equipo["nombre"]}")
        IO.puts("Pokémon: #{Enum.join(equipo["pokemon_ids"], ", ")}")

      {:error, razon} ->
        IO.puts("Error al quitar Pokémon: #{inspect(razon)}")
    end

    usuario_actual
  end

  defp procesar_comando(["quitar_pokemon_equipo" | _], usuario_actual) do
    IO.puts("Uso correcto: quitar_pokemon_equipo <nombre_equipo> <id_pokemon>")
    usuario_actual
  end
    defp procesar_comando(["crear_sala"], nil) do
    IO.puts("Primero debes iniciar sesión.")
    nil
  end

  defp procesar_comando(["crear_sala"], usuario_actual) do
    case GestorSalas.crear_sala(usuario_actual, 20) do
      {:ok, sala} ->
        IO.puts("Sala creada correctamente.")
        IO.puts("ID sala: #{sala["id"]}")
        IO.puts("Tiempo por turno: #{sala["tiempo_turno"]} segundos")

      {:error, razon} ->
        IO.puts("Error al crear sala: #{inspect(razon)}")
    end

    usuario_actual
  end

  defp procesar_comando(["crear_sala", "tiempo_turno=" <> _tiempo_texto], nil) do
    IO.puts("Primero debes iniciar sesión.")
    nil
  end

  defp procesar_comando(["crear_sala", "tiempo_turno=" <> tiempo_texto], usuario_actual) do
    case Integer.parse(tiempo_texto) do
      {tiempo, ""} when tiempo > 0 ->
        case GestorSalas.crear_sala(usuario_actual, tiempo) do
          {:ok, sala} ->
            IO.puts("Sala creada correctamente.")
            IO.puts("ID sala: #{sala["id"]}")
            IO.puts("Tiempo por turno: #{sala["tiempo_turno"]} segundos")

          {:error, razon} ->
            IO.puts("Error al crear sala: #{inspect(razon)}")
        end

      _ ->
        IO.puts("Uso correcto: crear_sala tiempo_turno=20")
    end

    usuario_actual
  end

  defp procesar_comando(["listar_salas"], usuario_actual) do
    case GestorSalas.listar_salas() do
      {:ok, []} ->
        IO.puts("No hay salas creadas.")

      {:ok, salas} ->
        IO.puts("=== Salas disponibles ===")

        salas
        |> Enum.each(fn sala ->
          jugadores = Enum.join(sala["jugadores"], ", ")

          IO.puts("""
          Sala: #{sala["id"]}
          Estado: #{sala["estado"]}
          Jugadores: #{jugadores}
          Tiempo por turno: #{sala["tiempo_turno"]} segundos
          """)
        end)

      {:error, razon} ->
        IO.puts("Error al listar salas: #{inspect(razon)}")
    end

    usuario_actual
  end

  defp procesar_comando(["unirse_sala", _id_sala], nil) do
    IO.puts("Primero debes iniciar sesión.")
    nil
  end

  defp procesar_comando(["unirse_sala", id_sala], usuario_actual) do
    case GestorSalas.unirse_sala(id_sala, usuario_actual) do
      {:ok, sala} ->
        IO.puts("Te uniste correctamente a la sala #{sala["id"]}.")
        IO.puts("Jugadores: #{Enum.join(sala["jugadores"], ", ")}")
        IO.puts("La sala está lista para iniciar batalla.")

      {:error, razon} ->
        IO.puts("Error al unirse a la sala: #{inspect(razon)}")
    end

    usuario_actual
  end

  defp procesar_comando(["unirse_sala" | _], usuario_actual) do
    IO.puts("Uso correcto: unirse_sala <id_sala>")
    usuario_actual
  end
    defp procesar_comando(["iniciar_batalla", _id_sala], nil) do
    IO.puts("Primero debes iniciar sesión.")
    nil
  end

  defp procesar_comando(["iniciar_batalla", id_sala], usuario_actual) do
    case GestorSalas.obtener_sala(id_sala) do
      {:error, razon} ->
        IO.puts("Error al iniciar batalla: #{inspect(razon)}")

      {:ok, sala} ->
        jugadores = sala["jugadores"]

        cond do
          length(jugadores) < 2 ->
            IO.puts("La batalla no puede iniciar. La sala necesita 2 jugadores.")

          usuario_actual not in jugadores ->
            IO.puts("No puedes iniciar una batalla en una sala donde no estás.")

          true ->
            [jugador_1, jugador_2] = jugadores
            tiempo_turno = sala["tiempo_turno"]

            GestorSalas.marcar_en_batalla(id_sala)
            case Cluster.iniciar_batalla(id_sala, jugador_1, jugador_2, tiempo_turno) do
              {:ok, pid, nodo} ->
                IO.puts("Batalla iniciada correctamente en el proceso #{inspect(pid)}.")
                IO.puts("Nodo asignado: #{nodo}")
                IO.puts("Iniciando batalla interactiva por turnos...")

                case Batalla.resolver_batalla(pid) do
                  {:ok, ganador, resumen} ->
                    IO.puts("====================================")
                    IO.puts("Resultado de la batalla")
                    IO.puts("Ganador: #{ganador}")
                    IO.puts("====================================")

                    resumen
                    |> Enum.each(fn evento ->
                      IO.puts(evento)
                    end)
                    GestorSalas.finalizar_sala(id_sala)

                  {:error, razon} ->
                    IO.puts("Error al resolver batalla: #{inspect(razon)}")
                    GestorSalas.finalizar_sala(id_sala)
                end

              {:error, razon} ->
                IO.puts("Error al crear el proceso de batalla: #{inspect(razon)}")
            end
        end
    end

    usuario_actual
  end

  defp procesar_comando(["iniciar_batalla" | _], usuario_actual) do
    IO.puts("Uso correcto: iniciar_batalla <id_sala>")
    usuario_actual
  end
    defp procesar_comando(["crear_sala_intercambio"], nil) do
    IO.puts("Primero debes iniciar sesión.")
    nil
  end

  defp procesar_comando(["crear_sala_intercambio"], usuario_actual) do
    case GestorIntercambios.crear_sala(usuario_actual) do
      {:ok, codigo} ->
        IO.puts("[Sala #{codigo} creada] Comparte este código con el otro entrenador.")

      {:error, razon} ->
        IO.puts("Error al crear sala de intercambio: #{inspect(razon)}")
    end

    usuario_actual
  end

  defp procesar_comando(["unirse_sala_intercambio", _codigo], nil) do
    IO.puts("Primero debes iniciar sesión.")
    nil
  end

  defp procesar_comando(["unirse_sala_intercambio", codigo], usuario_actual) do
    case GestorIntercambios.unirse_sala(codigo, usuario_actual) do
      {:ok, estado} ->
        IO.puts("[Sala #{codigo}] #{usuario_actual} se ha unido.")
        IO.puts("Participantes: #{Enum.join(estado.participantes, ", ")}")
        IO.puts("Ya pueden ofrecer Pokémon.")

      {:error, razon} ->
        IO.puts("Error al unirse a la sala de intercambio: #{inspect(razon)}")
    end

    usuario_actual
  end

  defp procesar_comando(["unirse_sala_intercambio" | _], usuario_actual) do
    IO.puts("Uso correcto: unirse_sala_intercambio <codigo>")
    usuario_actual
  end

  defp procesar_comando(["ofrecer_pokemon", _codigo, _id_pokemon], nil) do
    IO.puts("Primero debes iniciar sesión.")
    nil
  end

  defp procesar_comando(["ofrecer_pokemon", codigo, id_pokemon], usuario_actual) do
    case GestorIntercambios.ofrecer_pokemon(codigo, usuario_actual, id_pokemon) do
      {:ok, estado} ->
        pokemon = estado.ofertas[usuario_actual]

        IO.puts("[Sala #{codigo}] #{usuario_actual} ofrece:")
        IO.puts("[##{pokemon["id"]}] #{pokemon["nombre"]} (#{Enum.join(pokemon["tipos"], "/")}) [#{pokemon["rareza"]}]")
        IO.puts("Dueño original: #{pokemon["dueño_original"]}")

        mostrar_estado_intercambio(codigo, estado)

      {:error, razon} ->
        IO.puts("Error al ofrecer Pokémon: #{inspect(razon)}")
    end

    usuario_actual
  end

  defp procesar_comando(["ofrecer_pokemon" | _], usuario_actual) do
    IO.puts("Uso correcto: ofrecer_pokemon <codigo> <id_pokemon>")
    usuario_actual
  end

  defp procesar_comando(["confirmar_intercambio", _codigo], nil) do
    IO.puts("Primero debes iniciar sesión.")
    nil
  end

  defp procesar_comando(["confirmar_intercambio", codigo], usuario_actual) do
    case GestorIntercambios.confirmar_intercambio(codigo, usuario_actual) do
      {:ok, estado} ->
        IO.puts("[Sala #{codigo}] Confirmación registrada para #{usuario_actual}.")
        IO.puts("Falta la confirmación del otro entrenador.")
        mostrar_estado_intercambio(codigo, estado)

      {:completado, resultado, _estado} ->
        IO.puts("[Intercambio completado]")

        IO.puts("""
        #{resultado.usuario_1} entregó:
          [##{resultado.pokemon_1["id"]}] #{resultado.pokemon_1["nombre"]}

        #{resultado.usuario_2} entregó:
          [##{resultado.pokemon_2["id"]}] #{resultado.pokemon_2["nombre"]}

        Ahora los Pokémon cambiaron de inventario y conservaron su id, rareza, movimientos y dueño original.
        """)

      {:error, razon} ->
        IO.puts("Error al confirmar intercambio: #{inspect(razon)}")
    end

    usuario_actual
  end

  defp procesar_comando(["confirmar_intercambio" | _], usuario_actual) do
    IO.puts("Uso correcto: confirmar_intercambio <codigo>")
    usuario_actual
  end

  defp procesar_comando(["cancelar_intercambio", _codigo], nil) do
    IO.puts("Primero debes iniciar sesión.")
    nil
  end

  defp procesar_comando(["cancelar_intercambio", codigo], usuario_actual) do
    case GestorIntercambios.cancelar_intercambio(codigo, usuario_actual) do
      {:cancelada, _estado} ->
        IO.puts("[Sala #{codigo}] Intercambio cancelado correctamente.")

      {:error, razon} ->
        IO.puts("Error al cancelar intercambio: #{inspect(razon)}")
    end

    usuario_actual
  end

  defp procesar_comando(["cancelar_intercambio" | _], usuario_actual) do
    IO.puts("Uso correcto: cancelar_intercambio <codigo>")
    usuario_actual
  end

  defp procesar_comando(["estado_intercambio", codigo], usuario_actual) do
    case GestorIntercambios.estado_sala(codigo) do
      {:ok, estado} ->
        mostrar_estado_intercambio(codigo, estado)

      {:error, razon} ->
        IO.puts("Error al consultar estado de intercambio: #{inspect(razon)}")
    end

    usuario_actual
  end

  defp procesar_comando(["estado_intercambio" | _], usuario_actual) do
    IO.puts("Uso correcto: estado_intercambio <codigo>")
    usuario_actual
  end

    defp procesar_comando(["nodo"], usuario_actual) do
    IO.puts("Nodo actual: #{Cluster.nodo_actual()}")
    usuario_actual
  end

  defp procesar_comando(["nodos"], usuario_actual) do
    nodos = Cluster.nodos_conectados()

    if nodos == [] do
      IO.puts("No hay nodos conectados.")
    else
      IO.puts("Nodos conectados:")

      nodos
      |> Enum.each(fn nodo ->
        IO.puts("- #{nodo}")
      end)
    end

    usuario_actual
  end

  defp procesar_comando(["conectar_nodo", nombre_nodo], usuario_actual) do
    case Cluster.conectar_nodo(nombre_nodo) do
      {:ok, nodo} ->
        IO.puts("Conectado correctamente al nodo #{nodo}.")

      {:error, razon} ->
        IO.puts("Error al conectar nodo: #{inspect(razon)}")
    end

    usuario_actual
  end

  defp procesar_comando(["conectar_nodo" | _], usuario_actual) do
    IO.puts("Uso correcto: conectar_nodo <nombre_nodo>")
    usuario_actual
  end

  defp procesar_comando(_otro, usuario_actual) do
    IO.puts("Comando no reconocido. Escribe ayuda para ver los comandos disponibles.")
    usuario_actual
  end
    defp mostrar_estado_intercambio(codigo, estado) do
    IO.puts("=== Estado sala #{codigo} ===")
    IO.puts("Estado: #{estado.estado}")
    IO.puts("Participantes: #{Enum.join(estado.participantes, ", ")}")

    IO.puts("Ofertas:")

    estado.participantes
    |> Enum.each(fn usuario ->
      case Map.get(estado.ofertas, usuario) do
        nil ->
          IO.puts("  #{usuario}: sin oferta")

        pokemon ->
          confirmado =
            if Map.get(estado.confirmaciones, usuario, false) do
              "✓ confirmado"
            else
              "pendiente"
            end

          IO.puts("  #{usuario}: [##{pokemon["id"]}] #{pokemon["nombre"]} - #{confirmado}")
      end
    end)
  end

  defp mostrar_pokemon_obtenidos(lista_pokemon) do
    lista_pokemon
    |> Enum.with_index(1)
    |> Enum.each(fn {pokemon, index} ->
      tipos = Enum.join(pokemon["tipos"], "/")

      movimientos =
        pokemon["movimientos"]
        |> Enum.map(fn mov ->
          "#{mov["nombre"]}(#{mov["poder_base"]})"
        end)
        |> Enum.join(", ")

      IO.puts("""
        #{index}. [##{pokemon["id"]}] #{pokemon["nombre"]} (#{tipos}) [#{pokemon["rareza"]}]
           Ataque: #{pokemon["ataque"]} | Defensa: #{pokemon["defensa"]} | Velocidad: #{pokemon["velocidad"]} | Salud máx: 100
           Dueño original: #{pokemon["dueño_original"]}
           Movimientos: #{movimientos}
      """)
    end)
  end
end
