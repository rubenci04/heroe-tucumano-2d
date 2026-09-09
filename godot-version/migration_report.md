# Informe de migración — Tucumán Rush

## Estado de la entrega

Proyecto Godot 4 jugable creado exclusivamente dentro de `godot-version`. Los archivos HTML/JS, servidor, .gitignore raíz y todos los PNG originales permanecen intactos. El conflicto Git previo de `main.js` no se resolvió ni modificó.

- 100 PNG copiados byte por byte, con nombres, espacios, acentos y duplicados conservados.
- 22 animaciones Phaser extraídas y ocho acciones/estados nativos: **30 definiciones de actores**.
- Una biblioteca adicional representa cada PNG como una pose AnimatedSprite2D: **100 poses estáticas**.
- 11 WAV nativos derivados de AudioSFX, conservando además su fuente JavaScript y parámetros.
- Jugador/enemigos CharacterBody2D; formas automáticas, plataformas, proyectiles, objetos, oleadas, HUD, calor y primer final.
- No se generaron sprites, ilustraciones, fuentes ni tiles nuevos. Barras/textos son controles nativos; capturas son evidencia de ejecución.

## Dirección artística y recorrido

Se conserva el hincha de San Martín de Tucumán, vista lateral y filtrado nearest para una presentación arcade inspirada en Neo Geo/SNK. No se importaron assets de Metal Slug ni se reemplazó el arte existente.

El archivo real **`assets/fusion_fondos.png`** mide 8000×697. Se usa con proporciones nativas, desplazado verticalmente y recortado por el viewport de 800×450. Los suelos y props complementan el panorama. Los cerros tienen Parallax2D.

Orden confirmado: **Famaillá → Acheral → Monteros → León Rougés → Villa Quinteros → Río Seco**. Los umbrales 0, 1400, 2800, 4200, 5400 y 6600 son provisionales de diseño; no representan kilómetros ni garantizan coincidencia exacta con límites pintados en el panorama. Se editan en `scenes/levels/route_38_data.json`.

La batalla final se activa después de x=7300, en Río Seco. Al agotar sus 90 puntos, el jefe concede una recompensa única, escapa corriendo y se anuncia el **Ingenio Arcor**. El interior de la fábrica queda para el nivel 2; no se construyó ni se anuncia como jugable.

## Animaciones y material disponible

Los originales son PNG individuales, **no sprite sheets con grilla**. Los importadores agrupan cuadros y crean SpriteFrames, sin inventar cortes ni recomprimir los originales. Los cuadros adicionales se incorporan al jugador; se conserva también la definición histórica.

| Estado/acción | Cuadros existentes | Resultado |
|---|---|---|
| Idle | ciruja_idle | Una pose. |
| Run | ciruja_run0–5 | Seis cuadros a 12 FPS; conserva el duplicado del original. |
| Jump | ciruja_salto1–4 | Cuatro cuadros a 8 FPS; aterrizaje por física. |
| Throw Orange | ciruja_disparo_naranja0–5 | Seis cuadros a 24 FPS. |
| Throw Stone | ciruja_disparo_cascote0–4 | Cinco cuadros a 20 FPS. |
| Headbutt | ciruja_cabezazo0–2 | Tres cuadros a 12 FPS durante Furia Milanesa. |
| Hit | ciruja_idle | **Provisional:** cuadro existente con tinte/retroceso; no hay arte dedicado de golpe. |
| Death | ciruja_idle | **Provisional:** cuadro existente con color/rotación; no hay arte dedicado de muerte. |

Enemigos y objetos visuales usan AnimatedSprite2D. Fondos continuos usan Sprite2D/Parallax2D. Los saltos de enemigos y acciones adicionales del jefe permanecen en SpriteFrames aunque la IA actual no los reproduzca.

## Física, cámara y colisiones

- CharacterBody2D y `move_and_slide` para jugador/enemigos, gravedad 1300 px/s², velocidad normal 230 px/s e impulso de salto 580 px/s.
- Dos suelos físicos en capas independientes, Y=370 y Y=415. Cuerpos anclados a los pies; la vista no fuerza a los personajes fuera de su carril.
- Camera2D con seguimiento suave a velocidad 5 y límites del mapa.
- CollisionFactory calcula límites a partir de alfa >0.1 y genera CollisionShape2D rectangulares con márgenes. No es una colisión por píxel ni un ajuste artístico manual.
- El cambio de carril suspende temporalmente la máscara de terreno y activa la del destino al llegar. El salto no termina por un temporizador artificial.
- Cuatro vehículos estacionados: StaticBody2D con techo unidireccional derivado del PNG. Los props puramente decorativos no bloquean el recorrido.
- Objetos/proyectiles: Area2D con formas generadas. Los proyectiles añaden un barrido de trayectoria, y filtran por equipo y carril.

| Proyectil | Asset | Daño | Velocidad |
|---|---|---:|---:|
| Naranja | naranja.png | 1 | 560 px/s |
| Piedra | cascote.png | 3 | 700 px/s |
| Botella | botella_agua.png | 1 | 270 px/s |
| Café especial del jefe | cofee.png | 1 | 360 px/s |
| Bala del agente | bala.png | 1 | 190 px/s |

Jugador: 3 de salud, 3 vidas, 0,8 s de invulnerabilidad y Furia Milanesa de 10 s. Enemigos normales: 3/5/10 de salud. El jefe tiene 90 y un estado terminal de escape que impide recompensas repetidas.

## HUD y coleccionables

El HUD está en CanvasLayer: salud verde, vidas, puntaje, monedas, localidad, munición, calor y barra roja del jefe.

**Monedas:** el original no contiene una moneda dibujada. Cada empanada suma 25 puntos y una unidad al contador MONEDAS. Es una equivalencia provisional explícita; no se inventó un sprite ni una economía de tienda.

El naranjo inicial desbloquea naranjas ilimitadas. Cada pila agrega 20 piedras a un inventario independiente. El sánguche cura, recupera hasta una vida y activa Furia Milanesa. La achilata enfría 50 puntos y suma 100 puntos, sin curar salud.

Insolación: 2,1 puntos por segundo después de x=3200 (equivalente al HTML a 60 FPS). Al llenarse, intenta dañar cada dos segundos. El valor aparece en el HUD; tinte de calor y sol animado originales quedan pendientes.

## Audio

WAV mono PCM de 16 bits a 44,1 kHz, derivados del tipo de oscilador, frecuencias, rampas, ganancia y duración originales. La síntesis usa armónicos limitados y fundidos cortos: **no es idéntica bit a bit al audio del navegador**. La equivalencia auditiva fina requiere revisión humana.

Godot reproduce WAV con AudioStreamPlayer. JavaScript queda como fuente de conversión/herramienta; no es necesario para ejecutar el juego.

## Pendientes y diferencias con Phaser

Esta entrega es un prototipo Godot jugable, **no una declaración de paridad completa ni un juego terminado**.

1. Cuadros dedicados de Hit y Death: necesitan material adicional existente; no se generó arte.
2. Cinemática de secuestro y diálogos originales: imágenes preservadas, secuencia pendiente.
3. Tráfico dinámico, averías, daño de buses, transporte sobre vehículos móviles y su salida: pendientes. Los estacionados sí tienen techos físicos.
4. IA avanzada, ráfaga doble original del agente, rutinas exactas del jefe y saltos de enemigos: pendientes. La IA actual es funcional y simplificada.
5. El cabezazo es frontal con daño y animación, sin replicar aún su desplazamiento completo original.
6. Jefe: recompensa terminal de 1500, sin los 60 puntos por unidad de daño del HTML. Las monedas reutilizan empanadas.
7. Umbrales de localidades, colisiones y balance necesitan playtesting. La nueva física corrige carriles, anclajes y límites; no reproduce los bugs originales.
8. Música, sonidos nuevos, moneda dibujada, tilesets nuevos, shaders personalizados, controles táctiles y gamepad: no agregados.
9. Interior del Ingenio Arcor (nivel 2), guardado persistente y exportaciones finales: pendientes.

## Regeneración y conservación

Consultar README.md. Godot 4.7.2 fue utilizado para validar. Node 22/24 se necesita únicamente para herramientas. La reimportación lee la carpeta original padre y escribe solo en godot-version, regenerando PNG copiados, SpriteFrames, manifiestos y WAV; no modifica scripts jugables ni el HTML. La versión Godot ya generada puede copiarse y ejecutarse de forma independiente.

Se conservaron los dos pares idénticos: ciruja_run0 = ciruja_run3, y ciruja_disparo_naranja0 = ciruja_disparo_naranja2. También se conservaron los 19 PNG que Phaser no cargaba.

## Validación realizada

- Motor: **4.7.2-stable (official)**; Compatibility/OpenGL.
- Integridad: **104 originales** y **100 copias PNG**; SHA-256 correctos.
- Integración: **185 comprobaciones**, correctas.
- Recursos, movimiento, recolección, impactos reales y exclusión de carril opuesto, salto, piso inferior, techo unidireccional, cinco proyectiles y caducidad.
- Inventario separado, monedas, pausa, galería, calor a 30/60/120 actualizaciones, achilata, recompensa única, escape, muerte y game over.
- Capturas con render real en validation. No se exportó ejecutable ni se midió rendimiento sostenido en todos los dispositivos.

## Archivo por archivo

Inventario de entregables y evidencias presentes al generar el informe. Los PNG, .import y .uid se documentan individualmente.

| Archivo | Responsabilidad |
|---|---|
| `.gitignore` | Excluye caché .godot y capturas/logs de validación del control de versiones local. |
| `README.md` | Inicio rápido, controles y comandos para regenerar/verificar la migración. |
| `assets/achilata.png` | Coleccionable. Copia exacta 200×230; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/achilata.png.import` | Metadatos Godot de assets/achilata.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/agente_disparo_bala1.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/agente_disparo_bala1.png.import` | Metadatos Godot de assets/agente_disparo_bala1.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/agente_disparo_bala2.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/agente_disparo_bala2.png.import` | Metadatos Godot de assets/agente_disparo_bala2.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/agente_run1.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/agente_run1.png.import` | Metadatos Godot de assets/agente_run1.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/agente_run2.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/agente_run2.png.import` | Metadatos Godot de assets/agente_run2.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/agente_run3.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/agente_run3.png.import` | Metadatos Godot de assets/agente_run3.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/agente_salto.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/agente_salto.png.import` | Metadatos Godot de assets/agente_salto.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/animations/agente.tres` | SpriteFrames de carrera, salto y disparo del agente. |
| `assets/animations/asset_library.tres` | 100 animaciones de un cuadro, una por cada PNG; permite conservar también variantes sin uso jugable. |
| `assets/animations/boss.tres` | SpriteFrames de carrera, salto, puñetazo, burla y café del jefe. |
| `assets/animations/grandote.tres` | SpriteFrames de carrera, salto y puñetazo del grandote. |
| `assets/animations/hipster.tres` | SpriteFrames de carrera, salto y lanzamiento del hipster. |
| `assets/animations/native_animation_manifest.json` | Ocho estados/acciones añadidos y documentación de los reemplazos provisionales de Hit y Death. |
| `assets/animations/player.tres` | Ocho animaciones históricas y ocho acciones/estados nativos. Incluye cuadros completos de carrera, salto y lanzamientos. |
| `assets/arbol_naranjas.png` | Escenografía/indicador. Copia exacta 182×159; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/arbol_naranjas.png.import` | Metadatos Godot de assets/arbol_naranjas.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/asset_manifest.json` | Inventario de los 100 PNG: tamaño, dimensiones, SHA-256, uso en Phaser y 22 animaciones originales. |
| `assets/auto1.png` | Vehículo. Copia exacta 186×83; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/auto1.png.import` | Metadatos Godot de assets/auto1.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/auto2.png` | Vehículo. Copia exacta 200×60; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/auto2.png.import` | Metadatos Godot de assets/auto2.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/auto3.png` | Vehículo. Copia exacta 200×85; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/auto3.png.import` | Metadatos Godot de assets/auto3.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/bala.png` | Proyectil. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/bala.png.import` | Metadatos Godot de assets/bala.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/botella_agua.png` | Proyectil. Copia exacta 139×149; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/botella_agua.png.import` | Metadatos Godot de assets/botella_agua.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/bus1.png` | Vehículo. Copia exacta 189×81; preservada aunque Phaser no la cargaba. También disponible como pose AnimatedSprite2D. |
| `assets/bus1.png.import` | Metadatos Godot de assets/bus1.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/bus2.png` | Vehículo. Copia exacta 200×80; preservada aunque Phaser no la cargaba. También disponible como pose AnimatedSprite2D. |
| `assets/bus2.png.import` | Metadatos Godot de assets/bus2.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/bus3.png` | Vehículo. Copia exacta 191×76; preservada aunque Phaser no la cargaba. También disponible como pose AnimatedSprite2D. |
| `assets/bus3.png.import` | Metadatos Godot de assets/bus3.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/bus4.png` | Vehículo. Copia exacta 189×76; preservada aunque Phaser no la cargaba. También disponible como pose AnimatedSprite2D. |
| `assets/bus4.png.import` | Metadatos Godot de assets/bus4.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/camion_limones.png` | Vehículo. Copia exacta 190×88; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/camion_limones.png.import` | Metadatos Godot de assets/camion_limones.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/campeona empanadas.png` | Cinemática. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/campeona empanadas.png.import` | Metadatos Godot de assets/campeona empanadas.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/cartel_famailla.png` | Escenografía/indicador. Copia exacta 200×94; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/cartel_famailla.png.import` | Metadatos Godot de assets/cartel_famailla.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/cascote.png` | Proyectil. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/cascote.png.import` | Metadatos Godot de assets/cascote.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja comiendo.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja comiendo.png.import` | Metadatos Godot de assets/ciruja comiendo.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_cabezazo0.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_cabezazo0.png.import` | Metadatos Godot de assets/ciruja_cabezazo0.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_cabezazo1.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_cabezazo1.png.import` | Metadatos Godot de assets/ciruja_cabezazo1.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_cabezazo2.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_cabezazo2.png.import` | Metadatos Godot de assets/ciruja_cabezazo2.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_disparo_cascote0.png` | Jugador o acción del jugador. Copia exacta 200×200; preservada aunque Phaser no la cargaba. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_disparo_cascote0.png.import` | Metadatos Godot de assets/ciruja_disparo_cascote0.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_disparo_cascote1.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_disparo_cascote1.png.import` | Metadatos Godot de assets/ciruja_disparo_cascote1.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_disparo_cascote2.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_disparo_cascote2.png.import` | Metadatos Godot de assets/ciruja_disparo_cascote2.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_disparo_cascote3.png` | Jugador o acción del jugador. Copia exacta 200×200; preservada aunque Phaser no la cargaba. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_disparo_cascote3.png.import` | Metadatos Godot de assets/ciruja_disparo_cascote3.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_disparo_cascote4.png` | Jugador o acción del jugador. Copia exacta 200×200; preservada aunque Phaser no la cargaba. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_disparo_cascote4.png.import` | Metadatos Godot de assets/ciruja_disparo_cascote4.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_disparo_naranja0.png` | Jugador o acción del jugador. Copia exacta 200×200; preservada aunque Phaser no la cargaba. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_disparo_naranja0.png.import` | Metadatos Godot de assets/ciruja_disparo_naranja0.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_disparo_naranja1.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_disparo_naranja1.png.import` | Metadatos Godot de assets/ciruja_disparo_naranja1.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_disparo_naranja2.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_disparo_naranja2.png.import` | Metadatos Godot de assets/ciruja_disparo_naranja2.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_disparo_naranja3.png` | Jugador o acción del jugador. Copia exacta 200×200; preservada aunque Phaser no la cargaba. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_disparo_naranja3.png.import` | Metadatos Godot de assets/ciruja_disparo_naranja3.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_disparo_naranja4.png` | Jugador o acción del jugador. Copia exacta 200×200; preservada aunque Phaser no la cargaba. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_disparo_naranja4.png.import` | Metadatos Godot de assets/ciruja_disparo_naranja4.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_disparo_naranja5.png` | Jugador o acción del jugador. Copia exacta 200×200; preservada aunque Phaser no la cargaba. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_disparo_naranja5.png.import` | Metadatos Godot de assets/ciruja_disparo_naranja5.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_idle.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_idle.png.import` | Metadatos Godot de assets/ciruja_idle.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_run0.png` | Jugador o acción del jugador. Copia exacta 200×200; preservada aunque Phaser no la cargaba. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_run0.png.import` | Metadatos Godot de assets/ciruja_run0.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_run1.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_run1.png.import` | Metadatos Godot de assets/ciruja_run1.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_run2.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_run2.png.import` | Metadatos Godot de assets/ciruja_run2.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_run3.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_run3.png.import` | Metadatos Godot de assets/ciruja_run3.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_run4.png` | Jugador o acción del jugador. Copia exacta 200×200; preservada aunque Phaser no la cargaba. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_run4.png.import` | Metadatos Godot de assets/ciruja_run4.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_run5.png` | Jugador o acción del jugador. Copia exacta 200×200; preservada aunque Phaser no la cargaba. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_run5.png.import` | Metadatos Godot de assets/ciruja_run5.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_salto.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_salto.png.import` | Metadatos Godot de assets/ciruja_salto.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_salto1.png` | Jugador o acción del jugador. Copia exacta 200×200; preservada aunque Phaser no la cargaba. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_salto1.png.import` | Metadatos Godot de assets/ciruja_salto1.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_salto2.png` | Jugador o acción del jugador. Copia exacta 200×200; preservada aunque Phaser no la cargaba. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_salto2.png.import` | Metadatos Godot de assets/ciruja_salto2.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_salto3.png` | Jugador o acción del jugador. Copia exacta 200×200; preservada aunque Phaser no la cargaba. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_salto3.png.import` | Metadatos Godot de assets/ciruja_salto3.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/ciruja_salto4.png` | Jugador o acción del jugador. Copia exacta 200×200; preservada aunque Phaser no la cargaba. También disponible como pose AnimatedSprite2D. |
| `assets/ciruja_salto4.png.import` | Metadatos Godot de assets/ciruja_salto4.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/cofee.png` | Proyectil. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/cofee.png.import` | Metadatos Godot de assets/cofee.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/empanada.png` | Coleccionable. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/empanada.png.import` | Metadatos Godot de assets/empanada.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/exprebus.png` | Vehículo. Copia exacta 200×71; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/exprebus.png.import` | Metadatos Godot de assets/exprebus.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/final_boss_cofee1.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/final_boss_cofee1.png.import` | Metadatos Godot de assets/final_boss_cofee1.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/final_boss_cofee2.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/final_boss_cofee2.png.import` | Metadatos Godot de assets/final_boss_cofee2.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/final_boss_joke1.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/final_boss_joke1.png.import` | Metadatos Godot de assets/final_boss_joke1.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/final_boss_joke2.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/final_boss_joke2.png.import` | Metadatos Godot de assets/final_boss_joke2.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/final_boss_punch1.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/final_boss_punch1.png.import` | Metadatos Godot de assets/final_boss_punch1.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/final_boss_punch2.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/final_boss_punch2.png.import` | Metadatos Godot de assets/final_boss_punch2.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/final_boss_run1.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/final_boss_run1.png.import` | Metadatos Godot de assets/final_boss_run1.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/final_boss_run2.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/final_boss_run2.png.import` | Metadatos Godot de assets/final_boss_run2.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/final_boss_run3.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/final_boss_run3.png.import` | Metadatos Godot de assets/final_boss_run3.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/final_boss_salto1.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/final_boss_salto1.png.import` | Metadatos Godot de assets/final_boss_salto1.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/final_boss_salto2.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/final_boss_salto2.png.import` | Metadatos Godot de assets/final_boss_salto2.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/fondo_cerros.png` | Fondo o suelo. Copia exacta 900×450; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/fondo_cerros.png.import` | Metadatos Godot de assets/fondo_cerros.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/fusion_fondos.png` | Fondo o suelo. Copia exacta 8000×697; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/fusion_fondos.png.import` | Metadatos Godot de assets/fusion_fondos.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/grandote_punch1.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/grandote_punch1.png.import` | Metadatos Godot de assets/grandote_punch1.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/grandote_punch2.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/grandote_punch2.png.import` | Metadatos Godot de assets/grandote_punch2.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/grandote_punch3.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/grandote_punch3.png.import` | Metadatos Godot de assets/grandote_punch3.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/grandote_run1.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/grandote_run1.png.import` | Metadatos Godot de assets/grandote_run1.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/grandote_run2.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/grandote_run2.png.import` | Metadatos Godot de assets/grandote_run2.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/grandote_run3.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; preservada aunque Phaser no la cargaba. También disponible como pose AnimatedSprite2D. |
| `assets/grandote_run3.png.import` | Metadatos Godot de assets/grandote_run3.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/grandote_salto.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/grandote_salto.png.import` | Metadatos Godot de assets/grandote_salto.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/gruta_virgen.png` | Escenografía/indicador. Copia exacta 153×153; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/gruta_virgen.png.import` | Metadatos Godot de assets/gruta_virgen.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/hipster_agua1.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/hipster_agua1.png.import` | Metadatos Godot de assets/hipster_agua1.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/hipster_agua2.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/hipster_agua2.png.import` | Metadatos Godot de assets/hipster_agua2.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/hipster_run1.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/hipster_run1.png.import` | Metadatos Godot de assets/hipster_run1.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/hipster_run2.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/hipster_run2.png.import` | Metadatos Godot de assets/hipster_run2.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/hipster_run3.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/hipster_run3.png.import` | Metadatos Godot de assets/hipster_run3.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/hipster_salto.png` | Cuadro de enemigo/jefe. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/hipster_salto.png.import` | Metadatos Godot de assets/hipster_salto.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/juntar_cascote1.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/juntar_cascote1.png.import` | Metadatos Godot de assets/juntar_cascote1.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/juntar_cascote2.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/juntar_cascote2.png.import` | Metadatos Godot de assets/juntar_cascote2.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/juntar_cascote3.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/juntar_cascote3.png.import` | Metadatos Godot de assets/juntar_cascote3.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/juntar_cascote4.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/juntar_cascote4.png.import` | Metadatos Godot de assets/juntar_cascote4.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/juntar_cascote5.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/juntar_cascote5.png.import` | Metadatos Godot de assets/juntar_cascote5.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/juntar_naranjas1.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/juntar_naranjas1.png.import` | Metadatos Godot de assets/juntar_naranjas1.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/juntar_naranjas2.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/juntar_naranjas2.png.import` | Metadatos Godot de assets/juntar_naranjas2.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/juntar_naranjas3.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/juntar_naranjas3.png.import` | Metadatos Godot de assets/juntar_naranjas3.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/juntar_naranjas4.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/juntar_naranjas4.png.import` | Metadatos Godot de assets/juntar_naranjas4.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/juntar_naranjas5.png` | Jugador o acción del jugador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/juntar_naranjas5.png.import` | Metadatos Godot de assets/juntar_naranjas5.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/kiosco_coca.png` | Escenografía/indicador. Copia exacta 193×139; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/kiosco_coca.png.import` | Metadatos Godot de assets/kiosco_coca.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/montaña_cascote.png` | Escenografía/indicador. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/montaña_cascote.png.import` | Metadatos Godot de assets/montaña_cascote.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/naranja.png` | Proyectil. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/naranja.png.import` | Metadatos Godot de assets/naranja.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/palmera.png` | Escenografía/indicador. Copia exacta 119×149; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/palmera.png.import` | Metadatos Godot de assets/palmera.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/parada_colectivo.png` | Escenografía/indicador. Copia exacta 170×183; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/parada_colectivo.png.import` | Metadatos Godot de assets/parada_colectivo.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/poste_luz.png` | Escenografía/indicador. Copia exacta 58×173; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/poste_luz.png.import` | Metadatos Godot de assets/poste_luz.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/sanguche.png` | Coleccionable. Copia exacta 174×133; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/sanguche.png.import` | Metadatos Godot de assets/sanguche.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/secuestro_campeona.png` | Cinemática. Copia exacta 200×200; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/secuestro_campeona.png.import` | Metadatos Godot de assets/secuestro_campeona.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/sol.png` | Escenografía/indicador. Copia exacta 162×159; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/sol.png.import` | Metadatos Godot de assets/sol.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/suelo_ruta.png` | Fondo o suelo. Copia exacta 700×136; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/suelo_ruta.png.import` | Metadatos Godot de assets/suelo_ruta.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/suelo_ruta2.png` | Fondo o suelo. Copia exacta 700×136; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/suelo_ruta2.png.import` | Metadatos Godot de assets/suelo_ruta2.png: UID, rutas y opciones de importación. Generado por el motor. |
| `assets/tesa.png` | Vehículo. Copia exacta 200×63; usada en Phaser. También disponible como pose AnimatedSprite2D. |
| `assets/tesa.png.import` | Metadatos Godot de assets/tesa.png: UID, rutas y opciones de importación. Generado por el motor. |
| `audio/achilata.wav` | Efecto achilata derivado de AudioSFX: PCM mono 16 bits, 44.1 kHz; fuente y parámetros conservados en audio/source. |
| `audio/achilata.wav.import` | Metadatos Godot de audio/achilata.wav: UID, rutas y opciones de importación. Generado por el motor. |
| `audio/alerta.wav` | Efecto alerta derivado de AudioSFX: PCM mono 16 bits, 44.1 kHz; fuente y parámetros conservados en audio/source. |
| `audio/alerta.wav.import` | Metadatos Godot de audio/alerta.wav: UID, rutas y opciones de importación. Generado por el motor. |
| `audio/cabezazo.wav` | Efecto cabezazo derivado de AudioSFX: PCM mono 16 bits, 44.1 kHz; fuente y parámetros conservados en audio/source. |
| `audio/cabezazo.wav.import` | Metadatos Godot de audio/cabezazo.wav: UID, rutas y opciones de importación. Generado por el motor. |
| `audio/danio.wav` | Efecto danio derivado de AudioSFX: PCM mono 16 bits, 44.1 kHz; fuente y parámetros conservados en audio/source. |
| `audio/danio.wav.import` | Metadatos Godot de audio/danio.wav: UID, rutas y opciones de importación. Generado por el motor. |
| `audio/disparo_cascote.wav` | Efecto disparo_cascote derivado de AudioSFX: PCM mono 16 bits, 44.1 kHz; fuente y parámetros conservados en audio/source. |
| `audio/disparo_cascote.wav.import` | Metadatos Godot de audio/disparo_cascote.wav: UID, rutas y opciones de importación. Generado por el motor. |
| `audio/disparo_naranja.wav` | Efecto disparo_naranja derivado de AudioSFX: PCM mono 16 bits, 44.1 kHz; fuente y parámetros conservados en audio/source. |
| `audio/disparo_naranja.wav.import` | Metadatos Godot de audio/disparo_naranja.wav: UID, rutas y opciones de importación. Generado por el motor. |
| `audio/empanada.wav` | Efecto empanada derivado de AudioSFX: PCM mono 16 bits, 44.1 kHz; fuente y parámetros conservados en audio/source. |
| `audio/empanada.wav.import` | Metadatos Godot de audio/empanada.wav: UID, rutas y opciones de importación. Generado por el motor. |
| `audio/golpe.wav` | Efecto golpe derivado de AudioSFX: PCM mono 16 bits, 44.1 kHz; fuente y parámetros conservados en audio/source. |
| `audio/golpe.wav.import` | Metadatos Godot de audio/golpe.wav: UID, rutas y opciones de importación. Generado por el motor. |
| `audio/salto.wav` | Efecto salto derivado de AudioSFX: PCM mono 16 bits, 44.1 kHz; fuente y parámetros conservados en audio/source. |
| `audio/salto.wav.import` | Metadatos Godot de audio/salto.wav: UID, rutas y opciones de importación. Generado por el motor. |
| `audio/sanguche.wav` | Efecto sanguche derivado de AudioSFX: PCM mono 16 bits, 44.1 kHz; fuente y parámetros conservados en audio/source. |
| `audio/sanguche.wav.import` | Metadatos Godot de audio/sanguche.wav: UID, rutas y opciones de importación. Generado por el motor. |
| `audio/source/audio_sfx_original.js` | Copia del bloque AudioSFX original, conservada como fuente. El juego Godot no ejecuta este JavaScript. |
| `audio/source/sfx_recipes.json` | Tipo de onda, duración, frecuencias, rampas y ganancia capturados de los once efectos originales. |
| `audio/victoria.wav` | Efecto victoria derivado de AudioSFX: PCM mono 16 bits, 44.1 kHz; fuente y parámetros conservados en audio/source. |
| `audio/victoria.wav.import` | Metadatos Godot de audio/victoria.wav: UID, rutas y opciones de importación. Generado por el motor. |
| `migration_report.md` | Informe e inventario individual de los archivos de la entrega. |
| `project.godot` | Configuración Godot 4.7, Compatibility/OpenGL, viewport 800×450, física a 60 Hz, capas de colisión y autoload de audio. |
| `scenes/actors/enemy.tscn` | CharacterBody2D reutilizable para hipster, agente, grandote y jefe; visual AnimatedSprite2D. |
| `scenes/actors/pickup.tscn` | Area2D y AnimatedSprite2D para objetos recolectables y naranjo interactivo. |
| `scenes/actors/platform.tscn` | StaticBody2D y AnimatedSprite2D para vehículos con techo unidireccional. |
| `scenes/actors/player.tscn` | CharacterBody2D del hincha con AnimatedSprite2D. Genera su CollisionShape2D al instanciarse. |
| `scenes/actors/projectile.tscn` | Area2D y AnimatedSprite2D para cinco tipos de proyectil. |
| `scenes/levels/route_38.tscn` | Nivel con parallax, escenario, suelos, objetos, enemigos, proyectiles y jugador. |
| `scenes/levels/route_38_data.json` | Localidades en el orden pedido, umbrales editables, seis oleadas, jefe y destino Ingenio Arcor. |
| `scenes/main.tscn` | Escena raíz con nivel, Camera2D suave y CanvasLayer de interfaz. |
| `scripts/actors/enemy.gd` | IA inicial por arquetipo, ataques, contacto, daño, recompensa única y escape del jefe. |
| `scripts/actors/enemy.gd.uid` | Identificador estable Godot del script scripts/actors/enemy.gd. |
| `scripts/actors/pickup.gd` | Recolección mediante colisión y aplicación de efectos. El naranjo permanece visible tras activarse. |
| `scripts/actors/pickup.gd.uid` | Identificador estable Godot del script scripts/actors/pickup.gd. |
| `scripts/actors/platform.gd` | Genera un techo unidireccional a partir de los límites opacos de la imagen del vehículo. |
| `scripts/actors/platform.gd.uid` | Identificador estable Godot del script scripts/actors/platform.gd. |
| `scripts/actors/player.gd` | move_and_slide, salto, carriles, estados, armas, daño, inventario, monedas, calor y Furia Milanesa. |
| `scripts/actors/player.gd.uid` | Identificador estable Godot del script scripts/actors/player.gd. |
| `scripts/actors/projectile.gd` | Textura/velocidad/daño por tipo; colisión Area2D, barrido de trayectoria, filtro de carril/equipo y caducidad. |
| `scripts/actors/projectile.gd.uid` | Identificador estable Godot del script scripts/actors/projectile.gd. |
| `scripts/core/audio_manager.gd` | Autoload con ocho AudioStreamPlayer, once WAV y gestión del cierre de audio. |
| `scripts/core/audio_manager.gd.uid` | Identificador estable Godot del script scripts/core/audio_manager.gd. |
| `scripts/core/collision_factory.gd` | Calcula límites opacos de PNG, cachea resultados y genera formas rectangulares para cuerpos/áreas/suelos. |
| `scripts/core/collision_factory.gd.uid` | Identificador estable Godot del script scripts/core/collision_factory.gd. |
| `scripts/core/game_config.gd` | Constantes compartidas: dimensiones, carriles, velocidades, gravedad y capas. |
| `scripts/core/game_config.gd.uid` | Identificador estable Godot del script scripts/core/game_config.gd. |
| `scripts/core/hud.gd` | Actualiza salud, vidas, puntos, monedas, munición, calor, localidad, jefe y resultados. |
| `scripts/core/hud.gd.uid` | Identificador estable Godot del script scripts/core/hud.gd. |
| `scripts/core/input_setup.gd` | Registra las acciones del InputMap y las teclas al iniciar. Punto de edición para reasignar controles. |
| `scripts/core/input_setup.gd.uid` | Identificador estable Godot del script scripts/core/input_setup.gd. |
| `scripts/core/main.gd` | Coordina input, cámara, disparos, pausa, visor, muerte y final del nivel. |
| `scripts/core/main.gd.uid` | Identificador estable Godot del script scripts/core/main.gd. |
| `scripts/core/route_38.gd` | Construye escenario y colisiones, instancia objetos/oleadas, consulta localidades y activa al jefe en Río Seco. |
| `scripts/core/route_38.gd.uid` | Identificador estable Godot del script scripts/core/route_38.gd. |
| `scripts/tools/asset_gallery.gd` | Visor F1 para 100 PNG, 30 animaciones de actores y 11 sonidos; funciona mientras el mundo está pausado. |
| `scripts/tools/asset_gallery.gd.uid` | Identificador estable Godot del script scripts/tools/asset_gallery.gd. |
| `scripts/tools/build_native_animations.cjs` | Genera ocho acciones/estados canónicos del jugador y biblioteca de 100 poses con imágenes existentes. |
| `scripts/tools/build_report.cjs` | Regenera este informe a partir de inventario, descripciones y resultados de validación. |
| `scripts/tools/import_legacy.cjs` | Lee el HTML/JS padre, copia PNG, extrae 22 animaciones y audio original, genera WAV y llama al generador nativo. No requiere npm. |
| `scripts/tools/verify_integrity.cjs` | Compara SHA-256 de 104 originales y 100 copias; valida WAV y registra el resultado. |
| `shaders/README.md` | Reserva para shaders futuros; se usan materiales del motor, sin arte nuevo. |
| `tests/capture_preview.gd` | Genera capturas usando el renderizador real de Godot; no modifica los PNG fuente. |
| `tests/capture_preview.gd.uid` | Identificador estable Godot del script tests/capture_preview.gd. |
| `tests/migration_smoke.gd` | Integración: recursos, física, colisiones, inventario, vida, calor, pausa, muerte y escape del jefe. |
| `tests/migration_smoke.gd.uid` | Identificador estable Godot del script tests/migration_smoke.gd. |
| `tilesets/README.md` | Explica el uso de imágenes de suelo repetidas y la reserva para un futuro TileSet. |
| `ui/asset_gallery.tscn` | Control del visor de recursos, activo durante la pausa. |
| `ui/hud.tscn` | HUD nativo: barra verde de salud, puntaje, monedas, vidas, munición, calor, barra roja del jefe y resultados. Sin ilustración nueva. |
| `validation/.gdignore` | Excluye evidencias y registros de la importación/exportación de recursos del juego. |
| `validation/gallery_preview.png` | Captura del visor. Evidencia, no asset jugable. |
| `validation/gallery_preview.png.import` | Metadatos Godot de validation/gallery_preview.png: UID, rutas y opciones de importación. Generado por el motor. |
| `validation/godot_test_results.json` | Resultado estructurado más reciente de las pruebas, número de comprobaciones y versión del motor. |
| `validation/import.log` | Registro de importación Godot. |
| `validation/import_results.json` | Extracción histórica: 100 imágenes, 81 cargadas, 19 sin uso, 22 animaciones, 11 efectos y duplicados. |
| `validation/integrity_results.json` | Resultado más reciente de la comparación de originales y copias. |
| `validation/original_hashes.json` | Línea base anterior a la migración: hashes de cuatro archivos raíz y 100 PNG del original. |
| `validation/preview.log` | Registro del renderizador Compatibility al producir las capturas. |
| `validation/rio_seco_preview.png` | Captura del tramo final con jefe. Evidencia, no asset jugable. |
| `validation/route_preview.png` | Captura del inicio en Famaillá. Evidencia, no asset jugable. |
| `validation/route_preview.png.import` | Metadatos Godot de validation/route_preview.png: UID, rutas y opciones de importación. Generado por el motor. |
| `validation/startup.log` | Registro de arranque de la escena principal. |
| `validation/tests.log` | Registro más reciente de integración; prevalece sobre diagnósticos anteriores. |
| `validation/tests_verbose.log` | Diagnóstico histórico de un cierre de audio de la base inicial. La finalización fue corregida; consultar tests.log para el resultado vigente. |

## Caché interna del motor

.godot/ se genera automáticamente dentro de esta carpeta: texturas y audio importados, índices de UID/clases, estado del editor y cachés de shaders. Se excluye del control de versiones y se reconstruye al importar. Sus archivos internos variables no son entregables editados manualmente y no se enumeran en la tabla.

## Referencias del motor

- [CharacterBody2D](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html)
- [AnimatedSprite2D](https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html)
- [Parallax2D](https://docs.godotengine.org/en/stable/classes/class_parallax2d.html)
- [Línea de comandos](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)
