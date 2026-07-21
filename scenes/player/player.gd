extends CharacterBody2D

## Player Movement & Jump Controller for Mobile Platforming
@export var speed: float = 320.0
@export var jump_velocity: float = -800.0
@export var acceleration: float = 4500.0
@export var friction: float = 2000.0
@export var air_acceleration: float = 800.0 # Slight air adjustment like Jump King
@export var gravity_scale: float = 1.3 # Gentle base gravity multiplier
@export var fall_gravity_multiplier: float = 1.4 # Natural snappy fall gravity
@export var coyote_time_max: float = 0.12
@export var jump_buffer_max: float = 0.12
@export var load_save_position: bool = false # Disabled for level blockout testing

# Gravity settings
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

# State timers
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

@onready var visual: Control = $Visual
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	if camera:
		camera.top_level = true
	if not Engine.is_editor_hint() and load_save_position:
		var sm = get_node_or_null("/root/SaveManager")
		if sm and sm.current_save_data.get("has_save", false):
			var px: float = float(sm.current_save_data.get("player_pos_x", global_position.x))
			var py: float = float(sm.current_save_data.get("player_pos_y", global_position.y))
			global_position = Vector2(px, py)

func _process(_delta: float) -> void:
	if camera:
		# Lock camera horizontally to world origin (x = 0.0), track player vertically only
		camera.global_position.x = 0.0
		camera.global_position.y = global_position.y

func _physics_process(delta: float) -> void:
	# Apply gravity when in air (slight extra weight when falling)
	if not is_on_floor():
		var current_gravity := gravity * gravity_scale
		if velocity.y > 0.0:
			current_gravity *= fall_gravity_multiplier
		velocity.y += current_gravity * delta
		coyote_timer -= delta
	else:
		coyote_timer = coyote_time_max

	# Update jump buffer timer
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	# Handle Jump input
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_max

	# Execute Jump
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	# Variable jump height cutoff (releasing jump early cuts upward velocity)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.45

	# Horizontal movement
	var direction := Input.get_axis("move_left", "move_right")

	var current_accel := acceleration if is_on_floor() else air_acceleration
	var current_friction := friction if is_on_floor() else friction * 0.2

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, current_accel * delta)
		if visual:
			visual.pivot_offset = visual.size / 2.0
			visual.scale.x = 1.0 if direction < 0 else -1.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_friction * delta)

	move_and_slide()
