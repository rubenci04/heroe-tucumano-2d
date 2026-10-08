extends SceneTree
## Auditoría de solo lectura de animaciones: assets viejos (assets/animations/*.tres) y paquete nuevo
## (assets/animations/generated/*.tres). Imprime tablas markdown en la consola.
## Uso: Godot --headless --path godot-version --script res://tools/audit_assets.gd

const LEGACY := ["player", "agente", "hipster", "grandote", "boss", "drone"]
const NEW := ["ciruja", "agente", "hipster", "grandote", "palermitano", "campeona"]


func _init() -> void:
	print("## VIEJO")
	for name in LEGACY:
		_dump("res://assets/animations/%s.tres" % name, name)
	print("## NUEVO")
	for name in NEW:
		_dump("res://assets/animations/generated/%s.tres" % name, name)
	quit()


func _dump(path: String, label: String) -> void:
	var frames := load(path) as SpriteFrames
	if frames == null:
		print("| %s | (no carga) |" % label)
		return
	for anim in frames.get_animation_names():
		var count := frames.get_frame_count(anim)
		if count == 0:
			print("| %s | %s | 0 | %.0f | - | - | - |" % [label, anim, frames.get_animation_speed(anim)])
			continue
		var tex := frames.get_frame_texture(anim, 0)
		var bounds := CollisionFactory.opaque_bounds(tex)
		print("| %s | %s | %d | %.0f | %dx%d | alto visible %d | %s |" % [
			label, anim, count, frames.get_animation_speed(anim),
			tex.get_width(), tex.get_height(), int(bounds.size.y), tex.resource_path.get_base_dir().replace("res://", "")])
