class_name DialogueSequence
extends Resource

@export var sequence_id: StringName = &""
@export var allow_skip: bool = true
@export var entries: Array[Dictionary] = []


func is_valid() -> bool:
	return get_validation_errors().is_empty()


func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if sequence_id.is_empty():
		errors.append("sequence_id must not be empty")
	if entries.is_empty():
		errors.append("entries must contain at least one dialogue line")
	for index in range(entries.size()):
		var entry: Dictionary = entries[index]
		if not entry.has("speaker") or String(entry.speaker).strip_edges().is_empty():
			errors.append("entry %d requires a speaker" % index)
		if not entry.has("text") or String(entry.text).strip_edges().is_empty():
			errors.append("entry %d requires text" % index)
		if entry.has("portrait") and entry.portrait != null and not entry.portrait is Texture2D:
			errors.append("entry %d portrait must be a Texture2D" % index)
	return errors


func get_entry(index: int) -> Dictionary:
	if index < 0 or index >= entries.size():
		return {}
	return entries[index]
