# Evidencias de pruebas y ejecución

Este documento resume las evidencias principales usadas para validar el correcto funcionamiento del proyecto.

## Compilación del proyecto

Comando ejecutado:

```bash
mix.bat compile
```

Resultado esperado:

```text
Generated pokemon_battle app
```

La compilación confirma que los módulos del sistema no presentan errores de sintaxis ni errores de dependencias.

## Ejecución de pruebas unitarias

Comando ejecutado:

```bash
mix.bat test
```

Resultado esperado:

```text
8 tests, 0 failures
```

Las pruebas unitarias validan:

- Cálculo de efectividad fuerte, débil y neutra.
- Orden de turno por velocidad.
- Asignación de monedas al ganador y al perdedor.
- Compra y apertura de sobres.
- Intercambio de Pokémon.
- Restricción de intercambio si el entrenador está en sala de batalla.
- Restricción de doble sala de intercambio activa.
- Restricción de intercambio de Pokémon en equipo activo.

## Ejecución local del sistema

Comando ejecutado:

```bash
mix.bat run -e "PokemonBattle.Servidor.main"
```

Flujo básico validado:

```text
iniciar alejo 1234
abrir_sobre ultimo
inventario
crear_equipo rapido ID1,ID2,ID3
usar_equipo rapido
crear_sala tiempo_turno=300
salir
iniciar luis 1234
unirse_sala S-1001
iniciar_batalla S-1001
```

## Acciones de batalla validadas

Durante la batalla se validaron las siguientes acciones:

```text
ataque <movimiento>
cambiar <id_pokemon>
pasar
rendirse
```

El sistema muestra el turno, el Pokémon activo, el rival, los movimientos disponibles y valida si una acción es correcta o incorrecta.

## Ejecución distribuida con nodos

Se probaron dos nodos Elixir conectados.

Terminal 1:

```bash
iex.bat --sname nodo1 --cookie pokemon_cookie -S mix
```

Terminal 2:

```bash
iex.bat --sname nodo2 --cookie pokemon_cookie -S mix
```

Desde `nodo1` se ejecutó:

```text
conectar_nodo nodo2@LAPTOP-TQ97S0LH
nodos
```

Evidencia esperada:

```text
Nodos conectados:
- nodo2@LAPTOP-TQ97S0LH
```

Al iniciar una batalla, el sistema mostró:

```text
Nodo asignado: nodo2@LAPTOP-TQ97S0LH
```

Esto evidencia que la batalla fue asignada a un nodo remoto conectado.

## Registro en battles.log

El sistema registra las batallas en:

```text
data/battles.log
```

El log incluye:

- Jugadores.
- Ganador.
- Nodo donde se ejecutó.
- Duración.
- Resumen de acciones.

