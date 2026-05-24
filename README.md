# Proyecto Final - Batallas Pokémon en Elixir

## Universidad del Quindío
Programa de Ingeniería de Sistemas y Computación  
Asignatura: Programación III  
Proyecto Final: Batallas Pokémon por turnos  

---

## 1. Descripción general

Este proyecto implementa una plataforma de batallas Pokémon por turnos utilizando Elixir.

El sistema funciona mediante una interfaz por consola y permite registrar entrenadores, iniciar sesión, comprar y abrir sobres, obtener Pokémon aleatorios, crear equipos, crear salas de batalla, realizar batallas 1v1, intercambiar Pokémon entre entrenadores y guardar la información en archivos.

El proyecto utiliza conceptos vistos en Programación III como:

- Módulos.
- Funciones puras.
- Listas, mapas y tuplas.
- Pattern matching.
- Enum.
- Persistencia en archivos JSON.
- Procesos.
- GenServer.
- DynamicSupervisor.
- Distribución entre nodos.
- Pruebas unitarias con ExUnit.

---

## 2. Funcionalidades implementadas

El sistema cuenta con las siguientes funcionalidades:

### Entrenadores

- Registro automático de usuarios.
- Inicio de sesión con usuario y clave.
- Perfil del entrenador.
- Inventario persistente.
- Monedas actuales.
- Monedas acumuladas.
- Victorias.
- Clasificación global.

### Sobres y tienda

- Tienda de sobres.
- Compra de sobres básicos y avanzados.
- Apertura de sobres.
- Cada sobre entrega 3 Pokémon.
- Sorteo de rareza: común, raro y épico.
- Cálculo de estadísticas según rareza.
- Asignación aleatoria de 4 movimientos.
- Persistencia del inventario.

### Pokémon

Cada Pokémon de inventario tiene:

- ID único.
- Especie.
- Nombre.
- Tipos.
- Dueño original.
- Rareza.
- Ataque.
- Defensa.
- Velocidad.
- Movimientos.
- Salud máxima de 100 durante batalla.

### Equipos

- Crear equipos de 1 a 3 Pokémon.
- Listar equipos.
- Seleccionar equipo activo.
- Agregar Pokémon a un equipo.
- Quitar Pokémon de un equipo.
- Validación de Pokémon existentes en inventario.

### Batallas

- Crear salas de batalla.
- Listar salas.
- Unirse a salas.
- Iniciar batalla 1v1.
- Cada batalla corre en un proceso GenServer.
- Las batallas son supervisadas por un DynamicSupervisor.
- El combate usa velocidad para determinar el orden de ataque.
- El daño tiene en cuenta:
  - Poder del movimiento.
  - Ataque del atacante.
  - Defensa del defensor.
  - Efectividad de tipos.
  - STAB.
  - Factor aleatorio.
- Se otorgan monedas:
  - 100 monedas al ganador.
  - 30 monedas al perdedor.
- Se registra la batalla en `data/battles.log`.

### Intercambios

- Crear sala de intercambio.
- Unirse a sala de intercambio.
- Ofrecer Pokémon.
- Confirmar intercambio.
- Cancelar intercambio.
- Cuando ambos entrenadores confirman, los Pokémon cambian de inventario.
- Los Pokémon conservan:
  - ID.
  - Rareza.
  - Movimientos.
  - Dueño original.

### Distribución

El proyecto incluye un módulo `Cluster` para:

- Consultar nodo actual.
- Listar nodos conectados.
- Conectar con otros nodos.
- Asignar batallas a un nodo local o remoto.

---

## 3. Estructura del proyecto

```text
proyecto_final/
├── data/
│   ├── trainers.json
│   ├── pokemon.json
│   ├── moves.json
│   ├── tienda.json
│   └── battles.log
│
├── lib/
│   ├── pokemon_battle.ex
│   └── pokemon_battle/
│       ├── application.ex
│       ├── persistencia.ex
│       ├── gestor_entrenadores.ex
│       ├── sistema_sobres.ex
│       ├── motor_combate.ex
│       ├── gestor_equipos.ex
│       ├── gestor_salas.ex
│       ├── supervisor_batallas.ex
│       ├── batalla.ex
│       ├── supervisor_intercambios.ex
│       ├── intercambio.ex
│       ├── gestor_intercambios.ex
│       └── cluster.ex
│
├── test/
│   ├── test_helper.exs
│   └── pokemon_battle_test.exs
│
├── mix.exs
└── README.md

## Documentación adicional

El proyecto incluye documentación complementaria en la carpeta `docs/`:

- `docs/guia_ejecucion.md`: comandos para instalar, compilar, probar y ejecutar el proyecto.
- `docs/nodos_distribuidos.md`: explicación de la ejecución distribuida con nodos Elixir.
- `docs/roles_equipo.md`: roles generales del equipo.
- `docs/responsabilidades_tecnicas.md`: responsabilidades técnicas por integrante.
- `docs/evidencias_pruebas.md`: evidencias de compilación, pruebas, ejecución local y nodos.