class_name EncounterDirector
extends Node
const CFG = preload("res://scripts/prototype/feel_config.gd")

signal encounter_started(encounter_id: StringName)
signal encounter_completed(encounter_id: StringName)
signal active_enemy_count_changed(encounter_id: StringName, active_count: int)

const ACTIVATION_PLAYER_X := "player_x_at_least"
const COMPLETION_ALL_DEFEATED := "all_enemies_defeated"

var spawn_bounds := Vector2(40.0,7900.0)
var _spawn_enemy: Callable
var _encounters: Dictionary = {}
var _registration_order: Array[StringName] = []
var _activated: Dictionary = {}
var _completed: Dictionary = {}
var _active_enemies: Dictionary = {}
var _resetting: bool = false
var _pending: Array[Dictionary] = []
var _rest_remaining := 0.0
var _attack_tokens: Dictionary = {}
var _grant_remaining := 0.0
var _spawn_group := ""
var _spawn_group_remaining := 0.0
var camera_center_x := NAN
var viewport_width := 800.0
const HOSTILE_PROJECTILE_CAP := 3
const DRONE_WAVE_PROJECTILE_CAP := 2
const DRONE_ATTACK_CAP := 1
const DRONE_GLOBAL_GRANT_GAP := 0.75
const OFFSCREEN_MARGIN := 40.0
const OFFSCREEN_LIMIT := 4.0
const CAMERA_CAP_OFFSCREEN_LIMIT := 1.0
const EDGE_INSET := 30.0
const VOID_Y := 900.0

func actor_visual_rect(enemy: Node2D) -> Rect2:
	var visual: AnimatedSprite2D = enemy.get_node("Visual")
	var texture := visual.sprite_frames.get_frame_texture(visual.animation,visual.frame)
	var bounds := CollisionFactory.opaque_bounds(texture)
	bounds.position -= texture.get_size()*0.5
	if visual.flip_h:
		bounds.position.x = -bounds.end.x
	return visual.global_transform*bounds

func is_attack_visible(enemy: Node2D) -> bool:
	if is_nan(camera_center_x):
		return true # Isolated fixtures without an active route camera.
	var bounds := actor_visual_rect(enemy)
	var left := camera_center_x-viewport_width*0.5
	var right := camera_center_x+viewport_width*0.5
	# Body centre plus 16px inside the viewport; a sliver at the edge is not enough.
	return bounds.get_center().x >= left+16.0 and bounds.get_center().x <= right-16.0 \
		and bounds.end.y > 0.0 and bounds.position.y < 450.0

func get_hostile_projectile_count() -> int:
	var container := get_parent().get_node_or_null("Projectiles")
	var count := 0
	if container == null:
		return count
	for projectile in container.get_children():
		if projectile.is_queued_for_deletion() or projectile.get("spent")==true:
			continue
		if projectile.get("team")==&"enemy" and projectile.get("kind") in [&"hipster_coffee",&"agent_orb",&"drone_bolt"]:
			count += 1
	return count # Count every live hostile shot; camera motion cannot bypass the budget.

func get_ground_projectile_count() -> int:
	return get_hostile_projectile_count() # Compatibility name for existing probes.

func get_projectile_cap_for(enemy: Node) -> int:
	return DRONE_WAVE_PROJECTILE_CAP if enemy.get("archetype")=="drone" \
		and enemy.get_meta("encounter_id",&"")==&"route_drone_02" else HOSTILE_PROJECTILE_CAP

func can_emit_ground_shot(enemy: Node2D) -> bool:
	return is_attack_visible(enemy) and get_hostile_projectile_count()<HOSTILE_PROJECTILE_CAP

func request_attack(enemy: Node) -> bool:
	var id := enemy.get_instance_id()
	if enemy.get("archetype") != "drone" and not is_attack_visible(enemy):
		release_attack(enemy)
		return false
	if _attack_tokens.has(id):
		return true
	if get_hostile_projectile_count()>=get_projectile_cap_for(enemy):
		return false
	if not is_nan(camera_center_x) and absf(enemy.position.x-camera_center_x)>viewport_width*0.5+40.0:
		return false
	if _grant_remaining > 0.0:
		return false
	var requesting_drone: bool = enemy.get("archetype")=="drone"
	var same_pool_count := 0
	for holder: WeakRef in _attack_tokens.values():
		var actor = holder.get_ref()
		if actor == null:
			continue
		var holder_is_drone: bool = actor.get("archetype")=="drone"
		if holder_is_drone != requesting_drone:
			return false # Preserve air/ground exclusion while allowing two aerial holders.
		if holder_is_drone==requesting_drone:
			same_pool_count += 1
	var cap := DRONE_ATTACK_CAP if requesting_drone else 1
	if same_pool_count >= cap:
		return false
	_attack_tokens[id] = weakref(enemy)
	_grant_remaining = 0.22
	return true

func release_attack(enemy: Node) -> void:
	var released: bool = _attack_tokens.erase(enemy.get_instance_id())
	if released and enemy.get("archetype")=="drone":
		_grant_remaining = maxf(_grant_remaining,DRONE_GLOBAL_GRANT_GAP)

func get_attack_token_count() -> int:
	return _attack_tokens.size()

func get_drone_attack_token_count() -> int:
	var count := 0
	for holder: WeakRef in _attack_tokens.values():
		var actor = holder.get_ref()
		if actor != null and actor.get("archetype")=="drone":
			count += 1
	return count

func is_resting() -> bool:
	return _rest_remaining > 0.0

func add_rest(seconds: float) -> void:
	_rest_remaining = maxf(_rest_remaining,seconds)

func update_safety(player_x: float,center_x: float,width: float,camera_capped: bool = false,delta: float = 1.0/60.0) -> void:
	camera_center_x = center_x
	viewport_width = width
	for encounter_id in _active_enemies.keys():
		for enemy in get_active_enemies(encounter_id):
			if _rescue_stray(encounter_id,enemy,center_x,width,camera_capped,delta):
				continue
			if enemy.has_method("cancel_offscreen_attack") and not is_attack_visible(enemy):
				enemy.cancel_offscreen_attack()
			# No dead band behind the camera: a stationary patrol there never returns
			# and used to hold the serial encounter gate forever. Never cull visible art.
			if actor_visual_rect(enemy).end.x < minf(center_x-width*0.5,player_x):
				release_attack(enemy)
				_remove_enemy_reference(encounter_id,enemy.get_instance_id())
				enemy.queue_free() # No reward; only retire well behind BOTH Player and camera.


## Ningún encuentro depende de actores inalcanzables: un enemigo que cae al vacío se descarta (sin recompensa ni cupo);
## uno que pasa más de OFFSCREEN_LIMIT s fuera de cuadro (1 s si la cámara está en su tope) vuelve al borde visible.
func _rescue_stray(encounter_id: StringName,enemy: Node2D,center_x: float,width: float,camera_capped: bool,delta: float) -> bool:
	if enemy.global_position.y > VOID_Y:
		release_attack(enemy)
		_remove_enemy_reference(encounter_id,enemy.get_instance_id())
		enemy.queue_free()
		return true
	if enemy.get("archetype") == "drone":
		return false
	var half := width*0.5
	var dx := enemy.global_position.x-center_x
	if absf(dx) <= half+OFFSCREEN_MARGIN:
		enemy.set_meta("offscreen_time",0.0)
		return false
	var elapsed: float = float(enemy.get_meta("offscreen_time",0.0))+delta
	enemy.set_meta("offscreen_time",elapsed)
	if elapsed < (CAMERA_CAP_OFFSCREEN_LIMIT if camera_capped and dx > 0.0 else OFFSCREEN_LIMIT):
		return false
	release_attack(enemy)
	if enemy.has_method("cancel_offscreen_attack"):
		enemy.cancel_offscreen_attack()
	enemy.global_position.x = center_x+signf(dx)*(half-EDGE_INSET)
	enemy.velocity = Vector2.ZERO
	enemy.set_meta("offscreen_time",0.0)
	return false


func configure(encounters: Array, spawn_enemy: Callable, bounds: Vector2 = Vector2(40.0,7900.0)) -> bool:
	_encounters.clear()
	_registration_order.clear()
	_activated.clear()
	_completed.clear()
	_active_enemies.clear()
	_spawn_enemy = spawn_enemy
	spawn_bounds = bounds
	var valid := _spawn_enemy.is_valid()
	for encounter_data in encounters:
		valid = register_encounter(encounter_data) and valid
	return valid


func register_encounter(encounter_data: Dictionary) -> bool:
	if not _is_valid_encounter(encounter_data):
		return false
	var encounter_id := StringName(encounter_data.id)
	if _encounters.has(encounter_id):
		return false
	_encounters[encounter_id] = encounter_data.duplicate(true)
	_registration_order.append(encounter_id)
	return true


func advance_spawns(delta: float,player_x: float = NAN) -> void:
	_spawn_group_remaining = maxf(0.0, _spawn_group_remaining - delta)
	_grant_remaining = maxf(0.0,_grant_remaining-delta)
	_rest_remaining = maxf(0.0,_rest_remaining-delta)
	for pending in _pending.duplicate():
		pending.remaining -= delta
		if pending.remaining <= 0.0:
			# A delayed arrival stays ahead if Player ran past its original entry.
			var entry_origin: float = pending.x if is_nan(player_x) else maxf(pending.x,player_x)
			if not _can_admit(entry_origin, pending.group):
				continue
			_pending.erase(pending)
			_spawn_entry(pending.id,pending.data,entry_origin,true)
			_record_group(pending.group)

func population_limit(x: float) -> int:
	return CFG.WAVE_MAX_ADVANCED if x >= CFG.WAVE_ADVANCED_X else CFG.WAVE_MAX_EARLY

func _population() -> int:
	var population := 0
	for id in _active_enemies:
		population += get_active_enemy_count(id)
	return population

func _can_admit(x: float, group: String) -> bool:
	return _population() < population_limit(x) and (group == _spawn_group or _spawn_group_remaining <= 0.0)

func _record_group(group: String) -> void:
	if group != _spawn_group:
		_spawn_group = group
		_spawn_group_remaining = CFG.WAVE_GROUP_DELAY

func _spawn_entry(encounter_id: StringName,spawn_data: Dictionary,activation_x: float, spaced: bool = false) -> void:
	var spawn_x := clampf(activation_x+float(spawn_data.x_offset),spawn_bounds.x,spawn_bounds.y)
	if not is_nan(camera_center_x):
		# Never clamp an advancing entry onto Player at the end of the route.
		spawn_x = maxf(spawn_x,maxf(camera_center_x+viewport_width*0.5+80.0,activation_x+viewport_width*0.6))
	if spaced:
		# Move the entry outward on its existing side, never reposition live actors.
		var side := -1.0 if float(spawn_data.x_offset) < 0 and is_nan(camera_center_x) else 1.0
		var occupied: Array[float] = []
		for id in _active_enemies:
			for actor in get_active_enemies(id):
				occupied.append(actor.global_position.x)
		while occupied.any(func(x: float): return absf(x - spawn_x) < CFG.WAVE_MIN_SPAWN_DISTANCE):
			spawn_x += side * CFG.WAVE_MIN_SPAWN_DISTANCE
	var enemy = _spawn_enemy.call(String(spawn_data.enemy_id),spawn_x,0)
	if enemy is Node:
		if spaced and enemy.get("archetype") != "drone":
			enemy.set_meta("wave_entry", true)
		_track_enemy(encounter_id,enemy)

func update_activation(player_x: float) -> void:
	if _rest_remaining>0.0 or not _pending.is_empty():
		return
	for encounter_id in _registration_order:
		if _activated.has(encounter_id) or _completed.has(encounter_id):
			continue
		var encounter: Dictionary = _encounters[encounter_id]
		var activation: Dictionary = encounter.activation
		if activation.type == ACTIVATION_PLAYER_X and player_x >= float(activation.value):
			var population := 0
			var aerial_active := false
			for active_id in _active_enemies:
				for actor in get_active_enemies(active_id):
					population += 1
					aerial_active = aerial_active or actor.get("archetype")=="drone"
			var aerial_entry: bool = encounter.enemies.any(func(entry): return String(entry.enemy_id).begins_with("drone"))
			if population>=population_limit(player_x) or (population>0 and (aerial_active or aerial_entry)):
				return
			activate_encounter(encounter_id,player_x,true)
			return


func activate_encounter(encounter_id: StringName, activation_x: float = NAN,staggered: bool = true) -> bool:
	if not _encounters.has(encounter_id) or _activated.has(encounter_id) or _completed.has(encounter_id) or not _spawn_enemy.is_valid():
		return false
	var encounter: Dictionary = _encounters[encounter_id]
	if is_nan(activation_x):
		activation_x = float(encounter.activation.value)
	_activated[encounter_id] = true
	_active_enemies[encounter_id] = {}
	encounter_started.emit(encounter_id)
	var index := 0
	for spawn_data: Dictionary in encounter.enemies:
		var delay: float = float(spawn_data.get("delay",0.0)) if staggered else 0.0
		var group := "%s:%d" % [encounter_id, index / CFG.WAVE_GROUP_SIZE]
		if staggered:
			delay = maxf(delay, floorf(float(index) / CFG.WAVE_GROUP_SIZE) * CFG.WAVE_GROUP_DELAY)
		if staggered and (delay > 0.0 or not _can_admit(activation_x, group)):
			_pending.append({"id":encounter_id,"data":spawn_data,"x":activation_x,"remaining":delay,"group":group})
		else:
			# Unstaggered activation remains an explicit fixture/debug operation.
			# update_activation (F5) always uses the paced path.
			_spawn_entry(encounter_id,spawn_data,activation_x,staggered)
			if staggered:
				_record_group(group)
		index += 1
	if get_active_enemy_count(encounter_id) == 0:
		_complete_encounter(encounter_id)
	return true


func has_encounter(encounter_id: StringName) -> bool:
	return _encounters.has(encounter_id)


func is_encounter_activated(encounter_id: StringName) -> bool:
	return _activated.has(encounter_id)


func is_encounter_completed(encounter_id: StringName) -> bool:
	return _completed.has(encounter_id)


func get_registered_encounter_ids() -> Array[StringName]:
	return _registration_order.duplicate()


func get_completed_encounter_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for encounter_id in _registration_order:
		if _completed.has(encounter_id):
			result.append(encounter_id)
	return result


func get_active_enemies(encounter_id: StringName) -> Array[Node]:
	var result: Array[Node] = []
	var tracked: Dictionary = _active_enemies.get(encounter_id,{})
	for instance_id in tracked.keys():
		var reference: WeakRef = tracked[instance_id]
		var enemy = reference.get_ref()
		if enemy == null or not is_instance_valid(enemy) or not enemy.is_inside_tree():
			tracked.erase(instance_id)
		else:
			result.append(enemy)
	return result


func get_active_enemy_count(encounter_id: StringName) -> int:
	return get_active_enemies(encounter_id).size()


func reset_runtime_state(remove_spawned_enemies: bool = true) -> void:
	_spawn_group = ""
	_spawn_group_remaining = 0.0
	_resetting = true
	_attack_tokens.clear()
	_grant_remaining = 0.0
	_pending.clear()
	_rest_remaining = 0.0
	if remove_spawned_enemies:
		for encounter_id in _active_enemies:
			for enemy in get_active_enemies(encounter_id):
				enemy.queue_free()
	_activated.clear()
	_completed.clear()
	_active_enemies.clear()
	_resetting = false


func restore_completed_encounters(completed_encounter_ids: Array[StringName]) -> void:
	reset_runtime_state(true)
	for encounter_id in completed_encounter_ids:
		if not _encounters.has(encounter_id):
			continue
		_activated[encounter_id] = true
		_completed[encounter_id] = true


func _track_enemy(encounter_id: StringName, enemy: Node) -> void:
	enemy.set_meta("attack_coordinator",self)
	enemy.set_meta("encounter_id",encounter_id)
	var instance_id := enemy.get_instance_id()
	var tracked: Dictionary = _active_enemies[encounter_id]
	tracked[instance_id] = weakref(enemy)
	if enemy.has_signal("defeated"):
		enemy.defeated.connect(_on_enemy_defeated.bind(encounter_id,instance_id),CONNECT_ONE_SHOT)
	enemy.tree_exiting.connect(_on_enemy_exiting.bind(encounter_id,instance_id),CONNECT_ONE_SHOT)
	active_enemy_count_changed.emit(encounter_id,tracked.size())


func _on_enemy_defeated(_points: int, encounter_id: StringName, instance_id: int) -> void:
	_remove_enemy_reference(encounter_id,instance_id)


func _on_enemy_exiting(encounter_id: StringName, instance_id: int) -> void:
	_remove_enemy_reference(encounter_id,instance_id)


func _remove_enemy_reference(encounter_id: StringName, instance_id: int) -> void:
	_attack_tokens.erase(instance_id)
	if _resetting or not _active_enemies.has(encounter_id):
		return
	var tracked: Dictionary = _active_enemies[encounter_id]
	if not tracked.erase(instance_id):
		return
	active_enemy_count_changed.emit(encounter_id,tracked.size())
	if tracked.is_empty():
		_complete_encounter(encounter_id)


func _complete_encounter(encounter_id: StringName) -> void:
	if _completed.has(encounter_id) or _pending.any(func(entry: Dictionary): return entry.id==encounter_id):
		return
	var encounter: Dictionary = _encounters[encounter_id]
	if encounter.completion != COMPLETION_ALL_DEFEATED or get_active_enemy_count(encounter_id) > 0:
		return
	_completed[encounter_id] = true
	_rest_remaining = float(encounter.get("rest",2.0))
	_active_enemies.erase(encounter_id)
	encounter_completed.emit(encounter_id)


func _is_valid_encounter(encounter_data: Dictionary) -> bool:
	if not encounter_data.has_all(["id","activation","completion","enemies"]):
		return false
	var encounter_id := StringName(encounter_data.id)
	if encounter_id.is_empty() or not encounter_data.activation is Dictionary:
		return false
	var activation: Dictionary = encounter_data.activation
	if not activation.has_all(["type","value"]) or activation.type != ACTIVATION_PLAYER_X:
		return false
	if encounter_data.completion != COMPLETION_ALL_DEFEATED or not encounter_data.enemies is Array or encounter_data.enemies.is_empty():
		return false
	for spawn_data in encounter_data.enemies:
		if not spawn_data is Dictionary or not spawn_data.has_all(["enemy_id","x_offset","lane"]):
			return false
		if StringName(spawn_data.enemy_id).is_empty() or int(spawn_data.lane) < 0 or int(spawn_data.lane) >= GameConfig.LANES.size():
			return false
	return true
