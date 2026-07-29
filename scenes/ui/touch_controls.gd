extends CanvasLayer

## Mobile on-screen touch controller overlay supporting independent multi-touch tracking.

@onready var control: Control = $Control
@onready var btn_left: UiverseButton = $Control/ButtonContainer/BtnLeft
@onready var btn_right: UiverseButton = $Control/ButtonContainer/BtnRight
@onready var btn_jump: UiverseButton = $Control/ButtonContainer/BtnJump

var _player_ref: CharacterBody2D = null

# Active touches map: touch_index (int) -> Vector2 screen position
var _active_touches: Dictionary = {}

func _ready() -> void:
	control.show()
	call_deferred("_find_player")

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_active_touches[event.index] = event.position
		else:
			_active_touches.erase(event.index)
		_update_touch_actions()
	elif event is InputEventScreenDrag:
		_active_touches[event.index] = event.position
		_update_touch_actions()
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_active_touches[-1] = event.position
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_active_touches.erase(-1)
		_update_touch_actions()
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_active_touches[-1] = event.position
		_update_touch_actions()

func _update_touch_actions() -> void:
	var left_pressed := false
	var right_pressed := false
	var jump_pressed := false

	# Grow touch target rect slightly (by 15px padding) for comfortable touch bounds
	var padding := 15.0
	var rect_left := btn_left.get_global_rect().grow(padding) if btn_left and btn_left.is_visible_in_tree() else Rect2()
	var rect_right := btn_right.get_global_rect().grow(padding) if btn_right and btn_right.is_visible_in_tree() else Rect2()
	var rect_jump := btn_jump.get_global_rect().grow(padding) if btn_jump and btn_jump.is_visible_in_tree() else Rect2()

	for touch_id in _active_touches:
		var pos: Vector2 = _active_touches[touch_id]
		if rect_left.has_point(pos):
			left_pressed = true
		if rect_right.has_point(pos):
			right_pressed = true
		if rect_jump.has_point(pos):
			jump_pressed = true

	_set_action_state("move_left", left_pressed, btn_left)
	_set_action_state("move_right", right_pressed, btn_right)
	_set_action_state("jump", jump_pressed, btn_jump)

func _set_action_state(action: String, should_be_pressed: bool, button_node: UiverseButton) -> void:
	var currently_pressed := Input.is_action_pressed(action)
	if should_be_pressed and not currently_pressed:
		Input.action_press(action)
	elif not should_be_pressed and currently_pressed:
		Input.action_release(action)
	
	if button_node and button_node.has_method("set_external_pressed"):
		button_node.set_external_pressed(should_be_pressed)

# Syncs charge shake visuals when charging jump.
func _process(_delta: float) -> void:
	var ratio: float = _player_ref.get_charge_ratio() if is_instance_valid(_player_ref) else 0.0
	if ratio > 0.0:
		var shake_mag := ratio * 4.0
		btn_jump.pivot_offset = btn_jump.size / 2.0
		btn_jump.rotation_degrees = randf_range(-shake_mag, shake_mag)
	else:
		btn_jump.rotation_degrees = 0.0

func _find_player() -> void:
	var scene = get_tree().current_scene
	if scene:
		_player_ref = scene.get_node_or_null("Player") as CharacterBody2D
