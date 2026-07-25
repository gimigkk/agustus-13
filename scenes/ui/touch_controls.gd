extends CanvasLayer

## Touch Controls script providing visual buttons and touch/mouse interaction
@onready var control: Control = $Control
@onready var btn_left: Control = $Control/ButtonContainer/BtnLeft
@onready var btn_right: Control = $Control/ButtonContainer/BtnRight
@onready var btn_jump: Control = $Control/ButtonContainer/BtnJump

var initial_jump_pos: Vector2

func _ready() -> void:
	if control:
		control.show()
	
	if btn_jump:
		await get_tree().process_frame
		initial_jump_pos = btn_jump.position

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

	# Handle jump charge shake animation
	if not btn_jump:
		return
		
	var ratio: float = 0.0
	var player_node = get_tree().current_scene.get_node_or_null("Player")
	if player_node and player_node.has_method("get_charge_ratio"):
		ratio = player_node.get_charge_ratio()
		
	if ratio > 0.0:
		var shake_mag := ratio * 7.0
		btn_jump.position = initial_jump_pos + Vector2(randf_range(-shake_mag, shake_mag), randf_range(-shake_mag, shake_mag))
	else:
		if initial_jump_pos != Vector2.ZERO:
			btn_jump.position = initial_jump_pos
