extends RefCounted
## Todos los valores de game feel de la arena prototipo. Ajustá acá.

# Visible content, viewport 400x225; not the transparent canvas. Ciruja stays unchanged.
const REFERENCE_VISIBLE_HEIGHT := 74.0
const CHARACTER_PROPORTIONS := {
	"ciruja": 1.0, "agente": 1.0, "campeona": 0.95,
	"hipster": 1.054, "grandote": 1.25, "palermitano": 1.3,
}
# Measured on the new 320x256 source frames: gun tip / throwing hand.
const BATCH_MUZZLE_SOURCE := {"agente": Vector2(110, 101), "hipster": Vector2(146, 132)}

# Altura objetivo del Hipster (jinete + monopatín) en px. Tocala acá; hitbox y punto de lanzamiento escalan solos.
const HIPSTER_TARGET_HEIGHT := 92.0
const TARGET_HEIGHT_OVERRIDE := {"hipster": HIPSTER_TARGET_HEIGHT}

static func target_height(character: String) -> float:
	if TARGET_HEIGHT_OVERRIDE.has(character):
		return float(TARGET_HEIGHT_OVERRIDE[character])
	return REFERENCE_VISIBLE_HEIGHT * float(CHARACTER_PROPORTIONS[character])

# Hit-stop (frames de render congelados al impactar a un enemigo)
const HITSTOP_FRAMES := 3
const HITSTOP_TIME_SCALE := 0.02
const PLAYER_HURT_HITSTOP_FRAMES := 2

# Impacto por personaje: hitstop (frames, 2-4), shake (px de pantalla), flash blanco (frames),
# knock (px/s de empuje inicial; decae con KNOCKBACK_DECAY). Grandote y jefe pegan más fuerte
# en la pantalla pero se desplazan menos (más masa).
const IMPACT_PROFILES := {
	"agente": {"hitstop": 2, "shake": 1.5, "flash": 2, "knock": 90.0},
	"hipster": {"hitstop": 2, "shake": 1.5, "flash": 2, "knock": 100.0},
	"grandote": {"hitstop": 4, "shake": 3.0, "flash": 3, "knock": 45.0},
	"palermitano": {"hitstop": 4, "shake": 3.5, "flash": 3, "knock": 22.0},
}
const IMPACT_DEFAULT := {"hitstop": 3, "shake": 2.0, "flash": 2, "knock": 70.0}
const IMPACT_REFERENCE_DAMAGE := 1.0   # daño que cuenta como golpe "normal"
const IMPACT_STRENGTH_MIN := 0.75      # multiplicador de shake/knock según daño recibido
const IMPACT_STRENGTH_MAX := 2.0
const IMPACT_HEAVY_DAMAGE := 3         # a partir de este daño el hit-stop sube un frame
const SHAKE_IMPACT_DURATION := 0.10
const KNOCKBACK_DECAY := 9.0           # 1/s, caída exponencial del empuje
const KNOCKBACK_MIN_SPEED := 3.0

static func impact_profile(character: String) -> Dictionary:
	return IMPACT_PROFILES.get(character, IMPACT_DEFAULT)

# Screen shake: intensidad en píxeles de pantalla, duración en segundos
const SHAKE_SHOT_INTENSITY := 1.5
const SHAKE_SHOT_DURATION := 0.06
const SHAKE_HURT_INTENSITY := 6.0
const SHAKE_HURT_DURATION := 0.25
const SHAKE_EXPLODE_INTENSITY := 4.0
const SHAKE_EXPLODE_DURATION := 0.18

# Muzzle flash
const MUZZLE_DURATION := 0.06
const MUZZLE_LENGTH := 14.0
const MUZZLE_WIDTH := 5.0
const MUZZLE_COLOR := Color(1.0, 0.92, 0.55)

# Chispas de impacto
const SPARK_COUNT := 7
const SPARK_SPEED := 140.0
const SPARK_LIFE := 0.22
const SPARK_SIZE := 1.5
const SPARK_COLOR := Color(1.0, 0.85, 0.3)

# Flash blanco del enemigo (frames)
const ENEMY_FLASH_FRAMES := 2

# Polvo al correr / aterrizar
const DUST_RUN_MIN_SPEED := 60.0
const DUST_RUN_INTERVAL := 0.12
const DUST_RUN_COUNT := 2
const DUST_LAND_COUNT := 8
const DUST_LAND_MIN_AIR_TIME := 0.15
const DUST_SPEED := 40.0
const DUST_LIFE := 0.35
const DUST_SIZE := 2.5
const DUST_COLOR := Color(0.85, 0.8, 0.7, 0.8)

# Explosión al morir un enemigo
const DEATH_COUNT := 18
const DEATH_SPEED := 160.0
const DEATH_LIFE := 0.45
const DEATH_SIZE := 2.5
const DEATH_BODY_OFFSET := Vector2(0.0, -24.0)
const DEATH_COLORS := [Color(1.0, 0.9, 0.4), Color(1.0, 0.5, 0.15), Color(0.9, 0.2, 0.1)]

# Skin de Ciruja en la arena prototipo (experimento de arte pixelado, no toca los assets originales)
enum CirujaSkin { ORIGINAL, VARIANTE_A_SATURADA, VARIANTE_B_APAGADA }
const CIRUJA_SKIN := CirujaSkin.ORIGINAL  # cambiar acá: ORIGINAL / VARIANTE_A_SATURADA / VARIANTE_B_APAGADA
const CIRUJA_SKIN_DIRS := {
	CirujaSkin.VARIANTE_A_SATURADA: "var_a_saturada",
	CirujaSkin.VARIANTE_B_APAGADA: "var_b_apagada",
}

# Carrera de Ciruja generada con PixelLab (8 cuadros en bucle). Solo reemplaza "Run"; el resto de animaciones no cambia.
const CIRUJA_RUN_PIXELLAB := false         # Keep the illustrated source; no pixel-art fallback.
const CIRUJA_RUN_PIXELLAB_CORREGIDO := true # true = gorra roja + piel morocha / false = colores originales de PixelLab
const CIRUJA_RUN_PIXELLAB_FPS := 10.0

# --- Animación procedural (solo sprites visuales, no hitbox) ---
# Ciruja: inclinación al correr (grados), respiración en idle, stretch/squash en salto/aterrizaje
const RUN_LEAN_DEG := 6.0
const RUN_LEAN_SMOOTH := 14.0
const BREATH_SPEED := 2.4          # ciclos por segundo
const BREATH_AMOUNT := 0.025       # variación de escala (0.025 = 2.5%)
const JUMP_STRETCH := 0.14         # estiramiento vertical al subir (a velocidad de salto completa)
const FALL_STRETCH := 0.06         # estiramiento al caer
const STRETCH_SMOOTH := 18.0
const LAND_SQUASH := 0.22          # aplastamiento al aterrizar
const LAND_SQUASH_TIME := 0.22
const LAND_MIN_AIR_TIME := 0.08
# Retroceso al disparar (Ciruja)
const PLAYER_SHOT_KICK := 3.0      # px hacia atrás
const PLAYER_SHOT_KICK_IN := 0.03
const PLAYER_SHOT_KICK_OUT := 0.12
# Enemigos
const ENEMY_ANTIC_PULL := 4.0      # px hacia atrás durante la anticipación
const ENEMY_ANTIC_SQUASH := 0.12   # agacharse
const ENEMY_ANTIC_LEAN_DEG := 7.0  # inclinación hacia atrás
const ENEMY_HIT_PUSH := 6.0        # px de empujón al recibir impacto
const ENEMY_HIT_LEAN_DEG := 8.0
const ENEMY_HIT_IN := 0.03
const ENEMY_HIT_OUT := 0.16
# Muerte de enemigos (copia del sprite animada con tweens)
const ENEMY_DEATH_DURATION := 0.7
const ENEMY_DEATH_SPIN_DEG := 100.0
const ENEMY_DEATH_PUSH := 28.0     # px hacia atrás
const ENEMY_DEATH_HOP := 14.0      # salto inicial
const ENEMY_DEATH_FALL := 6.0      # cuánto baja respecto al punto inicial
const ENEMY_DEATH_FADE_DELAY := 0.3

# --- Muertes con peso ---
# Cámara lenta (tiempo real) al matar a un enemigo grande: escala del tiempo y duración.
const DEATH_SLOWMO := {
	"grandote": {"scale": 0.3, "time": 0.45},
	"palermitano": {"scale": 0.2, "time": 0.75},
}
# Polvo al tocar el suelo el cuerpo: cantidad de bocanadas y ancho en px.
const DEATH_DUST := {
	"agente": {"count": 8, "spread": 22.0},
	"hipster": {"count": 10, "spread": 26.0},
	"grandote": {"count": 16, "spread": 36.0},
	"palermitano": {"count": 18, "spread": 40.0},
}
const DEATH_DUST_DEFAULT := {"count": 8, "spread": 22.0}
const DEATH_DUST_AT := 0.55            # fracción de la animación de muerte en que el cuerpo toca el suelo
const DEATH_DUST_FALLBACK_AT := 0.45   # idem con la caída por tweens (sin cuadros de muerte)
const DEATH_LINGER := 1.0              # s que el cuerpo queda en el suelo antes de desvanecerse
const DEATH_LINGER_HEAVY := 1.8        # idem para Grandote y jefe
const DEATH_FADE := 0.55
const GROUND_DUST_LIFE := 0.5
const GROUND_DUST_SPEED := 38.0
const GROUND_DUST_SIZE := 2.6

# --- Casquillos y fogonazos de enemigos ---
const CASING_COLOR := Color(0.95, 0.72, 0.25)
const CASING_GRAVITY := 520.0
const CASING_BOUNCE := 0.35
const CASING_SPEED_X := Vector2(18.0, 45.0)
const CASING_SPEED_UP := Vector2(60.0, 110.0)
const CASING_LIFE := 1.6
const ENEMY_MUZZLE_SIZE := 0.8

# --- Proyectiles por código: giro (°/s), rebote (px) y frecuencia (saltos/s), estela y sombra ---
const PROJECTILE_FX := {
	"bottle": {"spin": 0.0, "hop": 6.0, "hop_hz": 2.2, "trail": 9, "trail_width": 3.0, "trail_color": Color(0.75, 0.9, 1.0, 0.55), "shadow": 1.0},
	"hipster_coffee": {"spin": 380.0, "hop": 4.0, "hop_hz": 2.6, "trail": 8, "trail_width": 3.0, "trail_color": Color(0.55, 0.35, 0.2, 0.55), "shadow": 1.0},
	"coffee": {"spin": 300.0, "hop": 3.0, "hop_hz": 2.0, "trail": 10, "trail_width": 4.0, "trail_color": Color(0.5, 0.32, 0.2, 0.6), "shadow": 1.2},
	"agent_orb": {"spin": 0.0, "hop": 0.0, "hop_hz": 0.0, "trail": 6, "trail_width": 2.5, "trail_color": Color(1.0, 0.9, 0.4, 0.6), "shadow": 0.7},
	"bullet": {"spin": 0.0, "hop": 0.0, "hop_hz": 0.0, "trail": 6, "trail_width": 2.0, "trail_color": Color(1.0, 0.9, 0.4, 0.6), "shadow": 0.6},
	"orange": {"spin": 420.0, "hop": 0.0, "hop_hz": 0.0, "trail": 6, "trail_width": 2.5, "trail_color": Color(1.0, 0.6, 0.15, 0.5), "shadow": 0.8},
	"stone": {"spin": 480.0, "hop": 0.0, "hop_hz": 0.0, "trail": 6, "trail_width": 2.5, "trail_color": Color(0.7, 0.68, 0.62, 0.5), "shadow": 0.9},
}
const PROJECTILE_FX_DEFAULT := {"spin": 0.0, "hop": 0.0, "hop_hz": 0.0, "trail": 5, "trail_width": 2.0, "trail_color": Color(1, 1, 1, 0.35), "shadow": 0.8}
# Lo que lanza el Palermitano se trata como "piedra" pesada: giro lento, estela larga y sombra grande.
const PROJECTILE_FX_BY_EMITTER := {
	"palermitano": {"spin": 480.0, "hop": 3.0, "hop_hz": 1.8, "trail": 12, "trail_width": 4.5, "trail_color": Color(0.62, 0.56, 0.5, 0.6), "shadow": 1.4},
}
const PROJECTILE_SHADOW_WIDTH := 6.0
const PROJECTILE_SHADOW_FLATNESS := 0.28
const PROJECTILE_SHADOW_ALPHA := 0.28
const PROJECTILE_SHADOW_HEIGHT_RANGE := 160.0
const PROJECTILE_SHADOW_MIN_SCALE := 0.4

# --- Jefe Palermitano ---
const BOSS_TRIGGER_X := 400.0          # Ciruja cruza esta X y arranca la intro
const BOSS_INTRO_DURATION := 2.0       # s con cámara bloqueada, nombre y barra apareciendo
const BOSS_INTRO_ZOOM := 1.25
const BOSS_INTRO_ZOOM_IN := 0.5        # s en acercarse al jefe
const BOSS_INTRO_ZOOM_OUT := 0.45      # s en volver al plano fijo de la arena
const BOSS_ACTIVATE_REACTION := 0.35   # s de pausa del jefe al terminar la intro, antes de decidir
const BOSS_NAME := "EL PALERMITANO"
const BOSS_SUBTITLE := "Se llevó a la Campeona"
const BOSS_PHASE2_THRESHOLD := 0.5     # fracción de vida a la que entra la fase 2
const BOSS_PHASE2_SPEED_MULT := 1.4    # movimiento
const BOSS_PHASE2_TEMPO_MULT := 0.7    # multiplica esperas/cooldowns/telegraphs (menor = más rápido)
const BOSS_PHASE2_ANIM_SPEED := 1.25
const BOSS_PHASE2_TINT := Color(1.0, 0.82, 0.78)
const BOSS_PHASE2_SHAKE := 5.0
const BOSS_PHASE2_BANNER := "¡SE ENOJÓ!"
const BOSS_PHASE2_BANNER_TIME := 1.1
# La cadena queda preparada (estado de ataque y alcance intactos) pero sin animación propia.
const BOSS_CHAIN_ANIMATED := false

# --- HUD y pantallas (texto legible con borde, estilo cartoon) ---
const HUD_TEXT_COLOR := Color(1.0, 0.88, 0.15)
const HUD_OUTLINE_COLOR := Color(0.14, 0.07, 0.03)
const HUD_OUTLINE_RATIO := 0.3         # grosor del borde = tamaño de fuente × ratio
const HUD_PANEL_FILL := Color(0.16, 0.08, 0.04, 0.82)
const HUD_PANEL_BORDER := Color(1.0, 0.72, 0.2)
const HUD_GAME_OVER_TITLE := "¡CIRUJA CAYÓ!"
const HUD_GAME_OVER_TEXT := "La Campeona sigue cautiva en manos del Palermitano.\nNo la dejes sola: ¡reintentá!"
const HUD_VICTORY_TITLE := "¡EL PALERMITANO HUYE AL INGENIO!"
const HUD_VICTORY_TEXT := "Ciruja sigue tras la Campeona que se llevaron de Famaillá.\nPróximo destino: Ingenio Arcor."
const HUD_RESTART_HINT := "R: volver a jugar"
const HUD_RESULT_DELAY := 1.4          # s entre el último golpe/caída y la pantalla final
const HUD_HEAD_CROP := 0.46            # alto del recorte de cabeza / alto de la silueta
const HUD_HEAD_OFFSET_X := 8.0

# --- Parallax de la arena (cada capa avanza esta fracción del desplazamiento de Ciruja) ---
const BACKDROP_SCROLL_SKY := 0.06
const BACKDROP_SCROLL_PANORAMA := 0.35
const BACKDROP_SKY_SCALE := 0.51
const BACKDROP_SKY_TILE_PX := 1561.0   # ancho útil en textura (el resto se funde con el comienzo, sin espejar)
const BACKDROP_SKY_OVERLAP := 0.12007
const BACKDROP_SKY_BOTTOM_Y := 395.0   # borde inferior del cielo (queda tapado por el panorama)
const BACKDROP_PANORAMA_REGION := Rect2(100.0, 440.0, 1600.0, 260.0)
const BACKDROP_PANORAMA_SCALE := 0.84
const BACKDROP_PANORAMA_BOTTOM_Y := 372.0
const HUD_TITLE_SIZE := 48
const HUD_TITLE_SIZE_LONG := 36        # para títulos largos, que no entran a 48 en 800 px
const HUD_TITLE_SHORT_CHARS := 20
