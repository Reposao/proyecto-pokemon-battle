\# Arquitectura OTP y procesos distribuidos



Este documento describe la arquitectura concurrente y distribuida utilizada en el proyecto Pokémon Battle.



\## Objetivo de la arquitectura



El proyecto utiliza características propias de Elixir y OTP para manejar procesos independientes, tolerancia a fallos y ejecución distribuida.



La arquitectura permite que las batallas y las salas de intercambio se ejecuten como procesos separados, evitando que una falla en una batalla afecte todo el sistema.



\## GenServer



En el proyecto se usan procesos `GenServer` para encapsular estados y comportamientos específicos.



Los módulos principales relacionados con esta idea son:



\- `PokemonBattle.Batalla`

\- `PokemonBattle.Intercambio`

\- `PokemonBattle.GestorSalas`

\- `PokemonBattle.GestorIntercambios`



Cada batalla mantiene su propio estado, incluyendo:



\- Jugadores.

\- Equipos.

\- Pokémon activos.

\- Turnos.

\- Acciones.

\- Ganador.

\- Resumen de eventos.



Cada sala de intercambio también mantiene su propio estado, incluyendo:



\- Participantes.

\- Pokémon ofrecidos.

\- Confirmaciones.

\- Estado de la sala.



\## DynamicSupervisor



El proyecto utiliza supervisores dinámicos para crear procesos bajo demanda.



Los módulos relacionados son:



\- `PokemonBattle.SupervisorBatallas`

\- `PokemonBattle.SupervisorIntercambios`



Esto permite que cada batalla o intercambio se cree como un proceso independiente cuando el usuario lo solicita.



La ventaja de usar `DynamicSupervisor` es que el sistema puede manejar múltiples batallas o intercambios sin tener que definirlos manualmente desde el inicio de la aplicación.



\## Concurrencia



La concurrencia se evidencia porque cada batalla vive en su propio proceso.



Esto permite que varias batallas puedan existir de manera independiente, sin compartir directamente el mismo estado.



Por ejemplo:



```text

Batalla S-1001 -> proceso independiente

Batalla S-1002 -> proceso independiente

Intercambio IC-001 -> proceso independiente

```



Si una batalla termina o falla, no debería afectar las demás partes del sistema.



\## Distribución con nodos Elixir



El proyecto también permite conectar nodos Elixir.



Un nodo es una instancia independiente de la máquina virtual BEAM. En la prueba del proyecto se usaron dos nodos:



```text

nodo1@LAPTOP-TQ97S0LH

nodo2@LAPTOP-TQ97S0LH

```



El nodo principal recibe los comandos del usuario, mientras que un nodo remoto puede recibir procesos de batalla.



\## Comandos usados para nodos



Nodo 1:



```bash

iex.bat --sname nodo1 --cookie pokemon\_cookie -S mix

```



Dentro de IEx:



```elixir

PokemonBattle.Servidor.main()

```



Nodo 2:



```bash

iex.bat --sname nodo2 --cookie pokemon\_cookie -S mix

```



Desde el nodo 1 se conecta el nodo 2:



```text

conectar\_nodo nodo2@LAPTOP-TQ97S0LH

```



Luego se verifica con:



```text

nodos

```



\## Asignación de batallas a nodos



Cuando existe un nodo conectado, el sistema puede asignar una batalla a ese nodo remoto.



La evidencia esperada es:



```text

Nodo asignado: nodo2@LAPTOP-TQ97S0LH

```



Esto demuestra que la batalla fue creada en un nodo diferente al nodo principal.



\## Módulo Cluster



El módulo `PokemonBattle.Cluster` se encarga de apoyar la conexión con nodos y la asignación de batallas.



Su función principal es revisar si hay nodos conectados y decidir si una batalla se ejecuta localmente o en un nodo remoto.



\## Ventajas de esta arquitectura



La arquitectura usada permite:



\- Separar responsabilidades por módulos.

\- Crear batallas de forma independiente.

\- Crear intercambios de forma independiente.

\- Manejar concurrencia usando procesos.

\- Usar supervisión dinámica.

\- Ejecutar batallas en nodos conectados.

\- Evitar que una falla local afecte todo el sistema.

\- Cumplir con los requisitos de concurrencia y distribución del proyecto.



\## Conclusión



La arquitectura OTP implementada permite que el proyecto no sea solamente una aplicación de consola, sino un sistema concurrente y distribuido basado en procesos Elixir.



El uso de `GenServer`, `DynamicSupervisor` y nodos conectados permite cumplir los requisitos técnicos del proyecto final.

