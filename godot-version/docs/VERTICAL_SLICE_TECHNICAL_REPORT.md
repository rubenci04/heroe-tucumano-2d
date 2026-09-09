# Informe técnico del vertical slice

Fecha de validación: 6 de septiembre de 2026.

## Resultado

**Estado técnico: READY para comenzar la fase artística y de pulido visual.**

El flujo `CHARACTER_SELECT → INTRO → GAMEPLAY → CHECKPOINT → MINIBOSS → CIERRE → RESULT` completó tres ciclos consecutivos en el mismo proceso. Cada ciclo incluyó una muerte y respawn desde checkpoint, muerte durante El Grandote, restauración de encuentros posteriores al checkpoint, nueva derrota del miniboss, cierre, RESULT y reinicio.

No se midió un cuello de botella que justifique pooling, cachés adicionales ni cambios de arquitectura.

## Entorno de medición

| Elemento | Valor |
|---|---|
| Sistema | Windows PC |
| Godot | 4.7.2 stable official |
| Render | OpenGL Compatibility |
| Resolución interna | 800×450 |
| CPU | AMD Ryzen 5 7600, 6 núcleos |
| GPU | Intel Arc B580 |
| Límite observado | 100 FPS, sincronizado con el monitor del entorno |

El hardware mínimo de referencia continúa **TBD**. Estas cifras validan el entorno disponible, no establecen requisitos mínimos para distribución.

## Pruebas ejecutadas

### Suite smoke

- Resultado: **550 verificaciones aprobadas, 0 fallos**.
- Ejecución renderizada con Godot 4, sin errores propios del proyecto.
- Cubre flujo, selección, introducción completa y omitida, movimiento, combate, carriles, salud, proyectiles, combo, Tucumanazo, enemigos, checkpoint, tráfico, miniboss, cierre, RESULT y reinicio.

### Integridad

- Resultado: **aprobado**.
- Archivos originales comprobados: **104**.
- Imágenes reutilizadas comprobadas: **100**.
- Errores: **0**.

### Perfil de ciclos completos

- Ciclos consecutivos: **3**.
- Encuentros completados por ciclo: **7**.
- Errores del arnés: **0**.
- Renderer y ventana activos durante la medición.
- Datos reproducibles: `tests/vertical_slice_profile.gd`.
- Resultado detallado: `validation/vertical_slice_profile.json`.

## Rendimiento observado

Las ventanas estables de los ciclos 2 y 3 dieron:

| Métrica | Resultado |
|---|---|
| FPS promedio | 100 FPS |
| FPS mínimo estable | 100 FPS |
| Tiempo de frame observado | aproximadamente 10 ms |
| Tiempo de proceso promedio | 10,42 ms |
| Tiempo de proceso máximo estable | 10,80 ms |
| Tiempo de física promedio | 0,21 ms |
| Tiempo de física máximo estable | 0,41 ms |

La carga representativa incluyó seis enemigos activos y dos vehículos simultáneos. El resultado deja margen frente al objetivo de 16,67 ms por frame para 60 FPS.

Las lecturas iniciales del monitor de `Performance` anteriores a su primera actualización se descartaron como calentamiento. No se observaron tirones sostenidos después de esa etapa.

## Memoria, nodos y recursos

| Estado | Nodos | Memoria estática aproximada |
|---|---:|---:|
| Sesión en reposo | 271 | 45,73–45,76 MiB después del primer ciclo |
| Carga representativa | 339 | hasta 46,18 MiB |
| Pico reservado informado por Godot | — | 57,37 MiB |

Después de tres reinicios:

- crecimiento de nodos: **0**;
- crecimiento de recursos: **0**; se mantuvieron **189**;
- diferencia de memoria entre el primer y tercer reinicio: **29.552 bytes** (aproximadamente 0,03 MiB), sin crecimiento de nodos o recursos asociado;
- nodos huérfanos: **0**;
- tweens activos en los puntos de control: **0**;
- timers de nodo: **8**, cantidad constante en todos los estados y ciclos;
- conexiones de progreso, checkpoint y derrota del miniboss: **1** cada una en todos los ciclos.

La variación pequeña de memoria es compatible con bookkeeping del asignador y cachés ya cargadas. No mostró acumulación de instancias ni recursos.

## Limpieza de runtime

En cada RESULT y después de cada reinicio se verificó:

- enemigos residuales: **0**;
- proyectiles residuales: **0**;
- vehículos residuales: **0**;
- miniboss duplicados: **0**;
- reproductores de audio: **9** constantes, uno de música y ocho voces SFX;
- duplicación de reproductores o conexiones: **0**;
- combo, Tucumanazo, checkpoint y progreso de sesión reiniciados;
- cámara sin límites, offset ni shake residuales;
- diálogo e INTRO inactivos al volver a selección.

## Problemas encontrados y correcciones

### Gamepad incompleto

El mapa semántico sólo tenía gamepad para selección, diálogo, Cabezazo y Tucumanazo. Faltaban movimiento, carriles, salto, proyectiles, pausa y reinicio.

Se añadieron bindings para:

- movimiento y carriles mediante stick izquierdo y cruceta;
- salto con botón A;
- Naranjazo y Cascotazo con hombros derecho e izquierdo;
- Cabezazo con X;
- Tucumanazo con Y;
- pausa con Start;
- reinicio con Back/View;
- selección y diálogos conservando A/B y cruceta.

La suite verifica ahora que todos los estados del vertical slice tengan bindings semánticos de gamepad y que los ejes del stick estén configurados.

No se encontraron problemas medidos de FPS, física, cámara, audio, spawns, limpieza o recursos que requirieran cambios de gameplay.

## Problemas pendientes

- Hardware mínimo de referencia para certificar 60 FPS: **TBD**.
- Prueba física con modelos concretos de gamepad: pendiente de QA con dispositivo conectado. El contrato `InputMap` y sus eventos están verificados automáticamente.
- Evaluación humana de sensación, dificultad y duración real de 10–15 minutos: pendiente de playtesting; no bloquea el inicio de la fase artística.
- Música definitiva para los estados del vertical slice, incluido RESULT: pendiente de producción musical. La ausencia de pista continúa siendo segura y silenciosa.

## Conclusión

La base mantiene 60 FPS con margen en el equipo disponible, completa tres ciclos sin residuos y conserva una cantidad estable de nodos, recursos, conexiones y reproductores. Las pruebas automatizadas y la verificación de integridad están en verde. El proyecto está **READY** para comenzar la fase artística y el pulido visual, manteniendo las decisiones de hardware mínimo y playtesting como validaciones posteriores.
