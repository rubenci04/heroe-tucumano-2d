extends SceneTree
## Tira de agacharse → agachado → levantarse en F5 (con ventana, --fixed-fps 60).
const OUT := "res://tests/screenshots/asset_merge/"
const CROP := Vector2i(150, 110)
const ZOOM := 2
var player: CharacterBody2D

func _initialize() -> void:
	call_deferred("run")

func crop() -> Image:
	var screen: Vector2 = root.get_canvas_transform() * player.global_position
	var origin := Vector2i(int(screen.x) - 75, int(screen.y) - CROP.y + 12).clamp(Vector2i.ZERO, Vector2i(800, 450) - CROP)
	var image := root.get_texture().get_image().get_region(Rect2i(origin, CROP))
	image.resize(CROP.x * ZOOM, CROP.y * ZOOM, Image.INTERPOLATE_NEAREST)
	return image

func shot(list: Array[Image]) -> void:
	await RenderingServer.frame_post_draw
	list.append(crop())

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
	route.encounter_director._rest_remaining = 1000000.0
	player.position.x = 1500.0
	for i in 20:
		await process_frame
	var list: Array[Image] = []
	await shot(list)
	Input.action_press("aim_down")
	for count in [3, 4, 6, 20]:
		for i in count:
			await process_frame
		await shot(list)
	Input.action_release("aim_down")
	for i in 4:
		await process_frame
	await shot(list)
	var strip := Image.create(CROP.x * ZOOM * list.size(), CROP.y * ZOOM, false, Image.FORMAT_RGBA8)
	for i in list.size():
		strip.blit_rect(list[i], Rect2i(Vector2i.ZERO, list[i].get_size()), Vector2i(i * CROP.x * ZOOM, 0))
	strip.save_png(ProjectSettings.globalize_path(OUT + "tira_agacharse.png"))
	print("CAPTURA_AGACHARSE ", list.size())
	quit()
