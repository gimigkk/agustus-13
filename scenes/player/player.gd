extends CharacterBody2D

## Player Movement & Jump Controller for Mobile Platforming
@export var speed: float = 320.0
@export var jump_velocity: float = -650.0
@export var acceleration: float = 2200.0
@export var friction: float = 1800.0
@export var air_acceleration: float = 1400.0
@export var coyote_time_max: float = 0.12
@export var jump_buffer_max: float = 0.12

# Gravity settings
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

# State timers
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

@onready var visual: ColorRect = $Visual
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	if camera:
		camera.top_level = true

func _process(_delta: float) -> void:
	if camera:
		# Lock camera horizontally to world origin (x = 0.0), track player vertically only
		camera.global_position.x = 0.0
		camera.global_position.y = global_position.y

func _physics_process(delta: float) -> void:
	# Add gravity when in air
	if not is_on_floor():
		velocity.y += gravity * delta
		coyote_timer -= delta
	else:
		coyote_timer = coyote_time_max

	# Update jump buffer timer
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	# Handle Jump input trigger
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_max

	# Execute Jump if buffer and coyote time allow
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	# Variable jump height cutoff (releasing jump early slows vertical speed)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.45

	# Get horizontal direction from Input actions
	var direction := Input.get_axis("move_left", "move_right")

	if direction != 0.0:
		var accel = acceleration if is_on_floor() else air_acceleration
		velocity.x = move_toward(velocity.x, direction * speed, accel * delta)
		# Face direction visual cue
		if visual:
			visual.pivot_offset = visual.size / 2.0
			visual.scale.x = -1.0 if direction < 0 else 1.0
	else:
		var deccel = friction if is_on_floor() else friction * 0.3
		velocity.x = move_toward(velocity.x, 0.0, deccel * delta)

	move_and_slide()
