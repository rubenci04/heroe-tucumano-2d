# Auditoría de pacing — Famaillá / Ruta 38

Fecha: 2026-09-08. Alcance: lectura del estado actual desde X=0 hasta X=8000. No se modificaron gameplay, datos, balance, escenas, arte ni actores.

## Resumen

Ruta 38 tiene 8000 px de mundo, dos carriles y ocho encuentros configurados. El tráfico opera entre X=1400 y X=6500, el calor empieza después de X=3200, y el checkpoint está en X=3600 (respawn `(3600, 370)`). La ruta ya dibuja una progresión razonable de terrestre a aéreo y a élite, pero necesita una regla de ritmo para evitar que una oleada no resuelta se sume a la siguiente al avanzar por X.

La estimación actual es **8–12 minutos para una primera partida sin muertes**, incluida la intro, recogidas, combate deliberado y aprendizaje de carriles. Es una estimación de diseño, no un playtest cronometrado; el objetivo histórico de 10–15 minutos debe confirmarse con jugadores.

## Mapa de pacing actual

| Tramo | Contenido y landmarks | Intensidad | Lectura de ritmo |
| --- | --- | ---: | --- |
| 0–899 | Inicio en Famaillá; cartel x271, empanadas x240/750, naranjo funcional x520/carril 0, palmeras x680. | 1/5 | Introducción segura: permite entender desplazamiento, salto y el primer recurso antes del combate. |
| 900–1399 | `route_wave_01`: 2 Hipsters (uno por carril). Poste x1000, empanada x1350. | 2/5 | Enseñanza limpia de dos carriles y proyectil enemigo; buen primer combate. |
| 1400–2199 | Tráfico inicia; cascotes x1450/carril 0, gruta y kiosco x1453–1464, plataforma Auto1 x1900, kiosco POC x1650, parada POC x2100, empanada x2000/carril 1. | 2/5 | Descanso activo y aprendizaje de tráfico/plataformas. No hay encuentro formal entre x900 y x2200: es el primer tramo largo de baja presión. |
| 2200–3199 | `route_wave_02`: Agente carril 1 + Hipster carril 0. Árbol visual x2420, sánguche x2800/carril 1, plataforma camión x3100. | 3/5 | Variación de rango y recuperación. La distancia de 1300 px desde la oleada anterior es amplia, pero el contenido lateral la sostiene. |
| 3200–4099 | Calor empieza después de x3200; Achilata x3200/carril 0; `route_wave_03` x3500: 2 Agentes; checkpoint x3600; parada visual x3600; empanada x3400/carril 1. | 3/5 | Escalada controlada: introduce presión ambiental y checkpoint antes de la parte aérea. Riesgo: calor + dos proyectiles antes/de inmediato alrededor del checkpoint. |
| 4100–4699 | `route_drone_01`: 1 Drone carril 0; empanada x4100/carril 0; Achilata x4300/carril 0; cascotes x4400/carril 0; poste x3950 y x4500. Tráfico activo. | 3/5 | Enseñanza aérea aislada y buen suministro de respuesta. El espacio de 600 px hasta la siguiente oleada es corto si el Drone no se limpia. |
| 4700–5399 | `route_wave_04`: Grandote carril 1 + Agente carril 0; parada visual x4800, plataforma Auto2 x5000, árbol visual x5120, empanada x4900/carril 1. | 4/5 | Primer pico terrestre/a distancia con tráfico y plataformas. Es el primer lugar de acumulación injusta potencial si el Drone anterior sigue vivo. |
| 5400–6099 | `route_drone_02`: 2 Drones, uno por carril; Achilata x5400/carril 1, empanada x5600/carril 0, poste x5200/x5800. | 4/5 | Variación aérea clara. El Achilata de entrada amortigua calor, pero dos Drones más tráfico elevan la demanda de lectura. |
| 6100–6999 | `route_drone_03`: Drone carril 0 + Agente carril 1; sánguche x6200/carril 1, árbol visual x6420, Achilata x6500/carril 0; tráfico termina en x6500. | 4/5 → 2/5 | Última prueba de aire+tierra. Tras x6500 desaparece el tráfico y queda un respiro parcial antes de los élites. |
| 7000–7599 | `route_wave_06`: 2 Grandotes, uno por carril; empanada x7000/carril 0, Achilata x7200/carril 1, empanada x7500/carril 1, plataforma Auto3 x6700. | 5/5 | Clímax actual de encuentros normales. Los recursos posteriores son una buena transición a boss, aunque el empanada x7500 queda muy cerca de la zona del boss legacy. |
| 7600–8000 | Datos legacy del Palermitano: spawn x7600, trigger x7800; sin integración de encuentro/cierre final vigente. | — | Espacio final sin ritmo formal implementado. Es la reserva natural para arena, presentación y cierre. |

## Sistemas transversales

- **Pickups:** empanadas alternan carril a lo largo de toda la ruta; naranjo y ambos cascotes están en carril 0; sánguches en carril 1; seis Achilatas alternan de x3200 a x7200 y reducen 50 de calor.
- **Plataformas:** todas están en carril 0: kiosco/Auto1 x1650–1900, parada x2100, camión x3100, Auto2 x5000 y Auto3 x6700. Sirven como variedad vertical, pero concentran la opción de salto en un solo carril.
- **Tráfico:** máximo dos vehículos, alternancia de carril/dirección, x1400–6500. Es una amenaza transversal que puede convertir una oleada de intensidad 3 en 4.
- **Drones:** mantienen carril lógico aunque vuelen alto; su anclaje visual actual mejora esa lectura. No tienen gravedad y sus proyectiles sólo interactúan en su carril.
- **Landmarks:** cartel de entrada, gruta/kiosco, paradas x2113/3600/4800, árboles visuales x2420/4086/5120/6420 y postes x1000–6450 crean puntos adecuados para microeventos sin alterar el recorrido.

## Problemas detectados

1. **Acumulación no bloqueada.** `EncounterDirector` activa por X y no exige completar la oleada anterior. Un jugador que atraviese x4100–6100 sin limpiar puede solapar Drone, Grandote/Agente y posteriores Drones, además de tráfico y calor.
2. **Pico 4700–6500.** Grandote+Agente, dos Drones y Drone+Agente se presentan en tres ventanas de 600–700 px mientras tráfico y calor aún están activos. Es el mayor riesgo de fatiga o injusticia.
3. **Ritmo temprano disperso.** Los 1300 px entre x900→2200 y x2200→3500 son largos para un run-and-gun, aunque los pickups, plataformas y landmarks amortiguan el vacío.
4. **Clímax sin transición formal.** La doble oleada de Grandotes en x7000 está bien como prueba final, pero el paso hacia el boss no está implementado y el spawn legacy x7600 deja poco margen para una presentación si se usa sin staging.
5. **Asimetría de carriles.** Plataformas, naranjo y cascotes favorecen carril 0; no rompe el pacing, pero limita la variedad espacial durante la mitad inicial.

## Zonas útiles para gags, secretos o eventos visuales

| Zona | Oportunidad | Motivo |
| --- | --- | --- |
| 520–750 | gag del naranjo / señal de aprendizaje | Sin combate y con primer recurso claro. |
| 1450–2113 | secreto corto alrededor de gruta, kiosco o parada | Es descanso activo con cascotes y plataformas. |
| 2800–3100 | beat de recuperación junto al sánguche/camión | Espacio entre combate y calor; ideal para anticipar insolación. |
| 3600 | beat de checkpoint/parada | Punto de continuidad natural tras la oleada de Agentes. |
| 4300–4400 | mini-secreto de Achilata + cascotes | Enseña preparación antes del Grandote. |
| 4800–5120 | gag de parada/Auto2/árbol | Visualmente reconocible, pero sólo después de no saturar el combate. |
| 6500–6999 | respiro visual de llegada a Río Seco | Fin de tráfico, Achilata y aproximación al clímax. |
| 7200–7500 | pre-boss breve | Últimos recursos; debe evitar otro combate o gag largo. |

## Curva recomendada para cerrar el escenario

La siguiente es una propuesta de orden para una futura tarea de diseño; no cambia el estado actual:

1. **Introducción (0–900):** naranjo, empanadas y desplazamiento/salto.
2. **Aprendizaje (900–2200):** dos Hipsters; luego tráfico, cascotes y primeras plataformas sin encuentro adicional.
3. **Escalada (2200–4100):** Agente+Hipster, sánguche, calor, dos Agentes y checkpoint.
4. **Variación (4100–5400):** Drone solo, recursos de respuesta, luego Grandote+Agente. Requerir o incentivar limpiar el Drone antes del Grandote.
5. **Presión corta y respiro (5400–7000):** dos Drones, luego Drone+Agente; después de x6500 cortar tráfico y reservar 500–900 px de recuperación antes de los élites.
6. **Clímax (7000–7200):** doble Grandote como prueba de control de carril; Achilata x7200 como recompensa/seguro.
7. **Boss (aprox. 7600):** entrada de Palermitano con una breve presentación y arena propia, sin tráfico ni oleada residual.

### Propuesta concreta de orden final

`Hipsters → tráfico/plataformas → Agente+Hipster → calor/Agentes/checkpoint → Drone → Grandote+Agente → 2 Drones → Drone+Agente → fin de tráfico/respiro → 2 Grandotes → Achilata → Palermitano`.

No añadiría otra oleada normal después de los dos Grandotes. Para no alargar innecesariamente, el Palermitano debe reemplazar el vacío final, no sumar una cuarta escalada.

## Posición recomendada para Palermitano

**X=7600** es la mejor ubicación de spawn porque coincide con el dato legacy, deja la franja x7200–7500 para recuperación/preparación y queda fuera del tráfico. Recomiendo que una futura integración use una activación/entrada en torno a **x7400–7450** y revise el actual `trigger_x=7800`, ya que activar más tarde reduce demasiado la presentación y el espacio de arena dentro del mundo de 8000 px.

La condición previa indispensable es que no existan oleadas normales vivas al iniciar la arena. Esto puede resolverse después por secuenciación de encuentros o limpieza de arena, pero no se implementó ni se recomienda cambiarlo dentro de esta auditoría.
