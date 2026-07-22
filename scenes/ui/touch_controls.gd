extends CanvasLayer

## Touch Controls script providing visual buttons and touch/mouse interaction
@onready var control: Control = $Control
@onready var btn_left: Button = $Control/BtnLeft
@onready var btn_right: Button = $Control/BtnRight
@onready var btn_jump: Button = $Control/BtnJump

var initial_jump_pos: Vector2

func _ready() -> void:
	if control:
		control.show()
	if btn_jump:
		initial_jump_pos = btn_jump.position

	# Connect button press and release signals to action triggers
	btn_left.button_down.connect(func(): Input.action_press("move_left"))
	btn_left.button_up.connect(func(): Input.action_release("move_left"))

	btn_right.button_down.connect(func(): Input.action_press("move_right"))
	btn_right.button_up.connect(func(): Input.action_release("move_right"))

	btn_jump.button_down.connect(func(): Input.action_press("jump"))
	btn_jump.button_up.connect(func(): Input.action_release("jump"))

func _process(_delta: float) -> void:
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
		btn_jump.position = initial_jump_pos
