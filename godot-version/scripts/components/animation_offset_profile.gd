class_name AnimationOffsetProfile
extends RefCounted

const MANIFEST_PATH := "res://data/animation_manifest.json"


static func load_character(character_id: StringName,runtime_to_canonical: Dictionary) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary or not parsed.has("characters"):
		return {}
	var characters: Dictionary = parsed.characters
	if not characters.has(String(character_id)):
		return {}
	var animations: Dictionary = characters[String(character_id)].animations
	var result := {}
	for runtime_name in runtime_to_canonical:
		var canonical_name: String = runtime_to_canonical[runtime_name]
		if not animations.has(canonical_name):
			continue
		var source_offsets = animations[canonical_name].get("frame_offsets",null)
		if not source_offsets is Array:
			continue
		var offsets: Array[Vector2] = []
		for source_offset in source_offsets:
			if source_offset is Array and source_offset.size() >= 2:
				offsets.append(Vector2(float(source_offset[0]),float(source_offset[1])))
		result[StringName(runtime_name)] = offsets
	return result


static func apply(sprite: AnimatedSprite2D,profiles: Dictionary) -> void:
	var offsets: Array = profiles.get(sprite.animation,[])
	sprite.offset = offsets[sprite.frame] if sprite.frame >= 0 and sprite.frame < offsets.size() else Vector2.ZERO
