extends CanvasLayer

const UIThemeHelper = preload("res://scenes/ui/ui_theme_helper.gd")

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

	# Style buttons with Fake 3D / AnimatedButton look
	if btn_left:
		UIThemeHelper.apply_fake_3d_style(btn_left, Color(0.1, 0.12, 0.18, 0.9), Color(0.3, 0.8, 1.0, 0.9), Color(1.0, 1.0, 1.0, 1.0), Color(0.1, 0.1, 0.1, 1.0), Color(0.68, 1.0, 0.18, 1.0), 30)
	if btn_right:
		UIThemeHelper.apply_fake_3d_style(btn_right, Color(0.1, 0.12, 0.18, 0.9), Color(0.3, 0.8, 1.0, 0.9), Color(1.0, 1.0, 1.0, 1.0), Color(0.1, 0.1, 0.1, 1.0), Color(0.68, 1.0, 0.18, 1.0), 30)
	if btn_jump:
		UIThemeHelper.apply_fake_3d_style(btn_jump, Color(0.15, 0.12, 0.22, 0.95), Color(1.0, 0.8, 0.3, 1.0), Color(1.0, 0.9, 0.4, 1.0), Color(0.1, 0.1, 0.1, 1.0), Color(0.68, 1.0, 0.18, 1.0), 30)

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
