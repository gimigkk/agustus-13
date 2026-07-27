extends CanvasLayer

## Mobile on-screen touch controller overlay mapping screen buttons to InputMap actions.

@onready var control: Control = $Control
@onready var btn_left: UiverseButton = $Control/ButtonContainer/BtnLeft
@onready var btn_right: UiverseButton = $Control/ButtonContainer/BtnRight
@onready var btn_jump: UiverseButton = $Control/ButtonContainer/BtnJump

var _player_ref: CharacterBody2D = null

func _ready() -> void:
	control.show()
	call_deferred("_find_player")

	btn_left.button_down.connect(func(): Input.action_press("move_left"))
	btn_left.button_up.connect(func(): Input.action_release("move_left"))

	btn_right.button_down.connect(func(): Input.action_press("move_right"))
	btn_right.button_up.connect(func(): Input.action_release("move_right"))

	btn_jump.button_down.connect(func(): Input.action_press("jump"))
	btn_jump.button_up.connect(func(): Input.action_release("jump"))

# Syncs button visual elevation states with InputMap and applies charge shake when charging jump.
func _process(_delta: float) -> void:
	if btn_left and btn_left.has_method("set_external_pressed"):
		btn_left.set_external_pressed(Input.is_action_pressed("move_left"))
	if btn_right and btn_right.has_method("set_external_pressed"):
		btn_right.set_external_pressed(Input.is_action_pressed("move_right"))
	if btn_jump and btn_jump.has_method("set_external_pressed"):
		btn_jump.set_external_pressed(Input.is_action_pressed("jump"))

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
