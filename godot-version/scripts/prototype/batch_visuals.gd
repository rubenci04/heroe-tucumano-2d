extends Node
## Visual de personajes con los cuadros nuevos (characters/lote2_cuadros -> assets/animations/generated).
## Compartido por la arena prototipo y la ruta 38: cambia solo el SpriteFrames del nodo visual, su escala
## proporcional y su anclaje a los pies. Los scripts de actor (movimiento, daño, ataques) no cambian.

const CFG = preload("res://scripts/prototype/feel_config.gd")
const CHARACTER_SCALE = preload("res://scripts/prototype/character_scale.gd")
const BATCH_FRAMES := "res://assets/animations/generated/"
const FEET_Y := 240.0  # y de los pies en el lienzo 320x256 de los cuadros nuevos

const CIRUJA_ALIASES := {&"Run": &"correr", &"Punch": &"pinazo", &"Headbutt": &"embestida", &"Death": &"muerte"}
const GRANDOTE_ALIASES := {
	&"grandote_run": &"correr", &"grandote_punch": &"punio", &"grandote_ground_slam": &"golpe_piso", &"Death": &"muerte",
}

var _entries: Array[Dictionary] = []


func _ready() -> void:
	# Después de la animación procedural, igual que la arena prototipo.
	process_priority = 100


## Cambia los cuadros de un actor. aliases: nombre de animación del actor -> carpeta del lote.
## El actor conserva sus colisiones; se escala con CHARACTER_SCALE (Ciruja no cambia de escala).
func attach(actor: Node2D, character: String, aliases: Dictionary) -> bool:
	var path := BATCH_FRAMES + character + ".tres"
	if not ResourceLoader.exists(path):
		push_warning("Build character frames first: " + path)
		return false
	var incoming := load(path) as SpriteFrames
	var sprite: AnimatedSprite2D = actor.visual
	if character != "ciruja" and not actor.has_meta("original_visible_height"):
		CHARACTER_SCALE.remember(actor)
	var frames: SpriteFrames = sprite.sprite_frames.duplicate(true)
	# Cada carpeta queda disponible con su nombre; los alias puentean los estados existentes.
	for name in incoming.get_animation_names():
		_copy_animation(incoming, name, frames, name)
	for name in aliases:
		if incoming.has_animation(aliases[name]):
			_copy_animation(incoming, aliases[name], frames, name)
	# Idle = f_00 de ajustar_gorra (Ciruja, parado y neutro) o primera pose de correr (resto).
	if incoming.has_animation(&"correr"):
		var idle_name: StringName = actor.character_definition.idle_animation if character == "ciruja" else &"Idle"
		if not frames.has_animation(idle_name):
			frames.add_animation(idle_name)
		frames.clear(idle_name)
		var idle_texture := incoming.get_frame_texture(&"correr", 0)
		if character == "ciruja" and incoming.has_animation(CFG.IDLE_SOURCE_ANIMATION):
			idle_texture = incoming.get_frame_texture(CFG.IDLE_SOURCE_ANIMATION, CFG.IDLE_SOURCE_FRAME)
		frames.add_frame(idle_name, idle_texture)
		frames.set_animation_speed(idle_name, 1.0)
		frames.set_animation_loop(idle_name, true)
	var current := sprite.animation
	sprite.sprite_frames = frames
	sprite.play(current)
	sprite.set_meta("batch_character", character)
	sprite.set_meta("batch_ground_y", FEET_Y)
	sprite.set_meta("batch_visual_scale", sprite.scale.y)
	actor.set_meta("prototype_character", character)
	# Ciruja conserva escala; el resto toma la altura objetivo de feel_config.
	CHARACTER_SCALE.apply(actor, character)
	if character == "ciruja":
		_refit_player_body(actor)
	var entry := {"actor": actor, "sprite": sprite, "character": character}
	_entries.append(entry)
	sprite.animation_changed.connect(_anchor.bind(sprite))
	sprite.frame_changed.connect(_anchor.bind(sprite))
	_anchor(sprite)
	if character == "palermitano":
		actor.health_component.damaged.connect(func(_amount, _health, _source):
			if actor.boss_state in [actor.BossState.DECIDE, actor.BossState.RECOVERY]:
				sprite.play(&"golpes_recibidos"))
	return true


static func boss_aliases() -> Dictionary:
	return {
		&"boss_run": &"correr", &"boss_idle": &"idle", &"boss_punch": &"golpe_v2" if CFG.BOSS_CHAIN_ANIMATED else &"idle",
		&"boss_joke": &"idle_v2", &"boss_order": &"idle_v2", &"Death": &"derrota",
	}


## Sprite sin script de actor (Campeona): cuadros, altura fija y anclaje a los pies.
func attach_npc(sprite: AnimatedSprite2D, character: String, start_animation: StringName) -> bool:
	var path := BATCH_FRAMES + character + ".tres"
	if not ResourceLoader.exists(path):
		push_warning("Build character frames first: " + path)
		return false
	sprite.sprite_frames = load(path) as SpriteFrames
	sprite.play(start_animation)
	sprite.set_meta("batch_character", character)
	sprite.set_meta("batch_ground_y", FEET_Y)
	sprite.set_meta("batch_static_actor", true)
	CHARACTER_SCALE.apply_npc(sprite, character)
	sprite.set_meta("batch_visual_scale", sprite.scale.y)
	_entries.append({"actor": sprite, "sprite": sprite, "character": character})
	sprite.animation_changed.connect(_anchor.bind(sprite))
	sprite.frame_changed.connect(_anchor.bind(sprite))
	_anchor(sprite)
	return true


## Deja de animar un sprite (p. ej. la Campeona cuando se la llevan de cámara).
func release(sprite: Node) -> void:
	for index in range(_entries.size() - 1, -1, -1):
		if _entries[index].sprite == sprite:
			_entries.remove_at(index)


## Alias de enemigos según su definición (los nombres de animación vienen del .tres del enemigo).
static func enemy_aliases(enemy: Node) -> Dictionary:
	var definition = enemy.definition
	match enemy.archetype:
		"agente":
			return {definition.run_animation: &"correr", definition.attack_animation: &"disparar", &"Punch": &"punio", &"Death": &"muerte"}
		"hipster":
			return {definition.run_animation: &"avanzar_idle", definition.attack_animation: &"tirar_cafe", &"Death": &"caida"}
		"grandote":
			return {definition.run_animation: &"correr", definition.attack_animation: &"punio", &"grandote_ground_slam": &"golpe_piso", &"Death": &"muerte"}
	return {}


## Punto de lanzamiento medido sobre el cuadro nuevo (mano/cañón). origin llega en mundo, sin la escala del actor.
static func muzzle_origin(emitter: Node2D, origin: Vector2) -> Vector2:
	var character: String = emitter.get_meta("prototype_character", "")
	var origin_world := emitter.global_position + (origin - emitter.global_position) * emitter.scale
	if not CFG.BATCH_MUZZLE_SOURCE.has(character):
		return origin_world
	var socket: Vector2 = CFG.BATCH_MUZZLE_SOURCE[character] - Vector2(160, 240)
	var mirrored: bool = emitter.facing < 0 if character == "hipster" else emitter.facing > 0
	if mirrored:
		socket.x = -socket.x
	return emitter.visual.to_global(socket)


func _process(_delta: float) -> void:
	for index in range(_entries.size() - 1, -1, -1):
		var entry: Dictionary = _entries[index]
		if not is_instance_valid(entry.actor):
			_entries.remove_at(index)
			continue
		_update_pose(entry.actor, entry.sprite, entry.character)
		_anchor(entry.sprite)


func _update_pose(actor: Node2D, sprite: AnimatedSprite2D, character: String) -> void:
	if character == "palermitano" and actor.get("boss_state") != null and actor.active:
		if actor.boss_state == actor.BossState.DECIDE:
			var idle: StringName = &"idle_v2" if actor.last_pattern == actor.Pattern.SUMMON_AGENTS else &"idle"
			if sprite.animation != &"golpes_recibidos" or not sprite.is_playing():
				sprite.play(idle)
	if character == "hipster":
		sprite.flip_h = actor.facing < 0  # el arte nuevo del monopatín mira a la derecha
	if character == "grandote" and actor.get("archetype") == "grandote" and actor.active_attack_kind == actor.AttackKind.GROUND_SLAM:
		# El golpe en piso tenía 13 poses; sus etapas se mapean a los 7 cuadros nuevos.
		if actor.ai_state == actor.AIState.TELEGRAPH:
			var progress: float = 1.0 - actor._state_remaining / actor.GRANDOTE_SLAM_DEFINITION.startup_duration
			sprite.frame = clampi(int(progress * 4.0), 0, 3)
		elif actor.ai_state == actor.AIState.ATTACK:
			sprite.frame = 4
		elif actor.ai_state == actor.AIState.RECOVERY:
			sprite.frame = 5 if actor._state_remaining > actor.GRANDOTE_SLAM_DEFINITION.recovery_duration * 0.5 else 6


func _anchor(sprite: AnimatedSprite2D) -> void:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null:
		return # animation_changed puede llegar antes de que Godot reinicie el cuadro.
	var feet_y := float(sprite.get_meta("batch_ground_y"))
	var base_scale: float = sprite.get_meta("batch_visual_scale", sprite.scale.y)
	sprite.scale = Vector2.ONE * base_scale * Vector2(sprite.get_meta("pose_multiplier", Vector2.ONE))
	# Sprite centrado: y=240 del lienzo cae sobre el origen del actor (pies sobre el suelo de la ruta).
	sprite.offset = Vector2(0.0, texture.get_height() * 0.5 - feet_y)
	if not sprite.has_meta("batch_static_actor"):
		sprite.position.y = 0.0


func _refit_player_body(player: CharacterBody2D) -> void:
	# Hitbox de Ciruja sobre la silueta nueva (misma regla que CollisionFactory.add_shape).
	var old: CollisionShape2D = player.get_node_or_null("CollisionShape2D")
	if old == null:
		return
	var texture: Texture2D = player.visual.sprite_frames.get_frame_texture(player.character_definition.idle_animation, 0)
	player.remove_child(old)
	old.queue_free()
	var body := CollisionFactory.add_shape(player, texture, player.character_visual_scale, true, player.collision_width_ratio)
	player.hurtbox.copy_shape_from(body)


func _copy_animation(source: SpriteFrames, source_name: StringName, target: SpriteFrames, target_name: StringName) -> void:
	if not target.has_animation(target_name):
		target.add_animation(target_name)
	target.clear(target_name)
	target.set_animation_speed(target_name, source.get_animation_speed(source_name))
	target.set_animation_loop(target_name, source.get_animation_loop(source_name))
	for index in source.get_frame_count(source_name):
		target.add_frame(target_name, source.get_frame_texture(source_name, index), source.get_frame_duration(source_name, index))
