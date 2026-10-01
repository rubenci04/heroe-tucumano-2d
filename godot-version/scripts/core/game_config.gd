class_name GameConfig
extends RefCounted
const WORLD_WIDTH: float = 8000.0
const GROUND_Y: float = 370.0
## SUSPENDED / deprecated: keep legacy heat logic and assets for future recovery.
const HEAT_ENABLED: bool = false
## Compatibilidad temporal para datos/firmas legacy. Ambos índices resuelven al único plano.
const LANES: Array[float] = [GROUND_Y,GROUND_Y]
const WALK_SPEED: float = 230.0
const GRAVITY: float = 1300.0
const JUMP_SPEED: float = 580.0
const LANE_DURATION: float = 0.2
const WORLD_LAYER: int = 1
## Player-supporting one-way roofs. Projectiles deliberately do not scan this layer.
const PLAYER_PLATFORM_LAYER: int = 64
const PLAYER_WORLD_MASK: int = WORLD_LAYER | PLAYER_PLATFORM_LAYER
const PLAYER_FRAMES = preload("res://assets/animations/player.tres")
const PLAYER_LAYER: int = 4
const ENEMY_LAYER: int = 8
const OBJECT_LAYER: int = 16
const PROJECTILE_LAYER: int = 32
