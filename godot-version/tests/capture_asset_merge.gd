extends SceneTree
## Capturas de la fusión VIEJO + NUEVO en F5 (juego completo). Necesita ventana, no --headless:
##   Godot --path godot-version --fixed-fps 60 --script res://tests/capture_asset_merge.gd
## Salida: tests/screenshots/asset_merge/{tira_naranja,tira_piedra,f3_origenes}.png

const OUT := "res://tests/screenshots/asset_merge/"
const CROP := Vector2i(150, 110)
const ZOOM := 2
const THROW_FRAMES := [2, 5, 8, 11, 14, 15]

var scene: Node
var route: Node2D
var player: CharacterBody2D
var camera: Camera2D


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size = Vector2i(800, 450)
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.get_node("Interface/CharacterSelect").confirm_selected()
	scene.get_node("IntroFamailla").skip()
	await process_frame
	scene.get_node("Interface").visible = false
	camera = scene.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	route = scene.get_node("Route38")
	player = route.get_node("Player")
	player.oranges_unlocked = true
	player.stones = 20
	player.position = Vector2(1200, player.position.y)
	for i in 20:
		await process_frame
	await _strip("orange", "naranja")
	for i in 30:
		await process_frame
	await _strip("stone", "piedra")
	await _poses_shot()
	await _origins_shot()
	quit()


func _strip(kind: String, file_name: String) -> void:
	var frames: Array[Image] = []
	player.shot_cooldown = 0.0
	player.throw_projectile(kind)
	var frame := 0
	for target in THROW_FRAMES:
		while frame < target:
			await process_frame
			frame += 1
		await RenderingServer.frame_post_draw
		frames.append(_crop_player())
	var strip := Image.create(CROP.x * ZOOM * frames.size(), CROP.y * ZOOM, false, Image.FORMAT_RGBA8)
	for i in frames.size():
		strip.blit_rect(frames[i], Rect2i(Vector2i.ZERO, frames[i].get_size()), Vector2i(i * CROP.x * ZOOM, 0))
	strip.save_png(ProjectSettings.globalize_path(OUT + "tira_%s.png" % file_name))
	print("tira_%s: proyectiles en escena=%d" % [file_name, route.get_node("Projectiles").get_child_count()])


func _crop_player() -> Image:
	var screen: Vector2 = root.get_canvas_transform() * player.global_position
	var origin := Vector2i(int(screen.x) - 50, int(screen.y) - CROP.y + 12)
	origin = origin.clamp(Vector2i.ZERO, Vector2i(800, 450) - CROP)
	var image := root.get_texture().get_image().get_region(Rect2i(origin, CROP))
	image.resize(CROP.x * ZOOM, CROP.y * ZOOM, Image.INTERPOLATE_NEAREST)
	return image


## F3 con Ciruja (NUEVO y VIEJO), enemigos NUEVOS y un estado que no existe en ningún paquete (FALTA).
func _origins_shot() -> void:
	for projectile in route.get_node("Projectiles").get_children():
		projectile.queue_free()
	player.set_physics_process(false)
	player.position = Vector2(1090, player.position.y)
	player.visual.play(&"Jump")
	var agent: Node2D = route.spawn_enemy("agente", 1190, 0)
	var hipster: Node2D = route.spawn_enemy("hipster", 1285, 0)
	var grandote: Node2D = route.spawn_enemy("grandote", 1385, 0)
	for enemy in [agent, hipster, grandote]:
		enemy.set_physics_process(false)
	var aliases: Dictionary = route.BATCH_VISUALS.enemy_aliases(agent)
	aliases[&"Estado inexistente"] = &"no_existe"
	route._batch.attach(agent, "agente", aliases, false)
	agent.visual.play(&"Estado inexistente")
	hipster.visual.play(hipster.definition.attack_animation)
	grandote.visual.play(grandote.definition.run_animation)
	var key := InputEventKey.new()
	key.keycode = KEY_F3
	key.pressed = true
	Input.parse_input_event(key)
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "f3_origenes.png"))
	print("f3_origenes guardado; overlay=%s" % route._batch._debug_overlay)


## Ciruja en reposo (NUEVO) y en poses VIEJAS normalizadas: misma altura, pies sobre la misma línea y mismo eje.
func _poses_shot() -> void:
	for projectile in route.get_node("Projectiles").get_children():
		projectile.queue_free()
	await process_frame
	player.set_physics_process(false)
	var poses := [[&"Idle", 0], [&"Run", 2], [&"Jump", 2], [&"Jump", 4], [&"Hit", 0], [&"Throw Orange", 3], [&"Throw Stone", 5], [&"Headbutt", 1]]
	var frames: Array[Image] = []
	for pose in poses:
		player.visual.animation = pose[0]
		player.visual.frame = pose[1]
		player.visual.pause()
		await process_frame
		await RenderingServer.frame_post_draw
		frames.append(_crop_player())
	var strip := Image.create(CROP.x * ZOOM * frames.size(), CROP.y * ZOOM, false, Image.FORMAT_RGBA8)
	for i in frames.size():
		strip.blit_rect(frames[i], Rect2i(Vector2i.ZERO, frames[i].get_size()), Vector2i(i * CROP.x * ZOOM, 0))
	strip.save_png(ProjectSettings.globalize_path(OUT + "poses_normalizadas.png"))
