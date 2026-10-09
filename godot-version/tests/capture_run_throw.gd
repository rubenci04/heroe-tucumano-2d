extends SceneTree
## Capturas de correr y lanzar en F5 (con ventana, --fixed-fps 60): tira de 6 cuadros y F3 con el origen NUEVO.
const OUT := "res://tests/screenshots/asset_merge/"
const CROP := Vector2i(170, 110)
const ZOOM := 2
const FRAMES := [1, 3, 5, 7, 10, 14]
var player: CharacterBody2D

func _initialize() -> void:
	call_deferred("run")

func crop() -> Image:
	var screen: Vector2 = root.get_canvas_transform() * player.global_position
	var origin := Vector2i(int(screen.x) - 60, int(screen.y) - CROP.y + 12).clamp(Vector2i.ZERO, Vector2i(800, 450) - CROP)
	var image := root.get_texture().get_image().get_region(Rect2i(origin, CROP))
	image.resize(CROP.x * ZOOM, CROP.y * ZOOM, Image.INTERPOLATE_NEAREST)
	return image

func run() -> void:
	root.size = Vector2i(800, 450)
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.get_node("Interface/CharacterSelect").confirm_selected()
	scene.get_node("IntroFamailla").skip()
	await process_frame
	scene.get_node("Interface").visible = false
	var route = scene.get_node("Route38")
	player = route.player
	player.oranges_unlocked = true
	player.stones = 99
	player.health_component.set_invulnerability(100000.0)
	route.encounter_director._rest_remaining = 1000000.0
	player.position.x = 1500.0
	Input.action_press("move_right")
	for i in 40:
		await physics_frame
	var shots: Array[Image] = []
	player.shot_cooldown = 0.0
	player.throw_projectile("orange")
	var frame := 0
	for target in FRAMES:
		while frame < target:
			await process_frame
			frame += 1
		await RenderingServer.frame_post_draw
		shots.append(crop())
	var strip := Image.create(CROP.x * ZOOM * shots.size(), CROP.y * ZOOM, false, Image.FORMAT_RGBA8)
	for i in shots.size():
		strip.blit_rect(shots[i], Rect2i(Vector2i.ZERO, shots[i].get_size()), Vector2i(i * CROP.x * ZOOM, 0))
	strip.save_png(ProjectSettings.globalize_path(OUT + "tira_correr_lanzar.png"))
	for i in 30:
		await process_frame
	player.shot_cooldown = 0.0
	player.throw_projectile("stone")
	var key := InputEventKey.new()
	key.keycode = KEY_F3
	key.pressed = true
	Input.parse_input_event(key)
	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "f3_correr_lanzar.png"))
	print("CAPTURAS anim=", player.visual.animation)
	Input.action_release("move_right")
	quit()
