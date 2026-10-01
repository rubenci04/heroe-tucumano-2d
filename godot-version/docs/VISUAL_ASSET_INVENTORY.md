# Inventario visual runtime — Ruta 38

Auditoría del 27-09-2026. Fuente de verdad: recursos y overrides cargados por el runtime actual. Las dimensiones se midieron sobre PNG; la altura visual usa bounds alfa >0,1 y la escala efectiva. Ciruja idle = 82,74 px = ratio 1,00.

Los rangos aprobados y la clasificación canónica viven en `VISUAL_SCALE_SPEC.md`; no son escalas aplicadas. Este documento conserva mediciones runtime y evidencia de pivots/anchors.

## Personajes y enemigos

| Nombre / archivo representativo | Categoría | Canvas / alfa | Escena → runtime = efectiva | Pivot y ground point | Sockets | Ratio / diagnóstico |
|---|---|---|---|---|---|---|
| Ciruja — `ciruja_idle.png`, `player.tres` | Player | 200×200 / 96×197 | 0,42 → definición 0,42 = 0,42 | sprite centrado, offset (0,−42); nodo actor = pies/Y=370 | muzzle horizontal ±32,−42; arriba 0,−74; diagonales ±26,−68/−24 | 1,000; referencia |
| Hipster — `hipster_scooter0.png`, `hipster.tres` | `COMPOSITE_ENEMY` / enemigo normal | 200×300 / 185×278 | escena genérica 1 → 0,34 = 0,34 | centrado, offset (0,−47,94); nodo = ground | café ±24,−42 | 1,142; ver `VISUAL_SCALE_SPEC.md` |
| Agente — `agente_run0.png`, `agente.tres` | Agente alto | 200×300 / 95×262 | escena genérica 1 → 0,36 = 0,36 | centrado, offset (0,−50,4); nodo = ground | arma ±22,−58 | 1,140; **+0,040 alto** |
| Grandote — `grandote_run1.png`, `grandote.tres` | Grandote | 200×300 / 184×267 | escena genérica 1 → 0,44 = 0,44 | centrado, offset (0,−63,36); nodo = ground | onda ±48,−4; melee desde `AttackDefinition` | 1,420; **+0,200 alto** |
| Drone — `drone_1.png`, `drone.tres` | `AIRBORNE_GAMEPLAY_ENTITY` | 151×151 / 141×87 | escena 1 → 0,55 = 0,55 | centro visual; flight anchor Y=ground−145; sin ground point físico | origen local inferior/aim reticle | 0,578; ver `VISUAL_SCALE_SPEC.md` |
| Grandote miniboss — `grandote_run1.png`, `miniboss_grandote.tscn` | Miniboss | 200×300 / 184×267 | escena 0,48; sin override = 0,48 | centrado, offset (0,−69,12); nodo = ground | hitbox según charge/punch/slam | 1,549; **+0,329 alto**; escena presente sin trigger en JSON actual |
| Palermitano — `final_boss_run1.png`, `palermitano_boss.tscn` | Boss | 200×300 / 160×256 | escena 0,42; sin override = 0,42 | centrado, offset (0,−60,9); nodo = ground | café ±34,−62; cadena offset ±68,−44 | 1,299; **+0,049 alto** |

Body/hurtbox de Player y enemigos genéricos se derivan sólo del primer frame configurado: ancho alfa × escala × `collision_width_ratio`, alto alfa × escala × 0,9. Palermitano usa body 48×92 y el miniboss 62×112. Los offsets por frame sólo mueven el visual.

### Offsets por frame vigentes

- Ciruja Idle: `[-5.5,0]`. Run: `[[-2.5,3],[-4,0],[-3.5,3.5],[-2,-1],[-0.5,0],[-0.5,1],[-2.5,1]]`.
- Hipster Ride: `[[-1.5,3],[1,-1],[2.5,4],[3,8],[-1,2]]`. Shoot Coffee: `[[1.5,0],[2.5,12],[2.5,5],[1,5],[0,6],[0.5,11],[0,13],[-1.5,9]]`.
- Agente Run: `[[-3,13],[-5,8],[4,7],[-5.5,4],[-1.5,11],[-3,13],[-5,8],[4,7]]`. Shoot: `[[9.5,4],[2,7],[0.5,19],[1,9],[0.5,-3]]`.
- Grandote Run: `[[-1.5,8],[-4.5,24],[-0.5,24],[0.5,43],[-0.5,26],[-4.5,23],[-1.5,8],[0,0]]`. Punch y Ground Slam también poseen offsets individuales en `data/animation_manifest.json`; Ground Slam varía entre Y=−5 y Y=44.
- Palermitano Run: `[[6.5,19],[0.5,14],[-0.5,10],[-3.5,15],[-15,10],[-4,9],[0,20]]`. Punch, Coffee, Joke y Order Attack tienen tablas propias; Coffee varía entre X=−12,5…18 e Y=0…23.
- Drone no usa tabla de offsets por frame.

Los arrays usan punto decimal para conservar pares X/Y inequívocos; la fuente exacta machine-readable sigue siendo `data/animation_manifest.json`.

## Vehículos

Todos usan sprite centrado. `platform.gd`/`vehicle.gd` calculan `Visual.position.y = (canvas_h/2 − opaque_bottom) × escala`; el borde opaco inferior coincide con el origen/ground point. El roof socket queda aproximadamente en `−altura_opaca_escalada`.

| Nombre / archivo | Uso | Canvas / alfa | Escena → runtime = efectiva | Ground/roof | Ratio / diferencia |
|---|---|---|---|---|---|
| auto1.png | estacionado X=700 | 189×85 / 182×82 | 1 → 0,90 = 0,90 | bottom alfa / roof automático | 0,892; **+0,072 alto** |
| auto2.png | estacionado X=5450 | 242×106 / 225×93 | 1 → 0,90 = 0,90 | bottom alfa / roof automático | 1,012; **+0,192 alto** |
| auto3.png | estacionado X=2300/3100 | 185×79 / 173×75 | 1 → 0,95 = 0,95 | bottom alfa / roof automático | 0,861; **+0,041 alto** |
| camioneta1.png | estacionada X=1500 | 300×300 / 282×115 | 1 → 0,82 = 0,82 | bottom alfa / roof automático | 1,140; categoría `CAMIONETA_PICKUP`, ver especificación |
| camioneta2.png | estacionada X=3900 | 300×300 / 274×137 | 1 → 0,72 = 0,72 | bottom alfa / roof automático | 1,192; categoría `CAMIONETA_PICKUP`, ver especificación |
| camioneta3.png | estacionada X=6200 | 300×300 / 286×140 | 1 → 0,70 = 0,70 | bottom alfa / roof automático | 1,184; categoría `CAMIONETA_PICKUP`, ver especificación |
| camioneta4.png | estacionada X=6900 | 300×300 / 286×121 | 1 → 0,78 = 0,78 | bottom alfa / roof automático | 1,141; categoría `CAMIONETA_PICKUP`, ver especificación |
| camion_limones.png | estacionado X=4650 | 300×300 / 288×165 | 1 → 0,80 = 0,80 | bottom alfa / roof automático | 1,595; **+0,345 alto** como camión |
| camion_cañas.png | asset sin instancia actual | 300×300 / 288×177 | sin escala runtime | ground estimable por bottom alfa | N/D; requiere decisión futura |
| exprebus.png | set piece | 300×300 / 261×115 | 1 → config 1,20 = 1,20 | bottom alfa / roof móvil | 1,668; **+0,268 alto** |
| tesa.png | set piece | 300×300 / 293×121 | 1 → config 1,10 = 1,10 | bottom alfa / roof móvil | 1,609; **+0,209 alto** |
| Hipster scooter compuesto | actor, no vehículo separable | 200×300 / 185×278 | 1 → 0,34 | usa ground del actor | No comparar con rango Moto: incluye al conductor |

No existe un asset de moto aislada. Aplicar 0,65–0,75 al Hipster completo reduciría también al personaje; se requiere separar conceptualmente vehículo y conductor antes de usar ese rango.

## Pickups y props jugables

| Nombre / archivo | Categoría | Canvas / alfa | Escena → runtime = efectiva | Pivot/ground point | Ratio / diagnóstico |
|---|---|---|---|---|---|
| arbol_naranjas.png | interacción | 182×159 / 176×154 | escena 1 → pickup 0,85 = 0,85 | centrado + bottom alfa; instancia Y=345 | 1,582; rango de pickup no aplicable a árbol |
| montaña_cascote.png | interacción | 197×197 / 195×105 | 1 → 0,32 = 0,32 | bottom alfa = nodo Y=370 | 0,406; tratar como prop, no icono |
| empanada.png | pickup | 199×199 / 115×191 | 1 → 0,14 = 0,14 | bottom alfa; suelo o techo−8 | 0,323; excepción `MINOR` frente a pickup 0,18–0,28 |
| sanguche.png | pickup | 204×115 / 200×84 | 1 → 0,25 = 0,25 | bottom alfa; suelo/techo/bus | 0,254; dentro de pickup 0,18–0,28 |
| achilata.png | pickup suspendido | 205×205 / 129×184 | sin instancia activa; escala histórica 0,18 | ground estimado por bottom alfa | 0,400 histórico; no hay escala runtime vigente |
| parada_colectivo2.png | plataforma roadside | 288×194 / 275×164 | 1 → 0,50 = 0,50 | nodo Y=350; roof manual −78, ancho 110 | 0,991; sin rango de prop aprobado |

Pickups y plataformas generadas por script no tienen sockets de ataque. Los pickups sobre techo usan el socket lógico `roof_world_y − 8`.

## Props ambientales

| Nombre / archivo | Estado | Canvas / alfa | Escala efectiva | Pivot / ground point | Observación |
|---|---|---|---:|---|---|
| cartel_famailla.png | activo | 198×93 / 194×89 | 0,80 | centered, `Vector2(271,288.6)` | sin ground point declarado |
| cañas_solas.png | activo | 511×118 / 485×118 | 0,45 | centered, `Vector2(1180,298.45)` | midground z=−8, sin parallax propio |
| semaforo1.png | activo | 130×182 / 116×164 | 0,70 | centered, `Vector2(3400,263.4)` | ground implícito, z=−2 |
| poste_luz.png | activo | 58×173 / 54×161 | 0,75 | centered, `Vector2(950,264.625)` | ground implícito, z=−2 |
| arbol_comun.png | asset disponible | 183×172 / 169×165 | sin instancia | ambiguo | ya aparece integrado dentro del panorama |
| casa1.png | asset disponible | 243×216 / 243×196 | sin instancia | ambiguo | Visual Lab lo muestra a 1,0 sólo como referencia cruda |
| casa2.png | asset disponible | 260×208 / 250×191 | sin instancia | ambiguo | sin categoría de profundidad runtime |
| kiosco_coca2.png | asset disponible | 208×123 / 204×110 | sin instancia | ambiguo | no invade actualmente el asfalto |
| pilar_cableado.png | asset disponible | 194×522 / 193×483 | sin instancia | ambiguo | canvas/altura extremos; requiere profundidad antes de escalar |

Los props ambientales no tienen sockets. Para los activos, `position`, `scale` y `z_index` de escena son el único contrato; ninguno declara un ground point reutilizable.

## Clasificación canónica

Las desviaciones, rangos de categoría y acciones futuras están centralizados en `VISUAL_SCALE_SPEC.md`. Achilata continúa fuera de clasificación runtime porque no posee instancia activa.

## Contradicciones y valores hardcodeados

1. `WORLD_SCALE_REFERENCE.md` registra Hipster 0,30, Grandote 0,40 y distribuciones vehiculares anteriores; runtime actual usa 0,34, 0,44 y nueve vehículos en otras X.
2. Ese documento también describe Tesa como referencia sin encuentro y café Hipster a 220 px/s; hoy Tesa tiene set piece y `hipster_coffee.tres` usa otro balance.
3. `data/enemies/boss.tres` contiene parámetros legacy del enemigo genérico, mientras Palermitano final usa script/escena dedicados.
4. Player y actores genéricos reciben escala desde recursos; Palermitano/miniboss desde escena; vehículos desde arrays/configs; props desde escena o llamadas hardcodeadas.
5. Muzzle offsets están hardcodeados en `player.gd`, `enemy.gd` y `palermitano_boss.gd`, no en el manifiesto visual.
6. El roof de la parada usa ancho 110 y offset −78 manuales; otros techos se derivan automáticamente de alfa.
7. Cartel, cañas, semáforo y poste usan posiciones Y manuales sin ground metadata.
8. `animation_manifest.json` corrige jitter visual por frame, pero collider/hurtbox permanece basado en un único frame.
9. Las casas, kiosco, pilar, árbol común y camión de cañas existen como assets pero carecen de escala/categoría runtime actual.
10. La escala 1,0 usada para esos assets en Visual Lab es una referencia cruda explícita, no un valor propuesto de integración.

## Decisiones resueltas en paso 4

Camionetas tienen la categoría independiente `CAMIONETA_PICKUP`; pickups usan 0,18–0,28; Drone es `AIRBORNE_GAMEPLAY_ENTITY`; Hipster + scooter es `COMPOSITE_ENEMY`; los props se clasifican por profundidad. Ver `VISUAL_SCALE_SPEC.md` para excepciones y casos `N/A`.
