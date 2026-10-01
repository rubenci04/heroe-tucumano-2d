# Especificación canónica de escala visual — Ruta 38

Estado: aprobada para clasificación y para un futuro paso de corrección visual. No autoriza cambios runtime en esta fase.

## Método de medición

La comparación se hace con la **altura visual efectiva opaca**: altura del bounding box alfa del frame representativo × escala efectiva runtime. No se usa el canvas completo, porque sus márgenes transparentes falsearían el resultado.

Registrar siempre, por separado: dimensiones de textura, canvas transparente, bounds opacos, escala de escena, override de runtime y altura visual efectiva. La fuente de valores actuales es `VISUAL_ASSET_INVENTORY.md`; recursos y escenas runtime prevalecen sobre `WORLD_SCALE_REFERENCE.md` histórico.

`PLAYER = 1,00` es Ciruja idle: 82,74 px opacos a escala runtime.

Clasificación de desviación para el futuro paso 5: **OK** dentro del rango; **MINOR** hasta 0,05 fuera; **MODERATE** >0,05 y hasta 0,15; **MAJOR** >0,15. Los assets sin escala runtime o sin categoría comparable quedan `N/A`, no se fuerzan a un ratio.

## Personajes y entidades de gameplay

| Categoría | Ratio objetivo | Asset actual | Ratio actual | Estado | Acción futura |
|---|---:|---|---:|---|---|
| PLAYER | 1,00 | Ciruja | 1,000 | OK | Referencia; no corregir automáticamente. |
| NORMAL_ENEMY | 0,95–1,05 | Hipster + scooter | 1,142 | MODERATE | Revisar escala del compuesto como enemigo, sin separar rider/scooter. |
| AGENT | 1,05–1,10 | Agente | 1,140 | MINOR | Ajuste visual fino si la lectura lo requiere. |
| GRANDOTE | 1,15–1,22 | Grandote común | 1,420 | MAJOR | Reducir sólo en un futuro paso visual validado. |
| GRANDOTE_MINIBOSS | 1,25–1,35 | Grandote miniboss | 1,549 | MAJOR | Revisar si vuelve a entrar en contenido activo; actualmente no tiene trigger JSON. |
| BOSS | 1,15–1,25 | Palermitano | 1,299 | MINOR | Mantener presencia de boss; revisar sólo con captura comparativa. |
| AIRBORNE_GAMEPLAY_ENTITY | 0,40–0,55 | Drone | 0,578 | MINOR | Ajustar sólo si perjudica lectura aérea. |

### Drone y enemigos compuestos

Drone es `AIRBORNE_GAMEPLAY_ENTITY`: no tiene `GROUND_POINT` tradicional. Su pivot debe ser un anchor aéreo estable, independiente de la ground line del Player.

Hipster + scooter es `COMPOSITE_ENEMY`. El rango de Moto no se aplica al sprite entero, pues también reduciría al conductor. No se separa ni se regenera arte en esta fase; una futura versión de arte puede exponer `rider` y `vehicle` como piezas independientes.

## Vehículos

| Categoría | Ratio objetivo | Asset actual | Ratio actual | Estado | Acción futura |
|---|---:|---|---:|---|---|
| AUTO | 0,72–0,82 | auto1 | 0,892 | MODERATE | Reducir visualmente tras validar techo/plataforma. |
| AUTO | 0,72–0,82 | auto2 | 1,012 | MAJOR | Reducir visualmente tras validar techo/plataforma. |
| AUTO | 0,72–0,82 | auto3 | 0,861 | MINOR | Ajuste fino opcional. |
| CAMIONETA_PICKUP | 0,85–0,95 | camioneta1 | 1,140 | MAJOR | Reducir visualmente tras validar techo/plataforma. |
| CAMIONETA_PICKUP | 0,85–0,95 | camioneta2 | 1,192 | MAJOR | Reducir visualmente tras validar techo/plataforma. |
| CAMIONETA_PICKUP | 0,85–0,95 | camioneta3 | 1,184 | MAJOR | Reducir visualmente tras validar techo/plataforma. |
| CAMIONETA_PICKUP | 0,85–0,95 | camioneta4 | 1,141 | MAJOR | Reducir visualmente tras validar techo/plataforma. |
| CAMION | 1,10–1,25 | camion_limones | 1,595 | MAJOR | Reducir visualmente conservando la lectura pesada. |
| COLECTIVO | 1,28–1,40 | Expresbus | 1,668 | MAJOR | Reducir visualmente sin cambiar mecánica/techo. |
| COLECTIVO | 1,28–1,40 | Tesa | 1,609 | MAJOR | Reducir visualmente sin cambiar mecánica/techo. |
| MOTO | 0,65–0,75 | scooter Hipster | N/A | N/A | No hay asset de moto aislado. |
| CAMION | 1,10–1,25 | camion_cañas | N/A | N/A | Sin instancia runtime: clasificar cuando se integre. |

Los vehículos actuales usan ruedas/base como `GROUND_POINT`; su roof line y collider de plataforma son contratos de gameplay separados de la escala visual.

## Pickups

Los pickups priorizan reconocimiento y silueta, no escala física del mundo. Su rango general es 0,18–0,28 de la altura opaca efectiva de Ciruja.

| Asset | Ratio actual | Estado | Acción futura |
|---|---:|---|---|
| empanada | 0,323 | MINOR | Documentar o ajustar como excepción por legibilidad. |
| sanguche | 0,254 | OK | Conservar como referencia del rango. |
| achilata | 0,400 histórico | N/A | Pickup suspendido sin instancia runtime; decidir sólo al reactivarlo. |

Naranja, cascote y demás pickups sin medición runtime en el inventario se clasifican por esta misma regla cuando entren al laboratorio. Un pickup que exceda el rango por legibilidad se documenta como excepción; no se amplía el rango global.

## Ground points y profundidad

| Clase de profundidad | Assets/uso actual | Regla |
|---|---|---|
| GAMEPLAY_GROUND | parada, poste cercano, semáforo, cartel/señales y objetos apoyados en banquina | Deben declarar o derivar `GROUND_POINT`: ruedas, base o apoyo estructural. |
| MIDGROUND | cañas, vegetación, construcciones y postes alejados | No deben tocar la ground line del Player; se colocan por perspectiva. |
| BACKGROUND | cerros, cielo, paisaje integrado y árbol integrado al panorama | Sin `GROUND_POINT` gameplay. |
| FOREGROUND | oclusión excepcional futura | No se normaliza por altura del jugador ni debe tapar amenazas/UI. |

Clasificación actual verificable: `parada_colectivo2`, `cartel_famailla`, `semaforo1` y `poste_luz` son `GAMEPLAY_GROUND`; `cañas_solas` es `MIDGROUND`; `arbol_comun` integrado al panorama es `BACKGROUND`. `casa1`, `casa2`, `kiosco_coca2` y `pilar_cableado` no tienen instancia runtime: quedan `UNASSIGNED` hasta una colocación concreta.

## Excepciones y límites conocidos

- `arbol_naranjas` y `montaña_cascote` son objetos de interacción/prop, no pickups iconográficos: no se comparan contra el rango de pickup.
- La parada tiene roof manual; los demás techos de vehículo se derivan de bounds alfa.
- Los props activos aún usan posiciones Y de escena y no metadata reutilizable de ground point. La formalización de ese contrato corresponde a un paso posterior.
- Los colliders de actores genéricos se derivan del primer frame; los offsets por frame mueven sólo el visual. Ninguna decisión de ratio autoriza cambiar hitboxes.

## Impacto para el futuro paso 5

Los assets con acción de escala futura son exactamente los marcados `MINOR`, `MODERATE` o `MAJOR` en las tablas anteriores. Los casos `N/A` requieren una decisión de integración, no una corrección de tamaño. Cualquier corrección deberá validarse en Visual Lab y preservar grounding, roofs, colliders y gameplay antes de entrar al nivel.
