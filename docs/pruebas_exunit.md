# Pruebas unitarias con ExUnit

Este documento describe las pruebas unitarias implementadas para validar el funcionamiento principal del proyecto Pokémon Battle.

## Objetivo de las pruebas

Las pruebas permiten verificar que los módulos principales del sistema funcionen correctamente antes de ejecutar el proyecto completo por consola.

El proyecto se valida con ExUnit, que es la herramienta de pruebas incluida en Elixir.

## Ejecución de pruebas

Para ejecutar las pruebas se usa el comando:

```bash
mix.bat test
```

Resultado esperado:

```text
8 tests, 0 failures
```

## Pruebas del motor de combate

Se valida el cálculo de efectividad entre tipos, incluyendo:

- Tipo fuerte.
- Tipo débil.
- Tipo neutro.

También se valida que el orden de turno se determine correctamente según la velocidad de los Pokémon. El Pokémon con mayor velocidad debe actuar primero.

## Pruebas de economía

Se valida la asignación de monedas después de una batalla:

- Ganador: recibe 100 monedas.
- Perdedor: recibe 30 monedas.
- Ambos valores se suman al acumulado histórico del entrenador.

## Pruebas de sobres

Se valida la compra y apertura de sobres.

La prueba confirma que:

- El entrenador pueda comprar un sobre si tiene monedas suficientes.
- El sobre abierto entregue 3 Pokémon.
- Cada Pokémon tenga rareza.
- Cada Pokémon tenga dueño original.
- Cada Pokémon tenga estadísticas.
- Cada Pokémon tenga exactamente 4 movimientos.

## Pruebas de intercambio

Se valida el intercambio de Pokémon entre dos entrenadores.

La prueba confirma que:

- Dos entrenadores puedan crear y usar una sala de intercambio.
- Cada entrenador pueda ofrecer un Pokémon.
- El intercambio se complete cuando ambos confirman.
- Los Pokémon cambien de inventario.
- Los Pokémon conserven sus datos principales como id, rareza, movimientos y dueño original.

## Validaciones adicionales de intercambio

También se validan reglas importantes para evitar errores en el sistema:

- No permitir crear una sala de intercambio si el entrenador está en una sala de batalla.
- No permitir que un entrenador tenga dos salas de intercambio activas.
- No permitir ofrecer en intercambio un Pokémon que está en el equipo activo.

## Importancia dentro del proyecto

Estas pruebas ayudan a comprobar que las funcionalidades principales del sistema funcionan correctamente:

- Combate.
- Turnos.
- Economía.
- Sobres.
- Inventario.
- Intercambio.
- Validaciones de reglas.

Con esto se cumple el requisito de pruebas mínimas solicitado en el proyecto y se agrega una validación adicional sobre reglas de intercambio.