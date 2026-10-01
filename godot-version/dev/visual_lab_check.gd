extends SceneTree
## Headless structural validation for the isolated Visual Lab.

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool,message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func run() -> void:
	root.size = Vector2i(800,450)
	var lab = load("res://dev/visual_lab.tscn").instantiate()
	root.add_child(lab)
	current_scene = lab
	await process_frame
	expect(lab.CATEGORY_NAMES.size()==4,"Visual Lab exposes four required categories")
	expect(is_equal_approx(lab.PLAYER_OPAQUE_HEIGHT,82.74),"Player height reference matches current Ciruja runtime")
	for category_index in range(lab.CATEGORY_NAMES.size()):
		lab.category_index = category_index
		lab.page = 0
		lab._show_page()
		await process_frame
		var category: StringName = lab.CATEGORY_NAMES[category_index]
		var category_entries: Array = lab.entries[category]
		expect(not category_entries.is_empty(),"%s category is populated" % category)
		expect(lab.display.get_child_count()==mini(lab.PAGE_SIZE,category_entries.size()),"%s first page renders expected entries" % category)
		for entry: Dictionary in category_entries:
			var resource_path: String = entry.get("frames",entry.get("texture",""))
			expect(not resource_path.is_empty() and load(resource_path)!=null,"Visual resource loads: %s" % entry.name)
			expect(float(entry.scale)>0.0,"Runtime/reference scale is positive: %s" % entry.name)
	var result := {"passed":failures.is_empty(),"checks":checks,"failures":failures}
	print(JSON.stringify(result))
	lab.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
