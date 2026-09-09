# Auditoría del sistema de carriles — Ruta 38

Fecha: 2026-09-07. Alcance: inspección de solo lectura del runtime Godot actual. No se modificaron escenas, datos, colisiones ni gameplay.

## Diagnóstico actual

Ruta 38 usa dos carriles físicos definidos por `GameConfig.LANES`:

| Carril | Y de suelo | Uso visual |
| --- | ---: | --- |
| 0 | 370 | plano trasero/superior |
| 1 | 415 | plano delantero/inferior |

La separación es de **45 px**. El Player legacy mide aproximadamente 80–84 px de alto visual en Idle/Run a 800×450, por lo que las siluetas de ambos carriles se solapan visualmente con frecuencia. El `z_index` usa el valor Y del carril, por lo que el carril 1 queda por delante; esto conserva profundidad, pero no elimina la ambigüedad cuando sprites, pickups o proyectiles se cruzan en pantalla.

Cada carril tiene un `StaticBody2D` de suelo propio y una capa física propia (`1 << lane`). Player cambia su `collision_mask`, `Hurtbox` y `lane_index` al terminar la transición; enemigos, pickups, plataformas, tráfico y proyectiles reciben o validan el mismo índice. El contrato evita golpes y colisiones cruzadas, no es sólo decorativo.

## Cambio de carril del Player

- Entradas: `lane_up` / `lane_down` (flechas/W-S, D-pad/stick vertical).
- Sólo inicia estando en suelo, cerca de la altura del carril, sin proyectil recién solicitado, salto, muerte, recogida, Tucumanazo o transición previa.
- Duración: 0,20 s. La trayectoria interpola entre Y y añade un arco visual de 20 px.
- Durante la transición se desactiva temporalmente `collision_mask`; al finalizar se actualizan `lane_index`, `Hurtbox` y máscara del nuevo carril.

Es una respuesta ágil de arcade, pero la misma dirección vertical también se usa para apuntar proyectiles. El bloqueo sólo evita que un input de disparo dispare a la vez un cambio de carril; el jugador debe aprender esta prioridad contextual.

## Contenido por carril

### Encuentros

| Encuentro | X de activación | Carril 0 | Carril 1 |
| --- | ---: | --- | --- |
| `route_wave_01` | 900 | Hipster (+550) | Hipster (-180) |
| `route_wave_02` | 2200 | Hipster (-180) | Agente (+550) |
| `route_wave_03` | 3500 | Agente (+550) | Agente (-180) |
| `route_drone_01` | 4100 | Drone (+500) | — |
| `route_wave_04` | 4700 | Agente (-180) | Grandote (+550) |
| `route_drone_02` | 5400 | Drone (+550) | Drone (-180) |
| `route_drone_03` | 6100 | Drone (+550) | Agente (-180) |
| `route_wave_06` | 7000 | Grandote (-180) | Grandote (+550) |

Los enemigos terrestres se instancian sobre `GameConfig.LANES[lane]`. En sus definiciones actuales `can_change_lanes` no está habilitado: cada uno conserva el carril configurado. Esto genera decisiones reales de prioridad, porque un enemigo de rango sólo puede dañar al Player cuando comparten carril.

### Pickups

| Tipo | Carril y posiciones X |
| --- | --- |
| Naranjo | carril 0: 520 |
| Cascotes | carril 0: 1450, 4400 |
| Sánguche | carril 1: 2800, 6200 |
| Empanadas | alternan: 240/0, 750/1, 1350/0, 2000/1, 2700/0, 3400/1, 4100/0, 4900/1, 5600/0, 6300/1, 7000/0, 7500/1 |
| Achilatas | alternan: 3200/0, 3600/1, 4300/0, 5400/1, 6500/0, 7200/1 |

La distribución alternada de empanadas y Achilatas sí invita al cambio de carril. En cambio, el naranjo y ambos suministros de cascotes están sólo en carril 0: es una asimetría funcional temprana.

### Plataformas

Todas las plataformas existentes son de **carril 0** y tienen solamente un techo `one-way`:

| Plataforma | X | Escala / techo útil |
| --- | ---: | --- |
| Auto1 estacionario | 1900 | 0,84; techo 124,32 px |
| Camión de limones | 3100 | 1,25; techo 190 px |
| Auto2 estacionario | 5000 | 1,10 |
| Auto3 estacionario | 6700 | 0,95 |
| Kiosco POC | 1650 | 0,72; techo útil 112 px |
| Parada POC | 2100 | 0,62; techo útil 94 px |

Esto da al carril 0 el único espacio vertical de salto, mientras carril 1 funciona hoy como suelo libre. Las plataformas no bloquean el carril opuesto y se atraviesan desde abajo.

### Tráfico

`TrafficDirector` opera entre X=1400 y X=6500, con máximo dos vehículos activos. Alterna carril por índice de spawn y alterna dirección; ningún asset pertenece de forma permanente a un carril. El vehículo hereda el carril asignado en su `Hitbox`, causa daño sólo allí y se despawnea al salir del margen de cámara. Es una decisión táctica clara: cambiar de carril evita un vehículo, pero puede colocar al Player ante el enemigo o pickup correspondiente.

### Drones

Un Drone se ancla a `GameConfig.LANES[lane] - 145`: Y=225 para carril 0 y Y=270 para carril 1. No tiene gravedad, floor snap ni cambio de carril terrestre. Aunque se vea elevado, conserva `lane_index`: su mira y su proyectil `drone_bolt` quedan asociados al carril del Drone. El Player puede dañarlo con disparo vertical/diagonal **sólo desde el mismo carril**. Esto es coherente con el contrato actual, pero no es visualmente obvio porque el Drone flota entre/encima de los planos terrestres.

### Proyectiles y ataques

- Player, Agente, Hipster y Drone propagan `lane_index` al proyectil.
- El proyectil combina la máscara de equipo con `1 << lane_index`; `Hurtbox.can_receive_attack` vuelve a validar el carril.
- Naranjazo/Cascotazo multidireccionales mantienen el carril original incluso cuando viajan en vertical o diagonal; no cambian de carril durante el vuelo.
- Tucumanazo, melee y onda rasante también se limitan al carril de activación.
- Las plataformas sólidas del carril coincidente consumen proyectiles; el carril opuesto las ignora.

## Valor táctico actual

Decisiones que funcionan:

- Cambiar para esquivar tráfico sin alterar su velocidad ni daño.
- Elegir carril para alcanzar un pickup alternado, sobre todo Achilata y empanadas.
- Separar un Agente/Hipster de su línea de tiro y volver para atacarlo.
- Priorizar enemigos en carriles distintos; las oleadas de dos Drones obligan a seleccionar objetivo y carril.
- Usar el techo del carril 0 para saltar sobre una amenaza terrestre o rasante.

Fricciones y confusión:

- 45 px es poca separación frente a la altura del personaje: el carril correcto no siempre se lee al primer vistazo.
- Drones, por altura visual, parecen potencialmente atacables desde ambos carriles, pero no lo son.
- Plataformas, naranjo y cascotes favorecen el carril 0; el carril 1 tiene menos variedad espacial.
- El input vertical sirve tanto para carril como para apuntado. El bloqueo contextual evita conflictos técnicos, pero no hace visible la regla.
- Los encuentros se activan por X y no por completar el anterior; si el jugador avanza sin limpiar, puede acumular amenazas. La separación de encuentros reciente reduce el riesgo, pero no lo elimina como propiedad del director.

## Alternativas para el primer escenario

| Opción | Impacto técnico y de contenido | Riesgo | Beneficio jugable |
| --- | --- | --- | --- |
| Mantener 2 carriles | Player, `Hitbox/Hurtbox`, proyectiles, plataformas, tráfico, Drone y `EncounterDirector` ya soportan exactamente dos índices. Sólo requeriría ajustes de presentación/datos puntuales. Tests actuales cubren el contrato. | Bajo | Movilidad inmediata y arcade; decisiones legibles si se mejora la señalización. |
| Pasar a 3 carriles | Cambiar `GameConfig.LANES`, Y de suelos, salto/cambio, orden de capas, cada spawn/pickup/plataforma, tráfico, Drone, máscaras y validación de encuentros. Reescribir expectativas y ampliar humo/profile para tercer carril. | Alto | Más espacio para evasión y composición, pero con 800×450 cada carril quedaría aún más comprimido o exigiría recomponer perspectiva. |
| Un solo carril | Eliminar transición y capas por carril de Player, enemigos, proyectiles, plataformas, tráfico, Drone y EncounterDirector; rehacer masks, datos y casi todos los asserts. | Alto | Lectura máxima y combate más directo, a costa de perder la principal maniobra defensiva y parte de la identidad arcade actual. |

### Impacto por subsistema

| Subsistema | 2 carriles | 3 carriles | 1 carril |
| --- | --- | --- | --- |
| Player | Sin cambio de contrato | Tercer destino, transición y feedback | Quitar transición/input vertical contextual |
| Enemigos y Drone | Datos actuales reutilizables | Nuevos spawns y validaciones 0–2 | Eliminar separación táctica de objetivos |
| Proyectiles | Máscaras actuales correctas | Máscaras y tests de tercer bit | Simplificar máscara, rehacer reglas de impacto |
| Plataformas | Añadir variedad al carril 1 | Definir distribución y Y de tres techos | Unificar suelos/techos y colisiones |
| Tráfico | Alternancia actual suficiente | Rebalancear frecuencia y trazas | Pierde vía de evasión lateral/vertical |
| EncounterDirector | Datos vigentes | Validación y composición de 3 carriles | Migrar todos los spawns a carril único |
| Tests | Mantener y ampliar visualmente | Refactor amplio de smoke/profile | Refactor amplio de smoke/profile |

## Recomendación

**Mantener dos carriles para cerrar el primer escenario.** Es la única alternativa de bajo riesgo que conserva una movilidad arcade distintiva sin rehacer sistemas ya validados. El problema no es el contrato físico, sino su lectura visual y la concentración de contenido espacial en carril 0.

Mejoras visuales simples, sin cambiar lógica:

1. Diferenciar el suelo delantero con un valor/contraste ligeramente mayor y una franja de sombra/oclusor bajo los personajes del carril 1.
2. Añadir marcas ambientales repetibles de profundidad (bordillo, línea de asfalto, sombras de postes) que conecten inequívocamente cada Y de carril.
3. Mostrar un indicador breve y diegético de carril al completar el cambio: polvo/sombra en el suelo de destino, no HUD permanente.
4. Dar a los Drones una sombra o línea de anclaje tenue hacia su carril objetivo para comunicar que su disparo no cruza de plano.
5. Introducir en una futura tarea visual al menos una plataforma o prop saltable de carril 1 para equilibrar lectura espacial, sin cambiar el contrato de plataformas.

Estas propuestas son art-direction/presentación; no se implementaron aquí.
