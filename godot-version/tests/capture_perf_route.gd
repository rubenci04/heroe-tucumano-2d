extends SceneTree
## Medición de rendimiento en F5 (con ventana): recorrido de Famaillá a Río Seco, enemigos activos, auto-kill de visibles.
##   Godot --path godot-version --script res://tests/capture_perf_route.gd -- [segundos]  (por defecto 180)
## Velocidad 55 px/s (~2,5 min de Famaillá a Río Seco con combates). Escribe validation/perf_<etiqueta>.csv y imprime el resumen (PERF_SUMMARY).

const SPEED := 55.0
var samples: Array[Dictionary] = []
var _t_proc := 0
var _t_phys := 0
var _proc_sum := 0
var _proc_max := 0
var _phys_sum := 0
var _phys_max := 0
var _window_frames := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var duration := float(args[0]) if args.size() > 0 else 180.0
	var label := String(args[1]) if args.size() > 1 else "run"
	root.size = Vector2i(800,450)
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.get_node("Interface/CharacterSelect").confirm_selected()
	scene.get_node("IntroFamailla").skip()
	await process_frame
	var route = scene.get_node("Route38")
	var player = route.player
	var director = route.encounter_director
	player.health_component.set_invulnerability(1000000.0)
	player.oranges_unlocked = true
	player.stones = 99
	var seen: Dictionary = {}
	var elapsed := 0.0
	var next_sample := 0.0
	var last_t := Time.get_ticks_msec()
	var frame := 0
	var peak_nodes := 0
	# CPU de scripts por frame (la ventana está limitada a 100 fps por el sistema, así que el FPS solo no mide holgura):
	# fase de proceso = process_frame -> frame_pre_draw; fase de física = physics_frame -> process_frame.
	physics_frame.connect(func(): _t_phys = Time.get_ticks_usec())
	process_frame.connect(func():
		_t_proc = Time.get_ticks_usec()
		if _t_phys > 0:
			var phys := _t_proc-_t_phys
			_phys_sum += phys
			_phys_max = maxi(_phys_max,phys)
			_t_phys = 0)
	RenderingServer.frame_pre_draw.connect(func():
		var proc := Time.get_ticks_usec()-_t_proc
		_proc_sum += proc
		_proc_max = maxi(_proc_max,proc)
		_window_frames += 1)
	while elapsed < duration and player.position.x < 7390.0:
		await process_frame
		frame += 1
		var now := Time.get_ticks_msec()
		var dt := (now-last_t)/1000.0
		last_t = now
		elapsed += dt
		var blocked: bool = route.get_node("ExpresbusSetPiece").phase in [1,2] or route.get_node("TesaSetPiece").phase in [1,2]
		if not blocked:
			player.position.x = minf(7390.0,player.position.x+SPEED*dt)
		player.position.y = GameConfig.GROUND_Y
		player.shot_cooldown = 0.0
		if frame % 20 == 0:
			player.throw_projectile("orange" if frame % 40 == 0 else "stone")
		for id in director._active_enemies.keys():
			for actor in director.get_active_enemies(id):
				if actor.get("_waiting_respawn_read") == true:
					actor._waiting_respawn_read = false
				var iid: int = actor.get_instance_id()
				if director.is_attack_visible(actor):
					if not seen.has(iid):
						seen[iid] = elapsed
					elif elapsed-float(seen[iid]) >= 1.2:
						actor.take_damage(999,&"player")
		if elapsed >= next_sample:
			next_sample += 0.5
			var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
			peak_nodes = maxi(peak_nodes,nodes)
			samples.append({
				"t": snappedf(elapsed,0.1), "x": int(player.position.x),
				"fps": int(Performance.get_monitor(Performance.TIME_FPS)),
				"proc_avg_ms": snappedf(_proc_sum/1000.0/maxf(_window_frames,1),0.01), "proc_max_ms": snappedf(_proc_max/1000.0,0.01),
				"phys_avg_ms": snappedf(_phys_sum/1000.0/maxf(_window_frames,1),0.01), "phys_max_ms": snappedf(_phys_max/1000.0,0.01),
				"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
				"nodes": nodes,
				"orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
				"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
				"mem_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0,0.1),
				"vram_mb": snappedf(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)/1048576.0,0.1),
				"enemies": route.get_node("Enemies").get_child_count(),
				"projectiles": route.get_node("Projectiles").get_child_count(),
				"root_children": route.get_child_count()})
			_proc_sum = 0
			_proc_max = 0
			_phys_sum = 0
			_phys_max = 0
			_window_frames = 0
	var csv := FileAccess.open("res://validation/perf_%s.csv" % label,FileAccess.WRITE)
	csv.store_line(",".join(samples[0].keys()))
	for s in samples:
		csv.store_line(",".join(s.values().map(func(v): return str(v))))
	csv.close()
	var fps: Array = samples.map(func(s): return float(s.fps))
	var sorted := fps.duplicate()
	sorted.sort()
	var avg := 0.0
	for v in fps:
		avg += v
	avg /= fps.size()
	var worst_proc := 0.0
	var cpu_avg := 0.0
	var max_draw := 0
	var max_nodes := 0
	var max_objects := 0
	var max_mem := 0.0
	var max_orphans := 0
	for s in samples:
		cpu_avg += (s.proc_avg_ms+s.phys_avg_ms)/samples.size()
		worst_proc = maxf(worst_proc,s.proc_max_ms+s.phys_max_ms)
		max_draw = maxi(max_draw,s.draw_calls)
		max_nodes = maxi(max_nodes,s.nodes)
		max_objects = maxi(max_objects,s.objects)
		max_mem = maxf(max_mem,s.mem_mb)
		max_orphans = maxi(max_orphans,s.orphans)
	print("PERF_SUMMARY label=%s sim_s=%.0f end_x=%d samples=%d fps_avg=%.1f fps_min=%d fps_p5=%d cpu_ms_avg=%.2f cpu_ms_max=%.2f draw_calls_max=%d nodes_max=%d objects_max=%d orphans_max=%d mem_mb_max=%.1f" % [label,elapsed,player.position.x,samples.size(),avg,sorted[0],sorted[int(sorted.size()*0.05)],cpu_avg,worst_proc,max_draw,max_nodes,max_objects,max_orphans,max_mem])
	quit()
