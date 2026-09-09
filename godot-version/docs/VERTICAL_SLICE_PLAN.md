# Plan técnico del vertical slice

## 1. Objetivo y alcance

Este documento define cómo convertir el prototipo Godot 4 existente en una base escalable para un vertical slice profesional de **Famaillá / inicio de Ruta 38**. No propone una nueva migración, una reescritura completa ni la implementación de la campaña entera.

El trabajo debe avanzar por cambios pequeños, manteniendo el prototipo ejecutable después de cada tarea. Los assets actuales continúan como **LEGACY/REFERENCE** hasta que una tarea artística autorice otra cosa.

El vertical slice terminado deberá demostrar:

- selección entre dos protagonistas equivalentes;
- movimiento arcade, salto y cambio de carril;
- ataque cuerpo a cuerpo y lanzamiento de proyectil;
- daño, hit reaction, muerte y recuperación;
- combo y una versión validable del Tucumanazo;
- enemigos básicos y un miniboss;
- cámara, HUD, diálogos y checkpoints;
- música, efectos, parallax, tráfico y ambientación;
- introducción cinematográfica y cierre de demo.

Decisiones aprobadas: plataforma inicial Windows PC; resolución interna 800×450; objetivo de 60 FPS estables; duración de 10–15 minutos en primera partida; recorrido limitado a Famaillá y el inicio de Ruta 38; teclado y gamepad; dos protagonistas con estadísticas y hitboxes idénticas; Cabezazo como ataque cuerpo a cuerpo; Naranjazo como proyectil principal; un checkpoint; y El Grandote como miniboss provisional.

Quedan **TBD**: hardware mínimo de referencia; protagonista seleccionado por defecto; asignación concreta de assets legacy para el hincha de Atlético; valores finales de carga, daño, radio y duración del combo/Tucumanazo; posición exacta del checkpoint; reglas detalladas de restauración; y contenido final de diálogos, música y efectos.

## 2. Arquitectura actual resumida

La escena `scenes/main.tscn` compone el nivel, una `Camera2D` y la interfaz en `CanvasLayer`. `scripts/core/main.gd` coordina señales, proyectiles, pausa, muerte y cierre. `scenes/levels/route_38.tscn` contiene nodos contenedores para escenario, terreno, objetos, enemigos y proyectiles, mientras `scripts/core/route_38.gd` construye el recorrido y activa oleadas.

El jugador y los enemigos son `CharacterBody2D`. Los proyectiles y pickups son `Area2D`; las plataformas son `StaticBody2D`. La comunicación principal usa señales, aunque varios sistemas consultan directamente propiedades internas de otros nodos.

La arquitectura es suficiente para un prototipo, pero todavía mezcla configuración, estado, presentación y reglas de juego dentro de scripts concretos.

## 3. Sistemas actuales que pueden conservarse

| Sistema | Base reutilizable | Condición para conservarlo |
|---|---|---|
| Composición principal | `main.tscn` con nivel, cámara e interfaz separada | Mantener `main.gd` como coordinador de flujo, sin convertirlo en contenedor de reglas de combate. |
| Movimiento | `CharacterBody2D`, `move_and_slide`, gravedad, salto variable y dos carriles | Proteger el comportamiento actual con pruebas antes de separar datos o estados. |
| Cámara | `Camera2D` con seguimiento suave y límites | Añadir zonas o eventos sólo si el vertical slice los necesita. |
| Proyectiles | Una escena reutilizable con tipos, equipo, carril, daño y caducidad | Mover configuración a datos y evitar crear `SpriteFrames` por instancia. |
| Daño básico | `take_damage`, invulnerabilidad y señales de muerte/derrota | Unificar el contrato mediante un componente pequeño, preservando valores actuales inicialmente. |
| Enemigos | Un actor común con definiciones de hipster, agente y grandote | Separar datos y decisiones de IA; evitar un árbol de comportamiento para este alcance. |
| Nivel | Contenedores de terreno, objetos, enemigos y proyectiles | Extraer la coordinación de encuentros sin reconstruir todo el nivel de una vez. |
| Oleadas | Datos externos en `route_38_data.json` | Para el vertical slice, usar datos tipados o validar el JSON antes de consumirlo. |
| Pickups | Escena común, filtro por carril y evento de recolección | Evitar que el jugador contenga todas las consecuencias de todos los tipos. |
| Plataformas | `StaticBody2D` y techo unidireccional | Conservar para vehículos estáticos; diseñar tráfico móvil como sistema aparte. |
| Colisiones | Capas por carril y `CollisionFactory` | Conservar como compatibilidad; precalcular formas críticas para evitar trabajo de imagen durante gameplay. |
| HUD | `CanvasLayer`, barras y pantalla de resultados | Cambiar de consulta por frame a actualización por señales. |
| Audio | `AudioManager` con varias voces para SFX | Ampliar con buses y música; no sustituir los efectos existentes sin revisión auditiva. |
| Parallax | `Parallax2D` del fondo lejano | Convertirlo en una composición pequeña de capas configurables. |
| Input | Acciones con nombres semánticos | Añadir acciones faltantes y navegación de selección sin dispersar lectura directa de teclas. |

## 4. Sistemas que necesitan refactor

### 4.1 Jugador

`player.gd` controla input, locomoción, carriles, animación, ataque, daño, vidas, puntaje, monedas, munición, pickups, calor y power-up. Debe continuar como coordinador del personaje, pero delegar gradualmente:

- salud/daño a un `HealthComponent`;
- hitboxes y hurtboxes a áreas reutilizables;
- datos visuales y parámetros a `CharacterDefinition`;
- combo/especial a un componente de combate pequeño;
- progreso de partida, puntaje y checkpoint a una sesión fuera del actor.

No conviene separar locomoción en muchos nodos ni implementar una máquina de estados genérica. El enum actual puede evolucionar a una máquina explícita dentro de `player.gd`, con funciones de entrada/salida de estado y prioridades claras.

### 4.2 Enemigos

`enemy.gd` contiene cuatro arquetipos, IA, contacto, ataques, daño y comportamiento especial del jefe. El refactor mínimo recomendado es:

- `EnemyDefinition` para salud, velocidad, puntuación, animaciones y ataque;
- `HealthComponent` y hit/hurt boxes compartidos;
- un controlador base de persecución/ataque;
- scripts específicos sólo para conductas que realmente difieran, como miniboss.

No usar behavior trees, navegación ni ECS para el vertical slice.

### 4.3 Nivel y encuentros

`route_38.gd` construye escenario, suelos, props, pickups, oleadas, enemigos y cierre. Debe conservar la escena actual mientras se extraen dos responsabilidades:

- `EncounterDirector`: activa grupos de enemigos y comunica cuándo termina un encuentro;
- `Checkpoint`: guarda una posición y un identificador estable dentro de la sesión.

La colocación visual del vertical slice debería quedar mayormente en escenas editables. Los datos deben describir encuentros, no reemplazar al editor como herramienta de composición.

### 4.4 Estado de partida y flujo

Salud, puntaje y monedas viven hoy en el jugador; el final está acoplado al escape del boss. Hace falta una sesión mínima que conserve:

- personaje elegido;
- puntaje/monedas si siguen en el diseño;
- checkpoint activo;
- estado de demo y reinicio.

`main.gd` debe coordinar estados de alto nivel: selección, cinemática, gameplay, pausa y resultado. No debe resolver ataques ni recompensas.

### 4.5 HUD

El HUD formatea textos durante cada `_process`. Debe reaccionar a señales de salud, puntaje, recursos, combo, especial, miniboss y checkpoint. Esto reduce acoplamiento y trabajo por frame.

### 4.6 Colisiones y creación de recursos

`CollisionFactory` lee píxeles de una textura la primera vez que aparece. El caché limita el costo, pero puede producir una pausa al instanciar un actor. Para personajes, enemigos frecuentes, proyectiles y tráfico del vertical slice, las formas deben quedar guardadas en escenas o recursos después de una generación en editor/herramienta.

`projectile.gd` crea `SpriteFrames` en ejecución para cada proyectil. Las variantes del vertical slice deberían usar escenas o recursos preconfigurados. No introducir pooling hasta que el perfilador muestre que las altas/bajas de nodos son un problema.

## 5. Sistemas faltantes

| Sistema | Alcance mínimo del vertical slice |
|---|---|
| Selección de protagonista | Dos opciones, vista previa, confirmación, retorno y persistencia durante la partida. La asignación de assets legacy de Atlético permanece **TBD**. |
| Definiciones de personaje | Mismos contratos de movimiento/combate y estadísticas base idénticas. Habilidades exclusivas fuera del alcance actual. |
| Ataque cuerpo a cuerpo | Ventana activa, alcance frontal, daño, recuperación y feedback; debe usar hitbox, no buscar todos los enemigos del árbol. |
| Combo | Contador, ventana temporal, eventos que suman/rompen combo y feedback de HUD. Multiplicadores/recompensas: **TBD**. |
| Tucumanazo | Recurso/carga, activación, duración, efecto y cancelación. Mecánica exacta: **TBD** antes de programar. |
| Miniboss | El Grandote: actor propio que reutilice salud/combate y posea hasta tres patrones legibles: embestida, puñetazo y salto/golpe al suelo. |
| Diálogos | Datos, caja de texto, hablante, avance, bloqueo/restauración de control y eventos al finalizar. |
| Cinemática inicial | Secuencia breve con actores, cámara, diálogos, secuestro y transición controlada al gameplay. |
| Checkpoints | Un checkpoint con activación única, respawn, restauración de estado definido y señal visual/sonora. Posición y reglas exactas: **TBD**. |
| Música | Reproductor, buses, loop, transición entre introducción/gameplay/miniboss y pausa. Composiciones: **TBD**. |
| Tráfico | Spawner limitado, carril, dirección, telegráfico, daño y reciclado/despawn fuera de cámara. |
| Ambientación | Props y eventos simples sin lógica individual innecesaria; densidad controlada. |
| Cierre de demo | Estado terminal, resultado, llamada hacia Acheral y opciones de reiniciar/salir. |
| Guardado | No necesario para el primer vertical slice salvo decisión posterior; mantener **TBD**. |

## 6. Dependencias entre sistemas

| Sistema consumidor | Depende de |
|---|---|
| Selección | Definiciones de personaje, sesión de juego, flujo principal, UI/input. |
| Jugador seleccionable | Definición de personaje, locomoción existente, animación y salud compartida. |
| Cuerpo a cuerpo | Estados del jugador, hitbox/hurtbox, salud/daño y facciones/carriles. |
| Proyectiles | Salud/daño, facciones/carriles, definiciones de ataque y fábrica de spawn. |
| Combo | Eventos de impacto/derrota/daño recibido y HUD. |
| Tucumanazo | Combo o medidor elegido, estados del jugador, feedback, audio y HUD. |
| Enemigos básicos | Salud/daño, definiciones, ataque, objetivo y EncounterDirector. |
| Miniboss | Base de enemigo, encuentros, cámara, HUD de boss y música. |
| Checkpoints | Sesión de juego, respawn, EncounterDirector y estado de pickups. |
| Diálogos | UI, input contextual y bloqueo/restauración de control. |
| Cinemática | Diálogos, flujo principal, cámara, audio y actores de escena. |
| Tráfico | Carriles, daño, cámara y presupuesto de instancias. |
| Cierre de demo | Encuentro final, diálogo, sesión, HUD y flujo principal. |

Regla de dependencia: el contenido concreto depende de componentes de gameplay; los componentes de gameplay no deben depender de un nivel específico. Las comunicaciones entre pares conocidos usan señales directas. No se recomienda un EventBus global para este alcance.

## 7. Orden exacto recomendado de implementación

Cada tarea debe entregarse de forma independiente. Los nombres de archivos nuevos son propuestas y pueden ajustarse si, al iniciar la tarea, ya existe una solución equivalente.

### Tarea 01 — Congelar línea base y criterios del vertical slice

**Trabajo:** definir duración objetivo, plataforma mínima, contenido incluido/excluido y recorrido de prueba. Registrar controles y valores actuales que no deben cambiar accidentalmente.

**Archivos aproximados:** `docs/VERTICAL_SLICE_ACCEPTANCE.md` (nuevo), `tests/migration_smoke.gd` (ampliación pequeña si faltan coberturas).

**Terminado cuando:** existe una lista reproducible de inicio a fin, FPS objetivo y regresiones críticas; el prototipo sigue pasando sus pruebas actuales.

**Modelo recomendado:** económico para documentación; razonamiento superior sólo para cerrar alcance si hay requisitos contradictorios.

### Tarea 02 — Sesión y estados de flujo

**Trabajo:** crear una sesión mínima y formalizar selección, cinemática, gameplay, pausa y resultado. Mantener el arranque actual como camino predeterminado hasta añadir selección.

**Archivos aproximados:** `scripts/core/game_session.gd` (nuevo), `scripts/core/main.gd`, `scenes/main.tscn`, `project.godot`, pruebas.

**Terminado cuando:** reiniciar limpia el estado correcto; pausa no altera gameplay; cambiar de estado habilita/deshabilita controles sin referencias circulares.

**Modelo recomendado:** razonamiento superior.

### Tarea 03 — Datos de protagonistas

**Trabajo:** introducir `CharacterDefinition` con nombre, escena visual, animaciones y parámetros, manteniendo inicialmente los valores del hincha de San Martín. Definir el contrato del segundo personaje sin inventar arte ni estadísticas.

**Archivos aproximados:** `scripts/data/character_definition.gd` (nuevo), `data/characters/*.tres` (nuevos), `scripts/actors/player.gd`, `scenes/actors/player.tscn`, pruebas.

**Terminado cuando:** el mismo `Player` acepta una definición y reproduce exactamente el comportamiento actual con la definición de San Martín; una definición incompleta falla con un mensaje claro.

**Modelo recomendado:** razonamiento superior para el primer cambio; económico para cargar recursos adicionales siguiendo el patrón.

### Tarea 04 — Pantalla de selección

**Trabajo:** crear UI de dos opciones conectada a la sesión. La asignación de assets legacy de Atlético puede permanecer bloqueada como **TBD**; no usar gráficos nuevos sin tarea artística.

**Archivos aproximados:** `ui/character_select.tscn` y `scripts/ui/character_select.gd` (nuevos), `scenes/main.tscn`, `scripts/core/main.gd`, input y pruebas.

**Terminado cuando:** teclado y gamepad permiten elegir, confirmar y volver; la elección llega al jugador y sobrevive al reinicio del nivel según la regla definida.

**Modelo recomendado:** económico una vez definido el contrato de la Tarea 03.

### Tarea 05 — Componente común de salud y daño

**Trabajo:** extraer salud, invulnerabilidad, muerte y señales comunes. Mantener respawn/vidas en el jugador y recompensa en la sesión o director, no dentro del componente.

**Archivos aproximados:** `scripts/components/health_component.gd` y `scenes/components/health_component.tscn` (nuevos), `player.gd`, `enemy.gd`, escenas de actor y pruebas.

**Terminado cuando:** jugador y enemigo reciben daño por el mismo contrato; no hay daño duplicado por frame; invulnerabilidad, derrota y muerte ocurren una sola vez.

**Modelo recomendado:** razonamiento superior.

### Tarea 06 — Hitbox, hurtbox y definición de ataque

**Trabajo:** agregar áreas de ataque/recepción con facción, carril, daño y ventana activa. Crear un dato mínimo `AttackDefinition`; evitar una jerarquía general de efectos.

**Archivos aproximados:** `scripts/components/hitbox.gd`, `hurtbox.gd`, `scripts/data/attack_definition.gd`, escenas de componentes y actores, pruebas.

**Terminado cuando:** el atacante no se golpea a sí mismo ni a aliados; carriles distintos no interactúan; un ataque sólo aplica el número de impactos previsto.

**Modelo recomendado:** razonamiento superior.

### Tarea 07 — Ataque cuerpo a cuerpo

**Trabajo:** reemplazar la búsqueda global del cabezazo por una hitbox frontal temporizada y añadir la acción cuerpo a cuerpo base. Sin arte nuevo: animaciones faltantes permanecen **TBD** o usan recursos legacy aprobados explícitamente.

**Archivos aproximados:** `player.gd`, `player.tscn`, `attack_definition` de melee/cabezazo, input, audio y pruebas.

**Terminado cuando:** inicio, ventana activa y recuperación son verificables; dirección y carril son correctos; recibir daño o morir cancela el ataque según regla documentada.

**Modelo recomendado:** razonamiento superior para timing/cancelaciones; económico para datos posteriores.

### Tarea 08 — Proyectiles configurables

**Trabajo:** conservar la escena común, trasladar tipos a recursos preconfigurados y evitar crear `SpriteFrames` por disparo. Mantener barrido contra tunneling y caducidad.

**Archivos aproximados:** `projectile.gd`, `projectile.tscn`, `scripts/data/projectile_definition.gd` y `data/projectiles/*.tres` (nuevos), `main.gd` o una fábrica pequeña, pruebas.

**Terminado cuando:** naranja, piedra, botella y proyectil del miniboss comparten código; daño, velocidad, equipo y carril provienen de datos; no se cargan texturas ni se crean recursos visuales por instancia.

**Modelo recomendado:** económico con revisión puntual de razonamiento superior sobre colisiones rápidas.

### Tarea 09 — Combo

**Trabajo:** definir eventos que suman, mantienen y rompen combo; implementar ventana temporal y señal al HUD. No asignar todavía el Tucumanazo automáticamente.

**Archivos aproximados:** `scripts/components/combo_component.gd` (nuevo), escena del jugador, `hud.gd`, `hud.tscn`, pruebas.

**Terminado cuando:** sólo impactos válidos suman; recibir daño o vencer la ventana rompe el combo; los eventos no dependen del tipo concreto de enemigo; comportamiento a pausas es consistente.

**Modelo recomendado:** razonamiento superior para reglas; económico para UI una vez cerradas.

### Tarea 10 — Tucumanazo vertical-slice

**Trabajo:** cerrar primero un diseño breve (**TBD**) y luego implementar una sola versión. Debe consumir una carga o condición clara, tener estado propio y feedback inequívoco.

**Archivos aproximados:** `GAME_DESIGN.md` o documento de decisión, `player.gd`, componente de combo/especial, HUD, audio, input y pruebas.

**Terminado cuando:** no puede activarse sin requisito; el consumo ocurre una sola vez; daño/movimiento/pausa/muerte cancelan o preservan el especial según reglas; no rompe encuentros.

**Modelo recomendado:** razonamiento superior.

### Tarea 11 — Enemigos básicos dirigidos por datos

**Trabajo:** convertir definiciones internas en recursos y dejar una IA simple: acercarse, telegráfica, atacar, recuperar. Conservar los arquetipos útiles para el slice; no portar todos si no aparecen.

**Archivos aproximados:** `enemy.gd`, `enemy.tscn`, `scripts/data/enemy_definition.gd`, `data/enemies/*.tres`, posibles scripts de ataque pequeños, pruebas.

**Terminado cuando:** al menos un enemigo de rango y uno cuerpo a cuerpo se configuran sin ramas por nombre; se desconectan y liberan correctamente; respetan carriles y estados del jugador.

**Modelo recomendado:** razonamiento superior para el patrón base; económico para variantes de datos.

### Tarea 12 — EncounterDirector y arena del slice

**Trabajo:** extraer activación de oleadas del nivel, definir inicio/fin de encuentros y bloqueo de avance sólo donde sea necesario.

**Archivos aproximados:** `scripts/level/encounter_director.gd` y recursos de encuentro (nuevos), `route_38.gd`, `route_38.tscn` o una escena específica del vertical slice, pruebas.

**Terminado cuando:** cada encuentro se activa una vez, informa finalización y no conserva referencias inválidas; reinicio/checkpoint puede restaurarlo de forma determinista.

**Modelo recomendado:** razonamiento superior.

### Tarea 13 — Checkpoints y respawn

**Trabajo:** añadir el único checkpoint explícito conectado a la sesión; definir qué se restaura: posición, salud, enemigos, pickups, combo y especial. Su posición exacta permanece **TBD**.

**Archivos aproximados:** `scripts/level/checkpoint.gd`, `scenes/level/checkpoint.tscn` (nuevos), `game_session.gd`, `main.gd`, `encounter_director.gd`, jugador y pruebas.

**Terminado cuando:** morir y continuar coloca al personaje en el último checkpoint; no duplica recompensas ni oleadas; reiniciar demo sigue siendo distinto de respawn.

**Modelo recomendado:** razonamiento superior.

### Tarea 14 — HUD dirigido por eventos

**Trabajo:** conectar señales de salud, sesión, inventario, combo, especial, miniboss y checkpoint. Mantener la interfaz en `CanvasLayer`.

**Archivos aproximados:** `hud.gd`, `hud.tscn`, componentes emisores y pruebas.

**Terminado cuando:** el HUD no necesita leer todo el jugador cada frame; cada indicador cambia sólo ante eventos; resolución 800×450 y escalado mantienen legibilidad.

**Modelo recomendado:** económico.

### Tarea 15 — Diálogos

**Trabajo:** crear formato de datos sencillo y una caja reutilizable. Debe administrar avance, hablante, bloqueo de control y señal de finalización.

**Archivos aproximados:** `scripts/dialogue/dialogue_runner.gd`, `scripts/data/dialogue_sequence.gd`, `ui/dialogue_box.tscn`, escenas/datos de diálogo y pruebas.

**Terminado cuando:** una conversación de varios hablantes comienza y termina por evento; pausa/avance rápido no deja controles bloqueados; textos se editan sin tocar código.

**Modelo recomendado:** razonamiento superior para flujo/cancelación; económico para cargar textos ya aprobados.

### Tarea 16 — Cinemática inicial

**Trabajo:** usar el sistema de diálogos, cámara y actores de escena para el secuestro. Preferir `AnimationPlayer` y señales sobre esperas encadenadas difíciles de cancelar.

**Archivos aproximados:** `scenes/cinematics/intro_famailla.tscn`, `scripts/cinematics/intro_famailla.gd`, `main.gd`, datos de diálogo, audio y pruebas.

**Terminado cuando:** puede reproducirse y omitirse; ambos caminos entregan exactamente el mismo estado inicial; la Campeona habla y actúa; el jugador recupera control una sola vez.

**Modelo recomendado:** razonamiento superior para orquestación; económico para ajustes de tiempos y texto.

### Tarea 17 — Miniboss

**Trabajo:** construir una escena específica para El Grandote que reutilice salud, hurtbox, ataques, EncounterDirector, HUD y música. Limitar sus patrones a embestida, puñetazo y salto/golpe al suelo.

**Archivos aproximados:** `scenes/actors/miniboss_*.tscn`, `scripts/actors/miniboss_*.gd`, definiciones de ataques, encuentro, HUD, audio y pruebas.

**Terminado cuando:** patrones se telegráfian, no se solapan de forma inválida, transición de derrota ocurre una vez y el encuentro termina de manera determinista.

**Modelo recomendado:** razonamiento superior.

### Tarea 18 — Parallax y composición ambiental

**Trabajo:** convertir Famaillá/inicio de ruta en pocas capas reutilizables y colocar landmarks/props desde escenas. No procesar lógica individual para decoración estática.

**Archivos aproximados:** escena del vertical slice, posibles escenas de capa, `route_38.gd` reducido, datos de nivel. Assets sólo mediante una tarea artística separada.

**Terminado cuando:** no hay huecos visibles, popping ni profundidad incorrecta; decoración no crea procesos por frame; una persona local reconoce Famaillá con los elementos aprobados.

**Modelo recomendado:** económico para composición técnica; razonamiento superior si hay problemas de coordenadas, escala o carga.

### Tarea 19 — Tráfico y elementos ambientales

**Trabajo:** crear un controlador de tráfico acotado con advertencia, aparición fuera de cámara, carril, daño, salida y máximo de instancias. Reutilizar la escena de plataforma cuando corresponda, sin mezclar vehículo móvil con decoración.

**Archivos aproximados:** `scripts/level/traffic_director.gd`, `scenes/actors/vehicle.tscn`, `scripts/actors/vehicle.gd`, datos de encuentro/nivel y pruebas.

**Terminado cuando:** nunca aparece sobre el jugador, respeta presupuesto de instancias, sale o se recicla fuera de cámara y no rompe checkpoints ni encuentros.

**Modelo recomendado:** razonamiento superior para física/spawn; económico para variantes configuradas.

### Tarea 20 — Música, buses y transiciones

**Trabajo:** ampliar `AudioManager` para música y buses separados de SFX; implementar loops y transiciones entre introducción, gameplay y miniboss. No crear ni copiar música dentro de esta tarea técnica.

**Archivos aproximados:** `audio_manager.gd`, `default_bus_layout.tres`, flujo/cinemática/miniboss y recursos musicales futuros.

**Terminado cuando:** volumen de música/SFX es independiente; loops no producen dobles reproducciones; pausa y cambio de estado conservan la política definida; ausencia de una pista falla de forma segura.

**Modelo recomendado:** económico para conexiones; razonamiento superior si se requiere mezcla dinámica o sincronización musical.

### Tarea 21 — Cierre de demo

**Trabajo:** crear una secuencia terminal corta que cierre el encuentro, apunte hacia Acheral y muestre reinicio/salida. No construir el resto de la campaña.

**Archivos aproximados:** `main.gd`, escena de cierre o diálogo, HUD/menú de resultado, sesión y pruebas.

**Terminado cuando:** se activa una sola vez; detiene daño/spawns; muestra resultado; reiniciar vuelve a un estado limpio; el mensaje no promete contenido jugable inexistente.

**Modelo recomendado:** económico si el flujo ya está consolidado.

### Tarea 22 — Perfilado y pulido de entrega

**Trabajo:** perfilar CPU, física, memoria y cantidad de nodos en una partida completa; corregir sólo cuellos medidos. Validar controles, cámaras, checkpoints, audio y finales.

**Archivos aproximados:** los que correspondan a problemas confirmados, pruebas y documentación de aceptación.

**Terminado cuando:** el slice completo cumple el FPS objetivo en el hardware **TBD**, no presenta errores del depurador, no crece en nodos/memoria tras reinicios y supera la lista de aceptación.

**Modelo recomendado:** razonamiento superior para diagnóstico; económico para correcciones mecánicas ya identificadas.

## 8. Estrategia de pruebas

Cada tarea debe ampliar las pruebas existentes sólo para comportamiento de alto valor. No crear pruebas que repitan literalmente la implementación.

Prioridades:

1. estados de flujo y reinicio limpio;
2. movimiento a distintas tasas de física;
3. daño único, facciones y separación entre carriles;
4. cancelación de ataques y Tucumanazo;
5. encuentros, checkpoint y restauración determinista;
6. cinemática reproducida/omitida con el mismo resultado;
7. miniboss y cierre activados una sola vez;
8. ausencia de nodos, temporizadores o audio acumulados tras reinicios.

Además de pruebas automatizadas, cada entrega que cambie sensación de juego necesita una prueba manual corta con overlay de colisiones y profiler cuando corresponda.

## 9. Riesgos técnicos

| Riesgo | Impacto | Mitigación |
|---|---|---|
| Refactor del jugador altera el movimiento | Alto: se pierde la sensación arcade ya funcional | Capturar valores y pruebas antes de extraer componentes; cambiar una responsabilidad por tarea. |
| Estados simultáneos incompatibles | Alto: atacar, recibir daño, dialogar o pausar pueden dejar al jugador bloqueado | Prioridades explícitas y transiciones con entrada/salida; pruebas de cancelación. |
| Segundo protagonista obliga a duplicar escenas | Alto a mediano | Una escena `Player` y definiciones de datos; scripts específicos sólo si una habilidad futura lo exige. |
| Contratos de daño divergentes | Alto | `HealthComponent` y hit/hurt boxes compartidos antes de combo, enemigos y miniboss. |
| Checkpoints duplican enemigos/recompensas | Alto | IDs estables de encuentros/pickups y restauración desde una única sesión. |
| Runtime carga/analiza imágenes al aparecer actores | Medio: tirones perceptibles | Formas y recursos preconfigurados; precarga del contenido del encuentro. |
| Exceso de nodos/procesos en decoración | Medio | Sprites estáticos sin scripts; agrupar sólo cuando el profiler lo justifique. |
| Proyectiles rápidos atraviesan objetivos | Medio | Conservar barrido y probar velocidades máximas; revisar capas/máscaras. |
| Tráfico aparece de forma injusta | Alto para experiencia | Telegraph visual/sonoro, zonas de spawn fuera de cámara y límites de concurrencia. |
| UI acoplada a clases concretas | Medio | Señales con datos simples; HUD no debe conocer la implementación interna de actores. |
| Cinemática y diálogo dejan control bloqueado | Alto | Un único dueño del estado de flujo; mismo cleanup al terminar u omitir. |
| Tucumanazo se diseña durante la implementación | Alto: retrabajo | Cerrar un documento de decisión pequeño antes de programar. |
| Arte legacy no cubre todas las acciones | Medio | Mantener placeholders explícitos y `TBD`; no inventar ni reemplazar assets en tareas técnicas. |
| Música o landmarks generan problemas de derechos | Alto | Material original y revisión específica; no copiar melodías, grabaciones ni marcas sin decisión. |
| Arquitectura crece más que el slice | Alto para un equipo pequeño | No crear servicios generales, plugins, behavior trees, ECS ni sistema de campaña hasta demostrar necesidad. |

## 10. Uso recomendado de modelos

### Modelo económico

Adecuado cuando el patrón y el criterio de terminado ya están definidos:

- crear recursos `.tres` repetitivos;
- conectar señales existentes;
- construir UI sencilla y textos;
- cargar datos de personajes, enemigos, proyectiles o encuentros;
- ajustar nombres, rutas, timings y valores aprobados;
- ampliar pruebas con casos equivalentes ya establecidos;
- mantener documentación e inventarios;
- componer capas/props estáticos con especificaciones precisas;
- integrar pistas y efectos ya preparados.

Cada tarea económica debe limitarse a pocos archivos y no redefinir contratos.

### Modelo de razonamiento superior

Justificado cuando el cambio afecta varios estados, contratos o tiempos:

- sesión y flujo principal;
- extracción de `CharacterDefinition` sin cambiar movimiento;
- salud, hitbox/hurtbox y cancelación de ataques;
- diseño e implementación inicial de combo/Tucumanazo;
- patrón base de IA y miniboss;
- encuentros y checkpoints deterministas;
- diálogos/cinemática con pausa, omisión y restauración de control;
- tráfico con física y spawning justo;
- diagnóstico de rendimiento o errores intermitentes.

El modelo superior debe producir primero una decisión concreta y pequeña; luego las variantes mecánicas pueden delegarse a un modelo económico.

## 11. Criterio global de terminado del vertical slice

El vertical slice se considera terminado cuando:

- puede jugarse desde selección hasta cierre sin herramientas del editor;
- ambos protagonistas pasan por el mismo flujo y contratos, con contenido pendiente claramente resuelto;
- movimiento, combate, combo, Tucumanazo, daño y respawn son consistentes;
- incluye enemigos básicos, miniboss, introducción, diálogos, checkpoint y cierre;
- Famaillá y el inicio de Ruta 38 son reconocibles con assets aprobados;
- cámara, HUD, parallax, tráfico, música y SFX funcionan durante una partida completa;
- pausar, omitir cinemática, morir y reiniciar no dejan estados residuales;
- sostiene 60 FPS en Windows PC; el hardware mínimo de referencia permanece **TBD**;
- no presenta errores del depurador ni crecimiento sostenido de nodos/memoria;
- el prototipo de referencia y los assets legacy no fueron eliminados o reemplazados sin autorización.
