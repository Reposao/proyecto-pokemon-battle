\# Responsabilidades técnicas del equipo



Este documento resume las responsabilidades técnicas asumidas por cada integrante durante la integración, revisión y preparación final del proyecto.



\## Alejandro Vargas



Responsable de la integración general del proyecto y del cierre funcional de la entrega.



Actividades realizadas:



\- Integración general del proyecto en estructura Mix.

\- Organización de módulos principales.

\- Validación del flujo completo por consola.

\- Revisión del sistema de entrenadores.

\- Revisión del sistema de sobres y tienda.

\- Revisión del inventario persistente.

\- Revisión de equipos reutilizables.

\- Revisión de salas de batalla.

\- Revisión de batalla interactiva por turnos.

\- Validación de acciones de batalla: atacar, cambiar, pasar y rendirse.

\- Validación de recompensas, monedas y victorias.

\- Validación de intercambio de Pokémon.

\- Verificación de persistencia en archivos JSON.

\- Verificación de pruebas unitarias.

\- Prueba de ejecución distribuida con nodos.

\- Preparación de documentación final del repositorio.



Archivos o áreas asociadas:



\- `lib/pokemon\_battle/servidor.ex`

\- `lib/pokemon\_battle/gestor\_entrenadores.ex`

\- `lib/pokemon\_battle/sistema\_sobres.ex`

\- `lib/pokemon\_battle/gestor\_equipos.ex`

\- `lib/pokemon\_battle/gestor\_salas.ex`

\- `lib/pokemon\_battle/persistencia.ex`

\- `lib/pokemon\_battle/batalla.ex`

\- `lib/pokemon\_battle/intercambio.ex`

\- `test/pokemon\_battle\_test.exs`

\- `README.md`

\- `docs/`



\## Nicolás



Responsable de la validación del proyecto en un entorno diferente de desarrollo y del ajuste de compatibilidad de versión de Elixir.



Actividades realizadas:



\- Clonación del repositorio en otro computador.

\- Instalación y descarga de dependencias.

\- Validación de compilación.

\- Ejecución de pruebas unitarias.

\- Identificación de incompatibilidad con Elixir 1.18.

\- Ajuste de compatibilidad en `mix.exs`.

\- Confirmación de pruebas exitosas después del ajuste.



Archivos o áreas asociadas:



\- `mix.exs`

\- Validación de dependencias.

\- Validación de pruebas con ExUnit.



\## Juan Pablo



Responsable de la revisión y documentación de la arquitectura concurrente y distribuida del proyecto.



Actividades asignadas:



\- Revisión de nodos distribuidos.

\- Revisión de procesos de batalla.

\- Revisión de GenServer.

\- Revisión de DynamicSupervisor.

\- Validación conceptual de ejecución remota de batallas.

\- Apoyo en documentación de arquitectura OTP.



Archivos o áreas asociadas:



\- `lib/pokemon\_battle/cluster.ex`

\- `lib/pokemon\_battle/batalla.ex`

\- `lib/pokemon\_battle/supervisor\_batallas.ex`

\- `lib/pokemon\_battle/supervisor\_intercambios.ex`

\- `docs/nodos\_distribuidos.md`

