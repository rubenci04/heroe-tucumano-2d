extends Node
## Visual de personajes con los cuadros nuevos (characters/lote2_cuadros -> assets/animations/generated).
## Compartido por la arena prototipo y la ruta 38: cambia solo el SpriteFrames del nodo visual, su escala
## proporcional y su anclaje a los pies. Los scripts de actor (movimiento, daño, ataques) no cambian.

const CFG = preload("res://scripts/prototype/feel_config.gd")
const CHARACTER_SCALE = preload("res://scripts/prototype/character_scale.gd")
const BATCH_FRAMES := "res://assets/animations/generated/"
const FEET_Y := 240.0  # y de los pies en el lienzo 320x256 de los cuadros nuevos

## Resolvedor de animaciones: 1) paquete NUEVO (characters/), 2) asset VIEJO (assets/) normalizado en altura,
## pies y eje horizontal, 3) marcador magenta + push_warning. Nunca cae al idle sin avisar.
enum Origin { NEW, OLD, MISSING }
const ORIGIN_NAMES := ["NUEVO", "VIEJO", "FALTA"]
const ORIGIN_COLORS := [Color(0.35, 1.0, 0.45), Color(1.0, 0.9, 0.25), Color(1.0, 0.1, 0.85)]
const NEW_ROOT := "res://characters/"

# Ciruja no tiene lanzar/saltar/golpeado en el paquete nuevo: esos estados salen del arte VIEJO (assets/).
const CIRUJA_ALIASES := {
	&"Run": &"correr", &"Punch": &"pinazo", &"Headbutt": &"embestida", &"Death": &"muerte",
}
# Estados que el código pide además de los alias (ver docs/INVENTARIO_ASSETS.md).
const EXTRA_STATES := {
	"ciruja": [&"Idle", &"Jump", &"Throw Orange", &"Throw Stone", &"Hit"],
	"palermitano": [&"boss_cofee", &"idle_v2", &"golpe_v2"],
}
const GRANDOTE_ALIASES := {
	&"grandote_run": &"correr", &"grandote_punch": &"punio", &"grandote_ground_slam": &"golpe_piso", &"Death": &"muerte",
}

var _entries: Array[Dictionary] = []


func _ready() -> void:
	# Después de la animación procedural, igual que la arena prototipo.
	process_priority = 100


## Cambia los cuadros de un actor. aliases: nombre de animación del actor -> carpeta del lote.
## El actor conserva sus colisiones; se escala con CHARACTER_SCALE (Ciruja no cambia de escala).
## scale_actor: true = prototipo (escala el actor y sus rangos de ataque). false = ruta 38: solo visual e hitbox,
## los rangos y tiempos de ataque no cambian.
func attach(actor: Node2D, character: String, aliases: Dictionary, scale_actor: bool = true) -> bool:
	var path := BATCH_FRAMES + character + ".tres"
	if not ResourceLoader.exists(path):
		push_warning("Build character frames first: " + path)
		return false
	var incoming := load(path) as SpriteFrames
	var sprite: AnimatedSprite2D = actor.visual
	release(sprite) # idempotente: se puede volver a llamar tras re-aplicar la definición del jugador
	if not sprite.has_meta("batch_legacy_ratio"):
		sprite.set_meta("batch_legacy_ratio", _legacy_ratio(sprite.sprite_frames, incoming))
	if character != "ciruja" and not actor.has_meta("original_visible_height"):
		CHARACTER_SCALE.remember(actor)
	var frames: SpriteFrames = sprite.sprite_frames.duplicate(true)
	# Cada carpeta queda disponible con su nombre; los alias puentean los estados existentes.
	for name in incoming.get_animation_names():
		_copy_animation(incoming, name, frames, name)
	for name in aliases:
		if incoming.has_animation(aliases[name]):
			_copy_animation(incoming, aliases[name], frames, name)
	# Ciruja usa todo el bucle neutro; ajustar_gorra sigue disponible como gesto eventual.
	if incoming.has_animation(&"correr"):
		var idle_name: StringName = actor.character_definition.idle_animation if character == "ciruja" else &"Idle"
		if not frames.has_animation(idle_name):
			frames.add_animation(idle_name)
		frames.clear(idle_name)
		var idle_texture := incoming.get_frame_texture(&"correr", 0)
		if character == "ciruja" and incoming.has_animation(CFG.IDLE_SOURCE_ANIMATION):
			_copy_animation(incoming, CFG.IDLE_SOURCE_ANIMATION, frames, idle_name)
		else:
			frames.add_frame(idle_name, idle_texture)
			frames.set_animation_speed(idle_name, 1.0)
			frames.set_animation_loop(idle_name, true)
	var origins := _resolve_states(frames, incoming, character, aliases, actor)
	_bake_legacy(frames, origins, float(sprite.get_meta("batch_legacy_ratio", 1.0)))
	sprite.set_meta("batch_origins", origins)
	var current := sprite.animation
	sprite.sprite_frames = frames
	sprite.play(current)
	sprite.set_meta("batch_character", character)
	sprite.set_meta("batch_ground_y", FEET_Y)
	sprite.set_meta("batch_visual_scale", sprite.scale.y)
	actor.set_meta("prototype_character", character)
	# Los offsets por cuadro del juego viejo pisarían el anclaje a los pies: se vacían.
	for legacy_property in ["_visual_frame_offsets", "_visual_offset_profiles"]:
		var legacy = actor.get(legacy_property)
		if legacy is Dictionary:
			legacy.clear()
	# Ciruja conserva escala; el resto toma la altura objetivo de feel_config.
	if scale_actor:
		CHARACTER_SCALE.apply(actor, character)
	elif character != "ciruja":
		_fit_visual(actor, character)
	if character == "ciruja":
		_refit_player_body(actor)
	var entry := {"actor": actor, "sprite": sprite, "character": character}
	_entries.append(entry)
	if not sprite.has_meta("batch_hooked"):
		sprite.set_meta("batch_hooked",true)
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
			_debug_labels.erase(entry.sprite)
			_missing_markers.erase(entry.sprite)
			_entries.remove_at(index)
			continue
		_update_pose(entry.actor, entry.sprite, entry.character)
		_anchor(entry.sprite)
		_update_debug(entry.actor, entry.sprite)


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
	var feet_x := texture.get_width() * 0.5
	var multiplier: Vector2 = sprite.get_meta("pose_multiplier", Vector2.ONE)
	if not texture.resource_path.begins_with(NEW_ROOT):
		# Cuadro VIEJO: misma altura de personaje que el nuevo, pies en la misma línea y mismo eje horizontal.
		var anchor := _legacy_anchor(texture)
		feet_x = anchor.x
		feet_y = anchor.y
	var base_scale: float = sprite.get_meta("batch_visual_scale", sprite.scale.y)
	sprite.scale = Vector2.ONE * base_scale * multiplier
	# Sprite centrado: y=240 del lienzo cae sobre el origen del actor (pies sobre el suelo de la ruta).
	# flip_h espeja el cuadro dentro de su rectángulo, no el offset: el desplazamiento horizontal se invierte.
	var shift_x := texture.get_width() * 0.5 - feet_x
	sprite.offset = Vector2(-shift_x if sprite.flip_h else shift_x, texture.get_height() * 0.5 - feet_y)
	if not sprite.has_meta("batch_static_actor"):
		sprite.position.y = 0.0


## Origen de una animación ya fusionada: NEW si su primer cuadro vive en characters/, OLD si viene de assets/, MISSING si no hay cuadros.
static func state_origin(frames: SpriteFrames, state: StringName) -> int:
	if not frames.has_animation(state) or frames.get_frame_count(state) == 0:
		return Origin.MISSING
	var texture := frames.get_frame_texture(state, 0)
	return Origin.NEW if texture != null and texture.resource_path.begins_with(NEW_ROOT) else Origin.OLD


## Clasifica cada estado pedido (alias + extras). Los que faltan reciben un cuadro de reemplazo
## (el neutro del personaje) con push_warning y marcador magenta: se ven, no se disfrazan de idle.
func _resolve_states(frames: SpriteFrames, incoming: SpriteFrames, character: String, aliases: Dictionary, actor: Node2D) -> Dictionary:
	var states: Array = aliases.keys()
	for state in EXTRA_STATES.get(character, []):
		if not states.has(state):
			states.append(state)
	var origins := {}
	var missing: Array[StringName] = []
	for state: StringName in states:
		var origin := state_origin(frames, state)
		origins[state] = origin
		if origin != Origin.MISSING:
			continue
		missing.append(state)
		push_warning("batch_visuals: FALTA el estado '%s' de %s (ni paquete nuevo ni asset viejo)" % [state, character])
		if not frames.has_animation(state):
			frames.add_animation(state)
		frames.clear(state)
		var neutral: StringName = &"idle" if incoming.has_animation(&"idle") else &"correr"
		frames.add_frame(state, incoming.get_frame_texture(neutral, 0))
		frames.set_animation_speed(state, 1.0)
		frames.set_animation_loop(state, true)
	actor.visual.set_meta("batch_missing", missing)
	return origins


# Relación de alto entre el personaje nuevo y el viejo (cuadro de reposo de cada uno).
func _legacy_ratio(legacy: SpriteFrames, incoming: SpriteFrames) -> float:
	var legacy_name := &""
	for name in legacy.get_animation_names():
		if (name == &"Idle" or String(name).ends_with("_idle")) and legacy.get_frame_count(name) > 0:
			legacy_name = name
			break
	var new_name: StringName = &"idle" if incoming.has_animation(&"idle") else &"correr"
	if legacy_name == &"" or not incoming.has_animation(new_name):
		return 1.0
	var legacy_texture := legacy.get_frame_texture(legacy_name, 0)
	if legacy_texture == null or legacy_texture.resource_path.begins_with(NEW_ROOT):
		return 1.0
	var legacy_height := CollisionFactory.opaque_bounds(legacy_texture).size.y
	var new_height := CollisionFactory.opaque_bounds(incoming.get_frame_texture(new_name, 0)).size.y
	return new_height / legacy_height if legacy_height > 0.0 else 1.0


# Los cuadros VIEJOS se reescalan una vez (misma altura que el personaje nuevo) en vez de escalar el sprite:
# la escala visual de Ciruja y de los actores se mantiene constante en saltos y lanzamientos.
var _baked := {}

func _bake_legacy(frames: SpriteFrames, origins: Dictionary, ratio: float) -> void:
	if absf(ratio - 1.0) < 0.005:
		return
	for state: StringName in origins:
		if origins[state] != Origin.OLD:
			continue
		for index in frames.get_frame_count(state):
			var texture := frames.get_frame_texture(state, index)
			if texture.has_meta("batch_scale"):
				continue # ya normalizado (attach repetido)
			frames.set_frame(state, index, _baked_texture(texture, ratio), frames.get_frame_duration(state, index))


func _baked_texture(texture: Texture2D, ratio: float) -> Texture2D:
	var key := "%s@%d" % [texture.resource_path, roundi(ratio * 1000.0)]
	if _baked.has(key):
		return _baked[key]
	var image: Image = texture.get_image().duplicate() # en headless get_image() devuelve la imagen viva de la textura
	image.resize(maxi(1, roundi(image.get_width() * ratio)), maxi(1, roundi(image.get_height() * ratio)), Image.INTERPOLATE_LANCZOS)
	var baked := ImageTexture.create_from_image(image)
	baked.take_over_path("res://assets/_batch_norm/%s@%d.png" % [texture.resource_path.get_file().get_basename(), roundi(ratio * 1000.0)])
	baked.set_meta("batch_scale", ratio)
	_baked[key] = baked
	return baked


static var _anchor_cache := {}

## Punto de apoyo de un cuadro VIEJO: centro horizontal de los pies (franja inferior) y borde inferior opaco.
static func _legacy_anchor(texture: Texture2D) -> Vector2:
	var key := texture.resource_path
	if _anchor_cache.has(key):
		return _anchor_cache[key]
	var bounds := CollisionFactory.opaque_bounds(texture)
	var image := texture.get_image()
	var band_top := maxi(int(bounds.position.y), int(bounds.end.y - maxf(4.0, bounds.size.y * 0.12)))
	var left := image.get_width()
	var right := 0
	for y in range(band_top, int(bounds.end.y)):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.1:
				left = mini(left, x)
				right = maxi(right, x + 1)
	var anchor := Vector2((left + right) * 0.5 if right > left else bounds.get_center().x, bounds.end.y)
	_anchor_cache[key] = anchor
	return anchor


## Posición local (respecto del sprite) de un punto en píxeles de un cuadro, con el mismo anclaje que _anchor.
static func _frame_point_local(sprite: AnimatedSprite2D, texture: Texture2D, point: Vector2) -> Vector2:
	var feet_x := texture.get_width() * 0.5
	var feet_y := float(sprite.get_meta("batch_ground_y"))
	if not texture.resource_path.begins_with(NEW_ROOT):
		var anchor := _legacy_anchor(texture)
		feet_x = anchor.x
		feet_y = anchor.y
	var shift_x := texture.get_width() * 0.5 - feet_x
	point *= float(texture.get_meta("batch_scale", 1.0)) # el punto viene en píxeles del cuadro original
	var local_x := point.x - texture.get_width() * 0.5
	if sprite.flip_h:
		return Vector2(-local_x - shift_x, point.y - feet_y)
	return Vector2(local_x + shift_x, point.y - feet_y)


## Segundos desde que Ciruja pide el disparo hasta el cuadro en que sale el proyectil (0 = inmediato).
## Solo cuando el lanzamiento usa cuadros VIEJOS; con cuadros nuevos el proyectil sale de inmediato.
static func throw_release_delay(player: Node2D, kind: String) -> float:
	var info = CFG.CIRUJA_THROW.get(kind)
	var state := _throw_state(player, kind)
	if info == null or state == &"" or player.visual.get_meta("batch_origins", {}).get(state, Origin.MISSING) != Origin.OLD:
		return 0.0
	var frames: SpriteFrames = player.visual.sprite_frames
	return float(info.release_frame) / maxf(frames.get_animation_speed(state), 1.0) + CFG.CIRUJA_THROW_START_LAG


## Mano de Ciruja en el cuadro de liberación, en coordenadas de mundo. Solo para tiros casi horizontales: en diagonal o
## hacia arriba se conserva el punto de salida original (fallback), medido para no nacer dentro de vehículos o plataformas.
static func throw_hand_origin(player: Node2D, kind: String, fallback: Vector2, direction: Variant = Vector2.RIGHT) -> Vector2:
	var info = CFG.CIRUJA_THROW.get(kind)
	var state := _throw_state(player, kind)
	var aim: Vector2 = direction if direction is Vector2 else Vector2(float(direction), 0.0)
	if info == null or state == &"" or absf(aim.y) > 0.3:
		return fallback
	var sprite: AnimatedSprite2D = player.visual
	var texture := sprite.sprite_frames.get_frame_texture(state, int(info.release_frame))
	if texture == null or texture.resource_path.begins_with(NEW_ROOT):
		return fallback
	return sprite.to_global(_frame_point_local(sprite, texture, info.hand))


static func _throw_state(player: Node2D, kind: String) -> StringName:
	var definition = player.get("character_definition")
	if definition == null:
		return &""
	var state: StringName = definition.throw_stone_animation if kind == "stone" else definition.throw_orange_animation
	var frames: SpriteFrames = player.visual.sprite_frames
	return state if frames != null and frames.has_animation(state) else &""


# --- Depuración: marcador de estados faltantes (siempre) y F3 con estado / animación / origen ---
var _debug_overlay := false
var _debug_labels := {}
var _missing_markers := {}


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_debug_overlay = not _debug_overlay
		for label: Label in _debug_labels.values():
			label.visible = _debug_overlay


func _update_debug(actor: Node2D, sprite: AnimatedSprite2D) -> void:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	var origin := _current_origin(sprite)
	var head := actor.global_position - Vector2(0.0, 28.0)
	if texture != null:
		head.y -= CollisionFactory.opaque_bounds(texture).size.y * absf(sprite.global_scale.y)
	var marker: Node2D = _missing_markers.get(sprite)
	if origin == Origin.MISSING and marker == null:
		marker = _make_marker(actor, sprite)
	if marker != null:
		marker.visible = origin == Origin.MISSING
		(marker.get_node("Text") as Label).text = "FALTA: " + String(sprite.animation)
		marker.global_position = head + Vector2(-75.0, -64.0)
	if not _debug_overlay and not _debug_labels.has(sprite):
		return
	var label: Label = _debug_labels.get(sprite)
	if label == null:
		label = Label.new()
		label.set_meta("row", _debug_labels.size() % 2)
		label.top_level = true
		label.z_index = 200
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_constant_override("outline_size", 4)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		actor.add_child(label)
		_debug_labels[sprite] = label
	label.visible = _debug_overlay
	label.text = "%s\n%s · %s" % [sprite.animation, _state_name(actor), ORIGIN_NAMES[origin]]
	label.modulate = ORIGIN_COLORS[origin]
	label.global_position = head + Vector2(-48.0, -26.0 - 12.0 * int(label.get_meta("row", 0)))


func _make_marker(actor: Node2D, sprite: AnimatedSprite2D) -> Node2D:
	var marker := Node2D.new()
	marker.top_level = true
	marker.z_index = 300
	var box := ColorRect.new()
	box.color = Color(1.0, 0.0, 0.8, 0.85)
	box.size = Vector2(150.0, 16.0)
	marker.add_child(box)
	var text := Label.new()
	text.name = "Text"
	text.add_theme_font_size_override("font_size", 10)
	marker.add_child(text)
	actor.add_child(marker)
	_missing_markers[sprite] = marker
	return marker


## Origen del cuadro que se muestra ahora (NEW/OLD por su ruta; MISSING si la animación es un reemplazo).
func _current_origin(sprite: AnimatedSprite2D) -> int:
	if sprite.get_meta("batch_missing", []).has(sprite.animation):
		return Origin.MISSING
	return state_origin(sprite.sprite_frames, sprite.animation)


func _state_name(actor: Node2D) -> String:
	var script: Script = actor.get_script()
	if script == null:
		return "-"
	var constants := script.get_script_constant_map()
	for pair in [["state", "State"], ["ai_state", "AIState"], ["boss_state", "BossState"]]:
		var value = actor.get(pair[0])
		if value != null and constants.get(pair[1]) is Dictionary:
			return String((constants[pair[1]] as Dictionary).find_key(value))
	return "-"


## Escala solo visual y hitbox nuevo; sin tocar el actor ni sus rangos de ataque.
func _fit_visual(actor: Node2D, character: String) -> void:
	var sprite: AnimatedSprite2D = actor.visual
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	sprite.scale = Vector2.ONE * (CFG.target_height(character) / CollisionFactory.opaque_bounds(texture).size.y)
	sprite.set_meta("batch_visual_scale", sprite.scale.y)
	var width_ratio: float = actor.definition.collision_width_ratio if actor.get("definition") != null else 0.7
	_refit_body(actor, texture, sprite.scale.y, width_ratio)


func _refit_player_body(player: CharacterBody2D) -> void:
	# Hitbox de Ciruja sobre la silueta nueva (misma regla que CollisionFactory.add_shape).
	var texture: Texture2D = player.visual.sprite_frames.get_frame_texture(player.character_definition.idle_animation, 0)
	_refit_body(player, texture, player.character_visual_scale, player.collision_width_ratio)


## Reemplaza el cuerpo y la zona de contacto/hurtbox por la silueta del cuadro actual.
func _refit_body(actor: Node2D, texture: Texture2D, image_scale: float, width_ratio: float) -> void:
	var old: CollisionShape2D = actor.get_node_or_null("CollisionShape2D")
	if old == null:
		return
	actor.remove_child(old)
	old.queue_free()
	var body := CollisionFactory.add_shape(actor, texture, image_scale, true, width_ratio)
	if actor.get("hurtbox") != null:
		actor.hurtbox.copy_shape_from(body)
	var contact: Node = actor.get_node_or_null("Contact")
	if contact != null:
		var old_contact: CollisionShape2D = contact.get_node_or_null("CollisionShape2D")
		if old_contact != null:
			contact.remove_child(old_contact)
			old_contact.queue_free()
		CollisionFactory.add_shape(contact, texture, image_scale, true, width_ratio)


func _copy_animation(source: SpriteFrames, source_name: StringName, target: SpriteFrames, target_name: StringName) -> void:
	if not target.has_animation(target_name):
		target.add_animation(target_name)
	target.clear(target_name)
	target.set_animation_speed(target_name, source.get_animation_speed(source_name))
	target.set_animation_loop(target_name, source.get_animation_loop(source_name))
	for index in source.get_frame_count(source_name):
		target.add_frame(target_name, source.get_frame_texture(source_name, index), source.get_frame_duration(source_name, index))
