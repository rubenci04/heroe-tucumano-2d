extends SceneTree
## Compara el color medio del sprite EN PANTALLA de correr vs correr_lanzar (con y sin invulnerabilidad).
## Método: captura con y sin el jugador (misma cámara) y promedia los píxeles que cambian. Con ventana, --fixed-fps 60.
const OUT := "res://tests/screenshots/asset_merge/"
var scene: Node
var player: CharacterBody2D

func _initialize() -> void:
	call_deferred("run")

func grab() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

## Color medio (rgb y luminancia) de los píxeles del jugador y su recorte ampliado para la tira.
func measure(animation: StringName, frame: int) -> Dictionary:
	player.visual.animation = animation
	player.visual.frame = frame
	player.visual.pause()
	player.visual.visible = true
	await process_frame
	var with_player := await grab()
	player.visual.visible = false
	await process_frame
	var without := await grab()
	player.visual.visible = true
	var sum := Vector3.ZERO
	var count := 0
	var min_x := 9999; var max_x := 0; var min_y := 9999; var max_y := 0
	for y in with_player.get_height():
		for x in with_player.get_width():
			var a := with_player.get_pixel(x, y)
			var b := without.get_pixel(x, y)
			if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b) > 0.12:
				sum += Vector3(a.r, a.g, a.b)
				count += 1
				min_x = mini(min_x, x); max_x = maxi(max_x, x); min_y = mini(min_y, y); max_y = maxi(max_y, y)
	var mean := sum / maxf(count, 1)
	var crop := Rect2i(min_x - 6, min_y - 6, 150, 120).intersection(Rect2i(0, 0, 800, 450))
	return {"mean": mean, "lum": 0.299*mean.x+0.587*mean.y+0.114*mean.z, "px": count, "img": with_player.get_region(crop)}

func run() -> void:
	root.size = Vector2i(800, 450)
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.get_node("Interface/CharacterSelect").confirm_selected()
	scene.get_node("IntroFamailla").skip()
	await process_frame
	scene.get_node("Interface").visible = false
	var route = scene.get_node("Route38")
	player = route.player
	route.encounter_director._rest_remaining = 1000000.0
	player.position.x = 1500.0
	for i in 10:
		await process_frame
	scene.get_node("Camera2D").position.x = 1500.0
	scene.get_node("Camera2D").reset_smoothing()
	for i in 5:
		await process_frame
	scene.process_mode = Node.PROCESS_MODE_DISABLED # fondo y cámara quietos: solo cambia el sprite
	var tiles: Array[Image] = []
	var lines: Array[String] = []
	var reference := 0.0
	for invulnerable in [false, true]:
		player.invulnerability = 0.0
		player.health_component.set_invulnerability(100000.0 if invulnerable else 0.0)
		for pair in [[&"Run", 2], [&"correr_lanzar", 2], [&"correr_lanzar", 4]]:
			var r := await measure(pair[0], pair[1])
			print("COLOR inv=%s %s f%d lum=%.3f rgb=(%.3f %.3f %.3f) px=%d" % [invulnerable, pair[0], pair[1], r.lum, r.mean.x, r.mean.y, r.mean.z, r.px])
			if not invulnerable and pair[0] == &"Run":
				reference = r.lum
			if not invulnerable:
				var ok: bool = absf(r.lum/reference-1.0) <= 0.05
				lines.append("%s f%d lum=%.3f rel=%.1f%% %s" % [pair[0], pair[1], r.lum, (r.lum/reference-1.0)*100.0, "OK" if ok else "FALLA"])
			var tile: Image = r.img
			tile.resize(300, 240, Image.INTERPOLATE_NEAREST)
			tiles.append(tile)
	var report := FileAccess.open(ProjectSettings.globalize_path(OUT + "color_report.txt"), FileAccess.WRITE)
	for line in lines:
		report.store_line(line)
	report.close()
	var strip := Image.create(300 * tiles.size(), 240, false, Image.FORMAT_RGBA8)
	for i in tiles.size():
		strip.blit_rect(tiles[i], Rect2i(0, 0, 300, 240), Vector2i(i * 300, 0))
	strip.save_png(ProjectSettings.globalize_path(OUT + "color_correr_vs_lanzar.png"))
	quit()
