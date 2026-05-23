defmodule PokemonBattle.GestorEntrenadores do
  @moduledoc """
  Módulo encargado de manejar los entrenadores del sistema.

  Aquí se controla:
  - Registro automático
  - Inicio de sesión
  - Perfil
  - Inventario
  - Monedas
  - Victorias
  - Clasificación global
  """

  alias PokemonBattle.Persistencia

  def iniciar_sesion(usuario, clave) do
    entrenadores = Persistencia.cargar_entrenadores()

    case Map.get(entrenadores, usuario) do
      nil ->
        nuevo_entrenador = crear_entrenador(clave)

        entrenadores_actualizados =
          Map.put(entrenadores, usuario, nuevo_entrenador)

        Persistencia.guardar_entrenadores(entrenadores_actualizados)

        {:ok, :registrado, usuario, nuevo_entrenador}

      %{"clave" => ^clave} = entrenador ->
        {:ok, :sesion_iniciada, usuario, entrenador}

      _ ->
        {:error, :clave_incorrecta}
    end
  end

  def obtener_entrenador(usuario) do
    Persistencia.cargar_entrenadores()
    |> Map.get(usuario)
  end

  def perfil(usuario) do
    case obtener_entrenador(usuario) do
      nil ->
        {:error, :entrenador_no_encontrado}

      entrenador ->
        inventario = Map.get(entrenador, "inventario", [])
        sobres = Map.get(entrenador, "sobres", [])

        mensaje = """
        === Perfil de #{usuario} ===
        Monedas: #{entrenador["monedas_actuales"]}
        Sobres pendientes: #{length(sobres)}
        Pokémon en inventario: #{length(inventario)}
        Victorias: #{entrenador["victorias"]}
        Monedas acumuladas: #{entrenador["monedas_acumuladas"]}
        """

        {:ok, mensaje}
    end
  end

  def inventario(usuario) do
    case obtener_entrenador(usuario) do
      nil ->
        {:error, :entrenador_no_encontrado}

      entrenador ->
        lista = Map.get(entrenador, "inventario", [])

        if lista == [] do
          {:ok, "El inventario está vacío."}
        else
          mensaje =
            lista
            |> Enum.with_index(1)
            |> Enum.map(fn {pokemon, index} ->
              movimientos =
                pokemon["movimientos"]
                |> Enum.map(fn mov ->
                  "#{mov["nombre"]}(#{mov["poder_base"]})"
                end)
                |> Enum.join(", ")

              """
              #{index}. [##{pokemon["id"]}] #{pokemon["nombre"]} [#{pokemon["rareza"]}]
                 Especie: #{pokemon["especie"]}
                 Ataque: #{pokemon["ataque"]} | Defensa: #{pokemon["defensa"]} | Velocidad: #{pokemon["velocidad"]} | Salud máx: 100
                 Dueño original: #{pokemon["dueño_original"]}
                 Movimientos: #{movimientos}
              """
            end)
            |> Enum.join("\n")

          {:ok, "=== Inventario de #{usuario} (#{length(lista)} Pokémon) ===\n" <> mensaje}
        end
    end
  end

  def agregar_pokemon(usuario, nuevos_pokemon) do
    entrenadores = Persistencia.cargar_entrenadores()

    case Map.get(entrenadores, usuario) do
      nil ->
        {:error, :entrenador_no_encontrado}

      entrenador ->
        inventario_actual = Map.get(entrenador, "inventario", [])

        entrenador_actualizado =
          Map.put(entrenador, "inventario", inventario_actual ++ nuevos_pokemon)

        entrenadores_actualizados =
          Map.put(entrenadores, usuario, entrenador_actualizado)

        Persistencia.guardar_entrenadores(entrenadores_actualizados)

        {:ok, entrenador_actualizado}
    end
  end

  def actualizar_entrenador(usuario, entrenador_actualizado) do
    entrenadores = Persistencia.cargar_entrenadores()

    entrenadores_actualizados =
      Map.put(entrenadores, usuario, entrenador_actualizado)

    Persistencia.guardar_entrenadores(entrenadores_actualizados)

    {:ok, entrenador_actualizado}
  end

  def sumar_monedas(usuario, cantidad) do
    entrenadores = Persistencia.cargar_entrenadores()

    case Map.get(entrenadores, usuario) do
      nil ->
        {:error, :entrenador_no_encontrado}

      entrenador ->
        monedas_actuales = Map.get(entrenador, "monedas_actuales", 0)
        monedas_acumuladas = Map.get(entrenador, "monedas_acumuladas", 0)

        entrenador_actualizado =
          entrenador
          |> Map.put("monedas_actuales", monedas_actuales + cantidad)
          |> Map.put("monedas_acumuladas", monedas_acumuladas + cantidad)

        actualizar_entrenador(usuario, entrenador_actualizado)
    end
  end

  def registrar_victoria(usuario) do
    entrenadores = Persistencia.cargar_entrenadores()

    case Map.get(entrenadores, usuario) do
      nil ->
        {:error, :entrenador_no_encontrado}

      entrenador ->
        victorias = Map.get(entrenador, "victorias", 0)

        entrenador_actualizado =
          Map.put(entrenador, "victorias", victorias + 1)

        actualizar_entrenador(usuario, entrenador_actualizado)
    end
  end

  def clasificacion do
    Persistencia.cargar_entrenadores()
    |> Enum.map(fn {usuario, entrenador} ->
      %{
        usuario: usuario,
        victorias: Map.get(entrenador, "victorias", 0),
        monedas_acumuladas: Map.get(entrenador, "monedas_acumuladas", 0)
      }
    end)
    |> Enum.sort_by(fn entrenador ->
      {-entrenador.victorias, -entrenador.monedas_acumuladas}
    end)
    |> generar_mensaje_clasificacion()
  end

  defp crear_entrenador(clave) do
    %{
      "clave" => clave,
      "victorias" => 0,
      "monedas_actuales" => 100,
      "monedas_acumuladas" => 100,
      "inventario" => [],
      "sobres" => [
        %{
          "id" => generar_id(),
          "tipo" => "basico"
        }
      ],
      "equipos" => %{}
    }
  end

  defp generar_mensaje_clasificacion(lista) do
    encabezado = """
    === Clasificación Global ===
    #    Entrenador   Victorias   Monedas acumuladas
    """

    cuerpo =
      lista
      |> Enum.with_index(1)
      |> Enum.map(fn {entrenador, index} ->
        "#{index}    #{entrenador.usuario}          #{entrenador.victorias}           #{entrenador.monedas_acumuladas}"
      end)
      |> Enum.join("\n")

    encabezado <> cuerpo
  end

  defp generar_id do
    :rand.uniform(90_000) + 10_000
  end
end
