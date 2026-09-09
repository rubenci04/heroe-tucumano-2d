# Art Bible — Tucumán Rush

## Propósito y alcance

Esta guía define la dirección de los assets definitivos del vertical slice. Todo arte nuevo vive dentro de `res://art_v2/`; los archivos existentes en `res://assets/` y `res://audio/` son **LEGACY/REFERENCE** y no se borran, mueven ni reemplazan durante producción artística.

La resolución interna se mantiene en **800×450**. El arte debe privilegiar lectura arcade inmediata, siluetas claras y composición limpia a esa escala.

## Dirección visual

- Pixel art arcade de alta calidad, con sensibilidad de máquinas 16/32 bits.
- Personajes caricaturescos, expresivos y legibles en movimiento lateral.
- Protagonistas con altura visual aproximada de **80–100 px** en su pose de juego.
- Contornos oscuros coherentes: más fuertes en siluetas y zonas de contacto, más suaves dentro de materiales iluminados.
- Iluminación principal desde arriba e izquierda. Sombras hacia abajo y derecha; no mezclar direcciones de luz dentro del mismo plano.
- Paleta cálida, saturada y subtropical: ocres, naranjas, verdes de cañaveral, celestes de cielo, rojos y azules deportivos. Reservar valores muy claros para impactos, metal, calor y foco narrativo.
- Los escenarios deben reconocer Tucumán por landmarks, vegetación, arquitectura, cartelería y objetos locales antes que por texto explicativo.
- La animación debe priorizar anticipación, poses extremas, lectura de impacto y ciclos cortos; no perseguir realismo.

## Reglas de producción V2

- Usar `art_v2/characters/`, `art_v2/enemies/`, `art_v2/bosses/`, `art_v2/environments/`, `art_v2/props/`, `art_v2/vehicles/`, `art_v2/ui/` y `art_v2/effects/` según corresponda. Si una tarea futura aprueba audio final dentro de esta convención, se reservará `art_v2/audio/` sin mover el audio legacy.
- Entregar sprites con fondo transparente y punto de apoyo documentado para el suelo.
- Mantener una misma escala de píxel, grosor de contorno y dirección de luz entre familias de assets.
- Cada hoja o secuencia final debe declarar: nombre, escala objetivo, pivot/ground point, animación asociada y número de frames.
- Probar cada entrega sobre captura 800×450 antes de integrarla. La legibilidad tiene prioridad sobre detalle invisible a la resolución interna.
- No reutilizar assets legacy como arte final. Sí pueden permanecer visibles como referencia hasta una tarea explícita de sustitución.
- En contenido tucumano se usa **frutillas**, nunca “fresas”.

## Personajes principales

| Personaje | Silueta y vestuario | Actitud y lectura |
|---|---|---|
| **CIRUJA — San Martín** | Gorra negra gastada, lentes baratos, tatuajes, cicatrices, dientes faltantes, ropa deportiva y camiseta de San Martín. | Caótico pero simpático; la postura, la ropa y la expresión deben comunicar energía de calle sin volverlo desagradable. |
| **DECA — Atlético** | Pelo semicuidado, ropa deportiva más prolija, camiseta de Atlético y morral posible. | Más limpio y cuidado que Ciruja, con la misma escala, potencia visual y lenguaje de contorno. Ninguno debe parecer un personaje secundario. |
| **PALERMITANO** | Alto, musculoso, barba arreglada, man bun y ropa moderna excesivamente cuidada. | Presencia premium, arrogante y ridícula. Debe leerse como antagonista incluso en silueta. |
| **CAMPEONA DE LA EMPANADA** | Mujer mayor, abuela tucumana rellenita, anteojos, brazos fuertes de amasar, delantal y cofia de cocinero. | Firme, activa y cómica; nunca un objeto pasivo de rescate. |
| **EL GRANDOTE** | Enorme, traje demasiado ajustado, lentes negros y auricular. | Superior visualmente al Grandote básico por masa, proporción, detalle y poses, sin perder claridad de combate. |

## Escenario y ambientación

Famaillá y el inicio de Ruta 38 deben combinar ruta, cañaveral, cerros, comercios y señalética con una lectura subtropical cálida. Los fondos genéricos sólo son aceptables si se acompañan de detalles de alto impacto que permitan reconocer el lugar: cartel de Famaillá, puestos locales, naranjos, limones, frutillas, paradas de colectivo, cañaverales, vehículos regionales y arquitectura de ruta.

El fondo se organiza por profundidad: cielo/cerros, paisaje lejano, localidad o vegetación media, ruta y props jugables. Los objetos interactivos deben separarse visualmente del fondo sin recurrir a flechas o UI invasiva.

## Folklore futuro

Estos conceptos se reservan para fases futuras; no habilitan producción ni integración en el vertical slice actual.

- **Perro Familiar:** futuro Ingenio azucarero.
- **Luz Mala:** futuro Cementerio del Oeste.
- **Mate Cocido:** posible boss o entidad del Cementerio del Oeste.

## Criterio de aprobación artística

Un asset V2 está listo para integración cuando conserva lectura a 800×450, respeta escala, contorno y luz, usa la paleta acordada, tiene pivots documentados y no exige cambios de gameplay para funcionar. La aprobación visual no autoriza reemplazar el legacy: esa sustitución ocurre sólo en una tarea de integración específica.
