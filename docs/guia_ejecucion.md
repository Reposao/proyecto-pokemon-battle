# Guía de ejecución del proyecto

## Instalar dependencias

```bash
mix.bat deps.get
```

## Compilar

```bash
mix.bat compile
```

## Ejecutar pruebas

```bash
mix.bat test
```

Resultado esperado:

```text
8 tests, 0 failures
```

## Ejecutar aplicación

```bash
mix.bat run -e "PokemonBattle.Servidor.main"
```

## Comandos principales

```text
iniciar alejo 1234
abrir_sobre ultimo
inventario
crear_equipo rapido ID1,ID2,ID3
usar_equipo rapido
crear_sala tiempo_turno=300
unirse_sala S-1001
iniciar_batalla S-1001
```

## Acciones durante batalla

```text
ataque <movimiento>
cambiar <id_pokemon>
pasar
rendirse
```

## Intercambio

```text
crear_sala_intercambio
unirse_sala_intercambio IC-001
ofrecer_pokemon <id_pokemon>
confirmar_intercambio
estado_intercambio
cancelar_intercambio
```