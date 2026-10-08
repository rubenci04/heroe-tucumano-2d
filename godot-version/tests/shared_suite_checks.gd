extends SceneTree
## Run shared suites even when the legacy migration monolith aborts early.
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	run.call_deferred()

func frames(count: int) -> void:
	for index in count:
		await physics_frame
	await process_frame

func run() -> void:
	for suite in ["rebalance_checks", "arcade_pacing_checks", "expresbus_checks"]:
		var scene = load("res://scenes/main.tscn").instantiate()
		root.add_child(scene)
		current_scene = scene
		await process_frame
		scene.get_node("Interface/CharacterSelect").confirm_selected()
		scene.get_node("IntroFamailla").skip()
		await process_frame
		scene.route.set_physics_process(false)
		scene.route.encounter_director.reset_runtime_state(true)
		if suite == "expresbus_checks":
			var completed: Array[StringName] = [&"route_wave_01", &"route_wave_02"]
			scene.route.encounter_director.restore_completed_encounters(completed)
		var results: Array = await load("res://tests/" + suite + ".gd").run(self, scene)
		var failed := 0
		for result in results:
			checks += 1
			if not result.ok:
				failed += 1
				failures.append(suite + ": " + result.message)
				push_error(failures[-1])
		print("SHARED %s %d/%d PASS" % [suite, results.size()-failed, results.size()])
		root.get_node("AudioManager").stop_all()
		scene.queue_free()
		await frames(3)
	print("SHARED_SUITES %d/%d PASS %d FAIL" % [checks-failures.size(), checks, failures.size()])
	root.get_node("AudioManager").stop_all()
	# Let the audio thread release stopped playback streams before process teardown.
	OS.delay_msec(100)
	quit(0 if failures.is_empty() else 1)
