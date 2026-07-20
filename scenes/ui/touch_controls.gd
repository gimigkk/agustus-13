extends CanvasLayer

## Touch Controls script providing visual buttons and touch/mouse interaction
@onready var control: Control = $Control
@onready var btn_left: Button = $Control/BtnLeft
@onready var btn_right: Button = $Control/BtnRight
@onready var btn_jump: Button = $Control/BtnJump

func _ready() -> void:
	if control:
		control.show()
		
	# Connect button press and release signals to action triggers
	btn_left.button_down.connect(func(): Input.action_press("move_left"))
	btn_left.button_up.connect(func(): Input.action_release("move_left"))

	btn_right.button_down.connect(func(): Input.action_press("move_right"))
	btn_right.button_up.connect(func(): Input.action_release("move_right"))

	btn_jump.button_down.connect(func(): Input.action_press("jump"))
	btn_jump.button_up.connect(func(): Input.action_release("jump"))
