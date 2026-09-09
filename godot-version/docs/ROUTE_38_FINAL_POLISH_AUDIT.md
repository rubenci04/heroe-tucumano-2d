# Auditoría final de gameplay y pulido — Famaillá / Ruta 38

Fecha: 2026-09-08. Alcance: evaluación de solo lectura del vertical slice actual, desde selección/intro hasta diálogo y `RESULT`. No se modificaron gameplay, datos, escenas, balance, colisiones ni arte.

## Veredicto

El slice ya forma una experiencia completa y técnicamente cerrada. La curva se entiende: introducción segura, combate terrestre, tráfico y plataformas, calor, progresión aérea, élites, descanso corto y Palermitano. En una ruta limpia, cada encuentro normal contiene como máximo dos enemigos, el tráfico desaparece antes del clímax y el boss dispone de ventanas de castigo razonables.

La duración estimada actual es **9–13 minutos en una primera partida sin muertes**, incluyendo intro, exploración breve, recogidas y boss. Una repetición informada debería quedar aproximadamente en **6–9 minutos**. Son estimaciones derivadas de distancias, velocidades y timings; falta un playtest humano cronometrado.

Hay un problema crítico antes de considerar el escenario listo para publicación: los encuentros se activan de manera independiente por X y el boss sólo exige que termine `route_wave_06`, no que todo el recorrido anterior esté limpio.

## Lectura del recorrido actual

| Tramo | Presión principal | Evaluación actual |
| --- | --- | --- |
| 0–900 | Naranjo, empanadas, aprendizaje | Introducción clara y suficientemente segura. |
| 900–2200 | 2 Hipsters; luego tráfico, cascotes y primeras plataformas | Buen aprendizaje. El descanso activo entre oleadas evita saturación. |
| 2200–3500 | Agente + Hipster, sánguche, camión-plataforma | Escalada suave y recursos bien introducidos. |
| 3500–4100 | 2 Agentes, calor y checkpoint | Primer punto de fricción: checkpoint muy cercano al trigger de la oleada. |
| 4100–4700 | 1 Drone + tráfico | La introducción aérea aislada funciona, siempre que se elimine antes de avanzar. |
| 4700–6500 | Grandote + Agente → 2 Drones → Drone + Agente, con calor y tráfico | Sección más exigente. Los triggers separados 600–700 px permiten solapamientos rápidos. |
| 6500–7000 | Fin del tráfico, Achilata y plataforma Auto3 | Respiro útil antes del clímax terrestre. |
| 7000–7425 | 2 Grandotes, Achilata y empanadas | Clímax normal legible; la transición al boss es corta pero funcional. |
| 7425–RESULT | Palermitano, arena y cierre | Flujo completo: arena, HUD, boss, diálogo y resultado. |

## Sistemas transversales

### Encuentros y simultaneidad

La composición prevista es moderada: ocho encuentros de 1–2 enemigos. La progresión aérea está bien graduada:

1. x=4100: un Drone en carril 0;
2. x=5400: dos Drones, uno por carril;
3. x=6100: Drone en carril 0 + Agente en carril 1.

Grandote aparece primero acompañado por un Agente en x=4700 y luego como pareja final en x=7000. Esto enseña su rol pesado antes de usarlo como examen terrestre. El problema no es cada composición, sino que `EncounterDirector` no obliga a resolverla antes del siguiente trigger. Si Player atraviesa todo sin limpiar, pueden quedar hasta **15 enemigos normales activos** antes de matar los dos Grandotes finales; tras completar sólo `route_wave_06`, todavía podrían entrar al boss hasta **13 enemigos anteriores**, además de Palermitano y sus dos summons. Los proyectiles pendientes tampoco se limpian al iniciar el boss.

### Tráfico

Opera entre x=1400–6500, con intervalo de 4 s, demora inicial de 1,5 s y máximo dos vehículos. A velocidad normal de Player, equivale aproximadamente a un nuevo vehículo cada 920 px si no hay detenciones; durante combates prolongados el presupuesto puede mantenerse lleno. Alternar carril permite esquivarlo y el aviso previo ayuda, pero entre x=4700–6500 puede coincidir con Grandote, Agente o dos Drones. Al iniciar Palermitano el tráfico sí se deshabilita y limpia correctamente.

### Pickups, calor y checkpoint

- El naranjo x=520 precede al combate y comunica bien el arma infinita.
- Los cascotes x=1450 y x=4400 dan hasta 40 disparos de daño alto si se conservan.
- Sánguches x=2800 y x=6200 ofrecen recuperación antes de las dos mitades más exigentes.
- Seis Achilatas alternan carril desde x=3200 hasta x=7200 y reducen exactamente 50 de calor.
- El calor sube 2,1 puntos/s después de x=3200: tarda unos 47,6 s continuos en llegar de 0 a 100. En desplazamiento libre no domina, pero sí penaliza quedarse combatiendo; recoger incluso parte de las seis Achilatas lo mantiene controlable.

La distribución es generosa, pero Achilata x=5400 coincide exactamente con la oleada de dos Drones y Achilata x=7200 cae dentro de la pareja final de Grandotes. Como recoger bloquea controles unos 0,5 s, esas posiciones pueden transformar una ayuda en una exposición involuntaria. El checkpoint x=3600 está sólo 100 px después del trigger de los dos Agentes de x=3500; al respawn se restauran encuentros completados, no el activo, por lo que esa oleada puede reactivarse inmediatamente.

### Plataformas, verticalidad y carriles

Las seis plataformas actuales son one-way y están en carril 0: kiosco x=1650, Auto1 x=1900, parada x=2100, camión x=3100, Auto2 x=5000 y Auto3 x=6700. Aportan saltos y cobertura contra amenazas terrestres, pero la verticalidad sigue concentrada en un solo carril. El carril 1 funciona como vía despejada y de recuperación.

Los dos carriles mantienen Y=370/415 y 45 px de separación. Las bandas tenues del suelo, el feedback de cambio y la sombra de anclaje del Drone mejoran la lectura sin tocar física. Sigue existiendo ambigüedad puntual cuando sprites altos se superponen, pero no justifica rehacer el sistema para cerrar este escenario.

## Palermitano

### Duración y vida

Los **90 HP** son una base razonable, pero producen una duración muy dependiente del inventario:

- Naranjazo: 1 de daño cada 0,25 s; mínimo teórico aproximado de 22,5 s de fuego perfecto, más esquive y cambios de carril.
- Cascotazo: 3 de daño cada 0,25 s; con 30 cascotes conservados el mínimo teórico baja a unos 7,5 s.
- Cinco Tucumanazos conservados pueden aportar 25 de daño adicionales, sujetos a rango y animación.

La duración práctica esperable es **20–45 s** con recursos normales, pero puede bajar notablemente si se guardaron cascotes y especiales o superar ese rango con sólo naranjas y baja precisión. Conviene medir por separado tres loadouts: sin cascotes, recursos medios y recursos completos.

### Patrones y ventanas de castigo

| Patrón | Timing actual | Evaluación |
| --- | --- | --- |
| Triple café | 0,30 s de telegraph; tres tiros cada 0,16 s; 0,55 s de recovery; cooldown 1,80 s | Legible por sí solo. A distancia puede repetirse aproximadamente cada 1,8 s y llenar el carril si además disparan dos Agentes. |
| Summon | 0,48 s de telegraph; 0,70 s de recovery; cooldown 5 s | Ventana de castigo generosa. El máximo de dos Agentes es razonable en una arena limpia. No vuelve a invocar mientras ambos vivan. |
| Cadena | 0,34 s de anticipación; 0,14 s activa; 0,52 s de recovery; cooldown 1,35 s | Tiene telegraph y castigo suficientes. La selección impide repetir cadena consecutivamente. |

El boss permanece vulnerable durante telegraphs y recoveries; por ello existe una oportunidad real de castigo tras los tres patrones. La arena x=7000–7950 ofrece **950 px de ancho mundial**, suficiente para Palermitano + dos Agentes y cambios de carril, especialmente porque el tráfico se limpia. No es suficiente para esa composición más enemigos arrastrados de oleadas anteriores.

## Hallazgos priorizados

### CRÍTICO — 1. Enemigos anteriores pueden entrar al boss

**Evidencia:** todos los encuentros se activan por X de forma independiente. El spawn del Palermitano comprueba únicamente `route_wave_06`; no exige que las otras siete composiciones hayan terminado ni limpia enemigos/proyectiles anteriores.

**Cambio pequeño recomendado:** antes de activar el boss, exigir que los ocho IDs registrados estén completados. Alternativamente, hacer secuencial sólo el tramo x=4100–7000. No limpiar silenciosamente enemigos vivos al llegar al trigger: ocultaría el problema y quitaría recompensas.

### IMPORTANTE — 2. Respawn casi encima de `route_wave_03`

**Evidencia:** trigger x=3500 y checkpoint x=3600. Morir tras activarlo restaura sólo encuentros completados y permite que los dos Agentes reaparezcan inmediatamente alrededor del respawn.

**Cambio pequeño recomendado:** mover el checkpoint antes del trigger, aproximadamente a x=3400, o activarlo sólo después de completar `route_wave_03`. Preferencia: moverlo a x=3400, por ser un ajuste de escena aislado y predecible.

### IMPORTANTE — 3. Densidad sostenida entre x=4700 y x=6500

**Evidencia:** tres encuentros separados 600–700 px, tráfico cada 4 s con presupuesto de dos vehículos y calor activo. Un jugador avanzando a 230 px/s cruza 600 px en unos 2,6 s, menos que un ciclo completo de ataque/limpieza.

**Cambio pequeño recomendado:** después de resolver el bloqueo secuencial, probar tráfico con intervalo **5 s** en toda la ruta. Si la lectura ya resulta suficiente, mantener 4 s; no tocar velocidades ni daños.

### IMPORTANTE — 4. Achilatas dentro de ventanas peligrosas

**Evidencia:** x=5400 coincide con dos Drones y x=7200 con dos Grandotes. La recogida bloquea control durante aproximadamente 0,5 s.

**Cambio pequeño recomendado:** desplazar sólo esas dos Achilatas hacia zonas previas de respiro; candidatos iniciales x=5300 y x=6850, conservando sus carriles actuales. Validar que no se superpongan con plataformas ni otros pickups.

### IMPORTANTE — 5. Duración del boss varía demasiado por recursos guardados

**Evidencia:** 90 HP equivalen teóricamente a 90 naranjas, 30 cascotes o una combinación de 5 Tucumanazos + 22 cascotes. El combate puede sentirse correcto o demasiado corto según conservación de inventario.

**Cambio pequeño recomendado:** no alterar todavía HP. Cronometrar al menos tres intentos por loadout y usar como ventana objetivo **25–45 s**. Sólo después ajustar un único parámetro: HP si cambia la duración global, o cooldown de café si el problema es densidad. Mantener máximo dos summons.

## Pendientes opcionales de pulido

### OPCIONAL — Gameplay/presentación

- Añadir en una tarea futura una plataforma reutilizando contenido existente en carril 1; no es necesaria para cerrar el slice.
- Dar 0,2–0,4 s más de presentación entre la muerte del último Grandote y el primer patrón del boss sólo si el playtest percibe brusca la transición actual de 0,8 s.
- Evaluar `coffee_cooldown` de 1,8 → 2,1 s únicamente si dos Agentes + triple café dejan sistemáticamente menos de una ruta clara de esquive.

### OPCIONAL — Pendientes puramente visuales conocidos

- Cadena de Palermitano reutiliza `boss_punch`; faltan poses específicas de anticipación, golpe y recuperación.
- Summon reutiliza `boss_joke`.
- Triple café reutiliza `boss_cofee`.
- Falta una posible mancha visual de café, sin efecto de gameplay.
- Los disparos verticales y diagonales del Player siguen usando la pose horizontal legacy.

## Orden recomendado de microajustes

1. Impedir entrada al boss con cualquier encuentro anterior pendiente.
2. Reubicar o condicionar checkpoint respecto de `route_wave_03`.
3. Hacer playtest cronometrado completo y del boss con tres loadouts.
4. Sólo si los datos lo justifican, probar tráfico a 5 s y mover las dos Achilatas conflictivas.
5. Resolver arte específico del boss y disparo multidireccional en una fase artística separada.

Ninguno de estos cambios fue implementado durante esta auditoría.
