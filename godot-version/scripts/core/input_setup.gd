extends RefCounted
static func configure() -> void:
	if InputMap.has_action("headbutt"):
		InputMap.erase_action("headbutt")
	var bindings: Dictionary = {
		"move_left": [KEY_LEFT,KEY_A], "move_right": [KEY_RIGHT,KEY_D],
		"lane_up": [KEY_UP,KEY_W], "lane_down": [KEY_DOWN,KEY_S],
		"jump": [KEY_SPACE], "throw_orange": [KEY_Z], "throw_stone": [KEY_X],
		"tucumanazo": [KEY_V], "asset_gallery": [KEY_F1], "restart": [KEY_R], "pause": [KEY_ESCAPE],
		"select_previous": [KEY_UP,KEY_W], "select_next": [KEY_DOWN,KEY_S],
		"select_confirm": [KEY_ENTER,KEY_SPACE], "select_cancel": [KEY_ESCAPE,KEY_BACKSPACE],
		"dialogue_advance": [KEY_ENTER,KEY_SPACE], "dialogue_skip": [KEY_Q]
	}
	for action: String in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: int in bindings[action]:
			_add_key_if_missing(action,key)
	var gamepad_bindings: Dictionary = {
		"move_left": JOY_BUTTON_DPAD_LEFT,
		"move_right": JOY_BUTTON_DPAD_RIGHT,
		"lane_up": JOY_BUTTON_DPAD_UP,
		"lane_down": JOY_BUTTON_DPAD_DOWN,
		"jump": JOY_BUTTON_A,
		"throw_orange": JOY_BUTTON_RIGHT_SHOULDER,
		"throw_stone": JOY_BUTTON_LEFT_SHOULDER,
		"tucumanazo": JOY_BUTTON_Y,
		"pause": JOY_BUTTON_START,
		"restart": JOY_BUTTON_BACK,
		"select_previous": JOY_BUTTON_DPAD_UP,
		"select_next": JOY_BUTTON_DPAD_DOWN,
		"select_confirm": JOY_BUTTON_A,
		"select_cancel": JOY_BUTTON_B,
		"dialogue_advance": JOY_BUTTON_A,
		"dialogue_skip": JOY_BUTTON_B,
	}
	for action: String in gamepad_bindings:
		_add_joypad_button_if_missing(action,gamepad_bindings[action])
	var gamepad_axis_bindings: Dictionary = {
		"move_left": [JOY_AXIS_LEFT_X,-1.0],
		"move_right": [JOY_AXIS_LEFT_X,1.0],
		"lane_up": [JOY_AXIS_LEFT_Y,-1.0],
		"lane_down": [JOY_AXIS_LEFT_Y,1.0],
	}
	for action: String in gamepad_axis_bindings:
		var axis_binding: Array = gamepad_axis_bindings[action]
		_add_joypad_motion_if_missing(action,axis_binding[0],axis_binding[1])

static func _add_key_if_missing(action: String,key: int) -> void:
	for existing_event in InputMap.action_get_events(action):
		if existing_event is InputEventKey and existing_event.physical_keycode == key:
			return
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action,event)

static func _add_joypad_button_if_missing(action: String,button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for existing_event in InputMap.action_get_events(action):
		if existing_event is InputEventJoypadButton and existing_event.button_index == button:
			return
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action,event)


static func _add_joypad_motion_if_missing(action: String,axis: JoyAxis,axis_value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for existing_event in InputMap.action_get_events(action):
		if existing_event is InputEventJoypadMotion and existing_event.axis == axis and is_equal_approx(existing_event.axis_value,axis_value):
			return
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action,event)
