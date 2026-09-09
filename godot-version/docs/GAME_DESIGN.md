# Game Design

## Visión general

**Tucumán Rush** es un arcade 2D de acción y humor, ambientado en Tucumán, Argentina. Su tono es caricaturesco, absurdo y afectuoso con la cultura local: el chiste nunca está separado del lugar, los personajes o el conflicto.

La campaña comienza durante un fin de semana en la entrada de Famaillá. Mientras uno de los protagonistas come empanadas, un empresario multimillonario palermitano llega con sus secuaces, secuestra a la Campeona de la Empanada y busca apropiarse de su receta para vender una absurda “empanada tucumana deconstruida” en Palermo. Los dos protagonistas lo persiguen por Tucumán.

## Pilares

1. **Acción arcade inmediata.** Movimiento, ataques, enemigos y obstáculos legibles en pocos segundos.
2. **Tucumán reconocible.** Cada zona combina fondos de ruta o ciudad con landmarks, comercios, transporte, productos y costumbres que permitan reconocerla.
3. **Humor con afecto.** La exageración, las rivalidades y la caricatura celebran la identidad local; los personajes deben resultar queribles.
4. **Dúo equivalente.** San Martín y Atlético son opciones jugables equivalentes. La rivalidad alimenta los diálogos, pero ninguno es una elección inferior.
5. **Campaña de persecución.** El empresario reaparece, provoca y huye hasta el combate final.

## Core loop

1. Elegir protagonista.
2. Avanzar por un tramo del nivel, derrotando secuaces y evitando obstáculos.
3. Recoger recursos locales y objetos de recuperación.
4. Usar ataques básicos, situacionales y especiales para resolver encuentros.
5. Llegar a un hito local, enfrentar una oleada o jefe y continuar la persecución.

El juego debe sostener partidas cortas, lectura visual clara y un ritmo de arcade. La duración de niveles, cantidad de vidas, checkpoints, dificultad y sistema de continuaciones son **TBD**.

## Personajes jugables

### Hincha de San Martín de Tucumán

Caricatura deliberadamente extrema: aspecto desalineado, pocos dientes, cicatrices, tatuajes, gorra gastada, lentes de sol baratos y señales de haber tenido una noche complicada. Su personalidad es agresiva, directa y querible. Debe ser gracioso y memorable, nunca presentado simplemente como desagradable.

### Hincha de Atlético Tucumán

Contraste visual y cómico: apariencia más prolija, pelo largo cuidado, shampoo, acondicionador, skincare, accesorios cuidados y una actitud algo más refinada. Su seguridad y presencia son fuente de humor frente al desorden del hincha de San Martín.

### Relación entre protagonistas

Ambos intercambian burlas por la rivalidad futbolística y por sus estilos opuestos. Funcionan como héroes equivalentes, cooperan frente al antagonista y comparten la motivación de rescatar a la Campeona de la Empanada.

Cooperativo local, cooperativo en línea, diferencias concretas de estadísticas y habilidades exclusivas por personaje: **TBD**.

## Antagonista y Campeona

### Empresario palermitano

Empresario multimillonario, hipster exagerado, arrogante y ridículo. Secuestra a la Campeona para apropiarse de la receta y comercializarla como una “empanada tucumana deconstruida”. Es un antagonista recurrente: provoca, envía secuaces y escapa durante la campaña.

Su voz debe distinguirlo con claridad de los personajes locales. Habla como un palermitano pretencioso y empresarial, con vocabulario de marketing, gastronomía moderna, startups, branding y experiencias premium. No usa “ura”, modismos tucumanos ni expresiones provinciales propias de Tucumán. El humor surge de su arrogancia, su pretensión y el contraste cultural, sin convertirlo en una caricatura ofensiva de una clase social real.

Nombre, empresa, secuaces concretos, estilo de combate final y destino posterior a la derrota: **TBD**.

### Campeona de la Empanada

Es una mujer mayor tucumana: abuela rellenita, con anteojos, brazos fuertes de amasadora, muchos años de experiencia y una receta tradicional. Tiene personalidad fuerte, diálogos y presencia cómica. No es un objeto pasivo: puede opinar sobre la persecución, frustrar los planes del empresario y participar activamente de la resolución narrativa. Su diseño no debe presentarla como una joven glamorosa genérica.

Nombre, voz, habilidades, frecuencia de aparición y grado de participación jugable: **TBD**.

### Identidad de voz y vocabulario

Los protagonistas y personajes locales pueden usar expresiones y giros tucumanos cuando correspondan a su personalidad, sin repetirlos en cada frase. En textos y elementos ambientales vinculados al producto local se usa **frutillas**; no se usa “fresas”.

## Combate y sistemas

Las acciones y nombres locales se incorporan cuando ayudan a la identidad y lectura del juego:

| Nombre | Rol actual |
|---|---|
| Naranjazo | Ataque o proyectil basado en naranjas. |
| Cascotazo | Ataque o proyectil basado en piedras. |
| Cabezazo | Ataque de corto alcance. |
| Tucumanazo | Ataque especial o sistema de combo; implementación **TBD**. |
| “¡Vamo' ura!” | Expresión de celebración, reacción o refuerzo de identidad; uso exacto **TBD**. |

Controles definitivos, inventario, munición, recursos, daño, invulnerabilidad, combos, power-ups y economía: **TBD**. La prioridad del vertical slice es comprobar que el combate sea claro, divertido y compatible con los dos protagonistas antes de cerrar esos sistemas.

## Progresión

La progresión narrativa es una persecución territorial: el empresario escapa a través de Tucumán y deja obstáculos, secuaces o jefes ligados a cada ambiente. La progresión jugable debe alternar combate, obstáculos, cambios de ritmo y set pieces locales.

Desbloqueos, selección de nivel, mejoras persistentes, ranking, dificultad adaptativa y finales alternativos: **TBD**.

## Campaña planeada

| Nivel | Ubicación | Dirección de juego |
|---|---|---|
| 1 | Famaillá / Ruta 38 | Inicio de la persecución. Famaillá → Acheral → Monteros → León Rougés → Villa Quinteros → Río Seco. |
| 2 | Ingenio azucarero | Interior industrial con vapor, calderas, cintas, maquinaria, azúcar, líquidos peligrosos y secuaces vestidos como obreros. Finaliza de noche; jefe: representación fantástica y gigantesca del Perro Familiar. |
| 3 | Dique Escaba | Agua, embarcaciones, estructuras del dique y naturaleza. Mecánicas acuáticas: **TBD**. |
| 4 | Simoca | Feria, gauchos, caballos, sulkys, puestos y cultura local. Segmento o persecución sobre sulky: **TBD**. |
| 5 | San Miguel de Tucumán / Cementerio del Oeste | Microcentro seguido por nivel sobrenatural con fantasmas, estatuas y mausoleos. |
| Final | Parque 9 de Julio | Combate final cerca del reloj floral, derrota del empresario y rescate de la Campeona. |

La campaña completa no es el objetivo actual de producción.

## Música

Banda sonora original retro inspirada de forma general en cumbia tucumana, música tropical, folklore tucumano, chiptune de 16/32 bits y música arcade. No se copiarán melodías ni grabaciones de artistas existentes.

Instrumentación, temas por nivel, tratamiento de jefes y dirección de audio detallada: **TBD**.

## Objetivo actual: vertical slice

El primer objetivo de producción es un vertical slice muy pulido basado en Famaillá y el inicio de Ruta 38. Debe demostrar:

- identidad visual y humor local;
- selección o representación de los dos héroes equivalentes;
- desplazamiento, combate y obstáculos de base;
- recursos locales integrados al juego;
- una breve introducción narrativa con el empresario y la Campeona;
- un recorrido que establezca la persecución hacia el sur.

El vertical slice no debe comprometer decisiones definitivas de campaña, balance, progresión persistente ni Tucumanazo.
