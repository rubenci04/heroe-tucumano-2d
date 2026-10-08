extends SceneTree
## Godot --headless --path godot-version --script res://tools/build_character_frames.gd
## Optional user arguments: --source=res://assets/characters --output=res://assets/animations/generated
## Writes resources only; never changes the source PNGs or metadata.

const OUTPUT := "res://assets/animations/generated"
var source := "res://assets/characters"
var output := OUTPUT
var characters: Dictionary = {}
var metadata: Dictionary = {}
var omitted: Array[String] = []
var failed := false

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--source="):
			source = argument.trim_prefix("--source=").trim_suffix("/")
		elif argument.begins_with("--output="):
			output = argument.trim_prefix("--output=").trim_suffix("/")
	if not DirAccess.dir_exists_absolute(source):
		if source == "res://assets/characters" and DirAccess.dir_exists_absolute("res://characters/lote2_cuadros"):
			source = "res://characters/lote2_cuadros"
			print("SOURCE: actual batch location ", source)
		else:
			push_error("Source directory missing: " + source)
			quit(1)
			return
	_scan(source)
	if failed or characters.is_empty():
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		push_error("Cannot create output directory: " + output)
		quit(1)
		return
	var total := 0
	var names := characters.keys()
	names.sort()
	for character: String in names:
		_write(character, characters[character])
		total += characters[character].size()
	print("GENERATED: %d characters, %d animations; %d folders pending metadata" % [characters.size(), total, omitted.size()])
	quit(1 if failed else 0)

func _read_meta(directory: String) -> Dictionary:
	if not metadata.has(directory):
		var file := directory.path_join("meta.json")
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(file)) if FileAccess.file_exists(file) else {}
		if not parsed is Dictionary:
			push_error("Invalid metadata: " + file)
			failed = true
			parsed = {}
		metadata[directory] = parsed
	return metadata[directory]

func _settings(directory: String, character: String, animation: String) -> Dictionary:
	var cursor := directory
	while cursor.begins_with(source):
		var meta := _read_meta(cursor)
		var candidates: Array = [meta.get(animation, {}), meta.get("animations", {}).get(animation, {})]
		if cursor == directory:
			candidates.push_front(meta)
		var character_meta = meta.get(character, {})
		if character_meta is Dictionary:
			candidates.append(character_meta.get(animation, {}))
			candidates.append(character_meta.get("animations", {}).get(animation, {}))
		for candidate in candidates:
			if candidate is Dictionary and candidate.has("fps") and (candidate.has("loop") or candidate.has("bucle")):
				return candidate
		if cursor == source:
			break
		cursor = cursor.get_base_dir()
	return {}

func _scan(directory: String) -> void:
	# Only character/animation folders belong to the batch. Ignore nested archive copies.
	if directory != source and directory.trim_prefix(source + "/").split("/").size() > 2:
		print("IGNORED nested package: ", directory)
		return
	var regex := RegEx.new()
	regex.compile("^f_([0-9]+)\\.png$")
	var frames: Array = []
	for filename in DirAccess.get_files_at(directory):
		var match_result := regex.search(filename)
		if match_result != null:
			frames.append({"index": int(match_result.get_string(1)), "path": directory.path_join(filename)})
	if not frames.is_empty():
		frames.sort_custom(func(a, b): return a.index < b.index)
		var animation := directory.get_file()
		var character := directory.get_base_dir().get_file()
		var settings := _settings(directory, character, animation)
		if settings.is_empty():
			omitted.append(directory)
			print("PENDING META (not invented): ", directory)
		else:
			var fps := float(settings.fps)
			var loop_value = settings.get("loop", settings.get("bucle"))
			if fps <= 0.0 or not loop_value is bool or int(settings.get("cuadros", frames.size())) != frames.size():
				push_error("Invalid fps/loop/frame count: " + directory)
				failed = true
				return
			for index in frames.size():
				if frames[index].index != index:
					push_error("Expected consecutive f_00..f_NN: " + directory)
					failed = true
					return
			if not characters.has(character):
				characters[character] = {}
			if characters[character].has(animation):
				push_error("Duplicate animation across batches: %s/%s" % [character, animation])
				failed = true
				return
			characters[character][animation] = {"frames": frames, "fps": fps, "loop": loop_value}
	for child in DirAccess.get_directories_at(directory):
		_scan(directory.path_join(child))

func _write(character: String, animations: Dictionary) -> void:
	var names := animations.keys()
	names.sort()
	var declarations: Array[String] = []
	var entries: Array[String] = []
	var id := 0
	for animation: String in names:
		var config: Dictionary = animations[animation]
		var frame_entries: Array[String] = []
		for frame in config.frames:
			id += 1
			declarations.append('[ext_resource type="Texture2D" path=%s id="%d"]' % [JSON.stringify(frame.path), id])
			frame_entries.append('{"duration": 1.0, "texture": ExtResource("%d")}' % id)
		entries.append('{"frames": [%s], "loop": %s, "name": &%s, "speed": %s}' % [", ".join(frame_entries), str(config.loop).to_lower(), JSON.stringify(animation), str(config.fps)])
	var text := '[gd_resource type="SpriteFrames" load_steps=%d format=3]\n\n%s\n\n[resource]\nanimations = [%s]\nmetadata/ground_y = 240.0\nmetadata/character = %s\n' % [id + 1, "\n".join(declarations), ",\n".join(entries), JSON.stringify(character)]
	var destination := output.path_join(character + ".tres")
	var file := FileAccess.open(destination, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write: " + destination)
		failed = true
		return
	file.store_string(text)
	print("WROTE ", destination, " (", names.size(), " animations)")
