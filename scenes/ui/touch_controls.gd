extends CanvasLayer

## Touch Controls script providing visual buttons and touch/mouse interaction
@onready var control: Control = $Control
@onready var btn_left: Control = $Control/ButtonContainer/BtnLeft
@onready var btn_right: Control = $Control/ButtonContainer/BtnRight
@onready var btn_jump: Control = $Control/ButtonContainer/BtnJump

func _ready() -> void:
	if control:
		control.show()
	call_deferred("_find_player")

	# Connect button press and release signals to action triggers
	if btn_left:
		btn_left.button_down.connect(func(): Input.action_press("move_left"))
		btn_left.button_up.connect(func(): Input.action_release("move_left"))

	if btn_right:
		btn_right.button_down.connect(func(): Input.action_press("move_right"))
		btn_right.button_up.connect(func(): Input.action_release("move_right"))

	if btn_jump:
		btn_jump.button_down.connect(func(): Input.action_press("jump"))
		btn_jump.button_up.connect(func(): Input.action_release("jump"))

func _process(_delta: float) -> void:
	# Synchronize visual button press states with keyboard / touch input actions
	if btn_left and btn_left.has_method("set_external_pressed"):
		btn_left.set_external_pressed(Input.is_action_pressed("move_left"))
		
	if btn_right and btn_right.has_method("set_external_pressed"):
		btn_right.set_external_pressed(Input.is_action_pressed("move_right"))
		
	if btn_jump and btn_jump.has_method("set_external_pressed"):
		btn_jump.set_external_pressed(Input.is_action_pressed("jump"))

	# Handle jump charge shake animation without touching position layout
	if btn_jump:
		var ratio: float = 0.0
		if _player_ref and _player_ref.has_method("get_charge_ratio"):
			ratio = _player_ref.get_charge_ratio()
			
		if ratio > 0.0:
			var shake_mag := ratio * 4.0
			btn_jump.pivot_offset = btn_jump.size / 2.0
			btn_jump.rotation_degrees = randf_range(-shake_mag, shake_mag)
		else:
			btn_jump.rotation_degrees = 0.0

var _player_ref: Node = null

func _find_player() -> void:
	var scene = get_tree().current_scene
	if scene:
		_player_ref = scene.get_node_or_null("Player")
