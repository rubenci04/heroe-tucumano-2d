class_name TucumanazoCounterComponent
extends Node

signal uses_changed(current_uses: int,max_uses: int)

@export_range(1,100,1) var max_uses: int = 5
var current_uses: int = 5


func configure(maximum: int,initial: int = -1) -> void:
	max_uses = maxi(1,maximum)
	current_uses = max_uses if initial < 0 else clampi(initial,0,max_uses)
	uses_changed.emit(current_uses,max_uses)


func consume_one() -> bool:
	if current_uses <= 0:
		return false
	current_uses -= 1
	uses_changed.emit(current_uses,max_uses)
	return true


func set_uses(value: int) -> void:
	var next_uses := clampi(value,0,max_uses)
	if current_uses == next_uses:
		uses_changed.emit(current_uses,max_uses)
		return
	current_uses = next_uses
	uses_changed.emit(current_uses,max_uses)


func reset_full() -> void:
	set_uses(max_uses)


func has_uses() -> bool:
	return current_uses > 0
