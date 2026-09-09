# Aceptación del vertical slice — Famaillá / inicio de Ruta 38

## Propósito

Este documento es la referencia verificable para decidir cuándo el vertical slice está terminado. Aplica al proyecto Godot 4 ubicado en `godot-version/` y no autoriza desarrollar contenido fuera del alcance definido aquí.

## Alcance aprobado

| Área | Criterio de alcance |
|---|---|
| Plataforma inicial | Windows PC. |
| Rendimiento | 60 FPS estables durante la ruta de prueba completa. El hardware mínimo concreto permanece **TBD**. |
| Resolución interna | 800×450. Sólo puede cambiarse con una razón técnica demostrable y una actualización aprobada de este documento. |
| Duración | Entre 10 y 15 minutos en una primera partida normal. |
| Recorrido | Famaillá y el comienzo de Ruta 38. La demo termina antes de que Acheral sea un nivel completo. |
| Controles | Teclado y gamepad. Se conservan los bindings existentes cuando sean compatibles. |
| Checkpoints | Un único checkpoint. Su posición exacta permanece **TBD** hasta componer definitivamente el recorrido. |

Quedan fuera de este slice: Ingenio, Dique Escaba, Simoca, San Miguel de Tucumán, Cementerio del Oeste, Parque 9 de Julio, campaña completa, guardado persistente, multijugador, online, versión móvil y bosses de niveles posteriores.

## Criterios de aceptación

### Inicio y flujo

- Desde una ejecución nueva, el usuario puede elegir al Hincha de San Martín de Tucumán o al Hincha de Atlético Tucumán.
- La selección funciona con teclado y gamepad, permite confirmar y volver antes de iniciar la partida.
- Ambos personajes recorren el mismo flujo, con idénticas estadísticas base, física, velocidad, salto, vida, daño e hitboxes.
- Las diferencias entre protagonistas se limitan a apariencia, animaciones, retrato, nombre, descripción y voz/frases.
- La introducción presenta el conflicto de Famaillá, al empresario palermitano, a sus secuaces y a la Campeona de la Empanada con participación propia.
- Omitir la introducción y reproducirla completa entregan exactamente el mismo estado inicial jugable.
- La demo tiene un cierre inequívoco antes de Acheral, con opciones funcionales de reiniciar o salir.

### Movimiento y cámara

- El protagonista se mueve, salta y cambia de carril conforme a los controles definidos por el proyecto.
- La física es consistente a las tasas de actualización que soporte Godot durante la prueba.
- La `Camera2D` sigue al protagonista con suavizado y mantiene el recorrido dentro de los límites previstos.
- El juego mantiene la resolución interna de 800×450 y el HUD sigue siendo legible.

### Combate y daño

- El ataque cuerpo a cuerpo principal es el **Cabezazo**: tiene inicio, ventana de impacto, recuperación y alcance frontal verificables.
- El proyectil principal es el **Naranjazo**: se dispara en la dirección y carril correctos, aplica daño una sola vez por impacto válido y se elimina al terminar su vida útil.
- El Cascotazo puede permanecer sin implementar; si aparece, no reemplaza ni altera el Naranjazo.
- Jugador, enemigos, proyectiles, plataformas y objetos relevantes tienen colisiones funcionales.
- Un atacante no puede dañarse a sí mismo, dañar aliados ni impactar objetivos de otro carril.
- Recibir daño aplica invulnerabilidad temporal, feedback y muerte/respawn sin daño duplicado por frame.

### Combo y Tucumanazo

- Los impactos válidos construyen un combo y actualizan un indicador de HUD.
- El combo se rompe según la regla documentada cuando vence su ventana o el jugador recibe daño.
- Los impactos válidos contribuyen al medidor especial.
- Con el medidor lleno, el jugador puede activar el **Tucumanazo**.
- El Tucumanazo es un ataque de área y produce feedback visual y sonoro fuerte, pausa breve de impacto y screen shake.
- La frase asociada puede ser “¡VAMO' URA!”.
- Los valores de carga, daño, radio y duración son **TBD** hasta playtesting, pero la implementación debe centralizarlos como parámetros ajustables.

### Enemigos y miniboss

- El slice contiene al menos un enemigo básico cuerpo a cuerpo y uno de rango, ambos con comportamiento legible de acercamiento, ataque y recuperación.
- Los enemigos respetan carriles, reciben daño una sola vez por impacto y se liberan correctamente tras ser derrotados.
- El miniboss provisional es **El Grandote**, guardaespaldas corpulento del empresario, con traje ajustado, lentes negros y auricular.
- El Grandote usa como máximo tres patrones: embestida, puñetazo y salto/golpe al suelo.
- Cada patrón del miniboss tiene una telegráfica clara y no se superpone con otro estado inválido.
- El Perro Familiar no aparece en este vertical slice.

### Nivel, ambientación y progreso

- Famaillá y el inicio de Ruta 38 se reconocen mediante los assets aprobados, parallax, landmarks y props disponibles.
- La composición ambiental no crea lógica por frame en decoración estática.
- El tráfico y los elementos ambientales móviles aparecen fuera de cámara o con advertencia suficiente, respetan carriles y un límite de instancias, y no generan situaciones inevitables.
- Cada encuentro se activa una vez, termina de manera determinista y no deja referencias o spawns residuales.
- El único checkpoint guarda el progreso acordado y, tras morir, restaura al jugador sin duplicar recompensas, pickups o enemigos.

### Interfaz, diálogo y audio

- El HUD muestra vida, puntaje, monedas, combo, medidor especial y, durante el miniboss, su estado relevante.
- Los valores del HUD se actualizan por eventos relevantes y no dependen de consultar el estado completo del jugador cada frame.
- Los diálogos muestran hablante y texto, permiten avance y no dejan el control bloqueado al terminar, omitir o pausar.
- Música y efectos tienen volumen independiente; las transiciones entre introducción, juego y miniboss no duplican reproducción.
- La ausencia de una pista o efecto falla de forma segura sin bloquear la partida.

### Calidad técnica

- No hay errores nuevos en el depurador de Godot durante la ruta de prueba.
- Pausar, reanudar, morir, usar el checkpoint, terminar la demo y reiniciar no dejan nodos, temporizadores, audio ni estado de combate acumulados.
- En un perfil de una partida completa, CPU, física y memoria no muestran crecimiento sostenido ni tirones atribuibles a creación evitable de recursos durante el juego.
- El proyecto y sus assets legacy/referencia siguen intactos salvo cambios autorizados por una tarea posterior.

## Ruta de prueba reproducible

### Preparación

1. Ejecutar el proyecto Godot 4 en Windows PC con la resolución interna configurada en 800×450.
2. Usar teclado y luego gamepad. Confirmar que ambos dispositivos permiten navegar la selección, jugar y pausar según los bindings vigentes.
3. Activar el monitor de FPS y el depurador de Godot. Usar el profiler durante una pasada completa cuando el contenido esté integrado.

### Recorrido principal

1. Iniciar una partida y elegir San Martín; repetir la ruta completa con Atlético.
2. Reproducir una vez la cinematográfica de Famaillá y repetirla omitiéndola. Confirmar que ambos caminos entregan el mismo control, posición, vida y estado inicial.
3. Avanzar por Famaillá y el inicio de Ruta 38 durante una partida normal de 10–15 minutos.
4. Probar movimiento, salto y cambio de carril sobre terreno, plataformas y vehículos aplicables.
5. Golpear un enemigo con Cabezazo y derrotar enemigos con Naranjazo; verificar dirección, carril, daño único y eliminación de proyectiles.
6. Acumular combo mediante impactos válidos, permitir que venza su ventana y recibir daño para verificar el reinicio del combo.
7. Llenar el medidor y activar Tucumanazo; verificar área, consumo único, pausa de impacto, screen shake, audio y retorno a control normal.
8. Activar el checkpoint, morir de forma controlada y continuar. Verificar posición y que enemigos, pickups y recompensas se restauren conforme a la regla final documentada.
9. Completar los encuentros previos y enfrentar a El Grandote. Observar y esquivar/recibir cada patrón: embestida, puñetazo y salto/golpe al suelo.
10. Terminar el encuentro, reproducir el cierre de demo y usar reiniciar. Confirmar una nueva partida limpia.

### Regresión y rendimiento

1. Repetir pausa/reanudar durante diálogo, combate, Tucumanazo y miniboss.
2. Repetir muerte, checkpoint, final y reinicio al menos tres veces en la misma sesión.
3. Confirmar ausencia de errores del depurador y de duplicación audible de música/SFX.
4. Registrar FPS, tiempo de física, uso de CPU, memoria y cantidad de nodos al inicio, después de checkpoint y después de tres reinicios. El resultado debe mantenerse estable y sostener 60 FPS.
5. Ejecutar las pruebas smoke existentes después de cualquier cambio de gameplay. La línea base actual cubre movimiento, salto, carriles, colisiones, proyectiles, pickups, plataformas, pausa, final y muerte.

## Decisiones aún pendientes

- Hardware mínimo de referencia para medir los 60 FPS.
- Protagonista seleccionado por defecto.
- Asignación concreta de assets legacy para la apariencia, animaciones, retrato y voz del hincha de Atlético.
- Valores definitivos de carga, daño, radio y duración del Tucumanazo, tras playtesting.
- Posición exacta del checkpoint y detalle de qué recursos se restauran.
- Textos finales de diálogo, música original y efectos sonoros definitivos.
