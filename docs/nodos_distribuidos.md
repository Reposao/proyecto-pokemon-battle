\# Ejecución distribuida con nodos Elixir



El proyecto permite ejecutar batallas usando nodos distribuidos de Elixir.



Un nodo en Elixir es una instancia independiente de la máquina virtual BEAM. En este proyecto se usaron dos nodos:



\- `nodo1`: nodo principal donde se ejecuta la consola del juego.

\- `nodo2`: nodo remoto disponible para recibir procesos de batalla.



\## Nodo 1



```bash

iex.bat --sname nodo1 --cookie pokemon\_cookie -S mix

```



Dentro de IEx:



```elixir

PokemonBattle.Servidor.main()

```



\## Nodo 2



```bash

iex.bat --sname nodo2 --cookie pokemon\_cookie -S mix

```



El nodo 2 queda abierto como nodo remoto de trabajo.



\## Conectar nodos



Desde el nodo 1:



```text

conectar\_nodo nodo2@NOMBRE\_DEL\_EQUIPO

nodos

```



Ejemplo:



```text

conectar\_nodo nodo2@LAPTOP-TQ97S0LH

```



\## Evidencia esperada



Al iniciar una batalla, el sistema muestra:



```text

Nodo asignado: nodo2@LAPTOP-TQ97S0LH

```



Esto evidencia que la batalla fue creada en un nodo remoto conectado.



\## Diferencia entre ejecución local y distribuida



Si no hay nodos conectados, la batalla se ejecuta en el nodo local.



Si existe un nodo conectado, el sistema puede asignar la batalla al nodo remoto usando comunicación distribuida con Elixir.



Esto permite demostrar que el proyecto no depende únicamente de una sola instancia de ejecución.

