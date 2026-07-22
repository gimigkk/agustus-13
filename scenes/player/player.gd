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
@export var jump_flip_speed: float = 720.0 # Airborne spin speed (720 deg/sec = 2 full flips/sec)
@export var load_save_position: bool = false # Disabled for level blockout testing

# Gravity settings
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

# State timers
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

# Juice & Animation variables
var was_on_floor: bool = true
var facing_dir: float = -1.0 # -1.0 = Facing Right, 1.0 = Facing Left
var squash_stretch_scale: Vector2 = Vector2(1.0, 1.0)
var visual_tween: Tween

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
	var currently_on_floor := is_on_floor()

	# Detect Landing event (was in air -> now on floor)
	if currently_on_floor and not was_on_floor:
		_on_landed()

	# Apply gravity when in air
	if not currently_on_floor:
		var current_gravity := gravity * gravity_scale
		if velocity.y > 0.0:
			current_gravity *= fall_gravity_multiplier
		velocity.y += current_gravity * delta
		coyote_timer -= delta
		
		# Rotate player sprite smoothly while airborne
		if visual:
			visual.rotation_degrees += jump_flip_speed * delta * (-facing_dir)
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
		_on_jumped()

	# Variable jump height cutoff (releasing jump early cuts upward velocity)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.45

	# Horizontal movement
	var direction := Input.get_axis("move_left", "move_right")
	var current_accel := acceleration if currently_on_floor else air_acceleration
	var current_friction := friction if currently_on_floor else friction * 0.2

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, current_accel * delta)
		facing_dir = 1.0 if direction < 0 else -1.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_friction * delta)

	# Update visual sprite scale & pivot (feet-anchored when upright on floor, center-anchored when flipping/recovering)
	if visual:
		if currently_on_floor and absf(visual.rotation_degrees) < 5.0:
			visual.pivot_offset = Vector2(visual.size.x / 2.0, visual.size.y)
		else:
			visual.pivot_offset = visual.size / 2.0
		visual.scale = Vector2(squash_stretch_scale.x * facing_dir, squash_stretch_scale.y)

	was_on_floor = currently_on_floor
	move_and_slide()

func _on_jumped() -> void:
	# Stretch vertically on jump launch (X=0.55, Y=1.45)
	_apply_squash_stretch(Vector2(0.55, 1.45), 0.38)

func _on_landed() -> void:
	# Normalize rotation angle to shortest path (-180 to 180) to prevent freak-out spins
	if visual:
		var current_rot := fmod(visual.rotation_degrees, 360.0)
		if current_rot > 180.0:
			current_rot -= 360.0
		elif current_rot < -180.0:
			current_rot += 360.0
		visual.rotation_degrees = current_rot
		
		# Smoothly recover to upright 0 degrees around center pivot first
		var land_tween := create_tween()
		land_tween.tween_property(visual, "rotation_degrees", 0.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	# Squash horizontally on impact landing (X=1.4, Y=0.6)
	_apply_squash_stretch(Vector2(1.4, 0.6), 0.32)

func _apply_squash_stretch(target_squash: Vector2, duration: float) -> void:
	if visual_tween and visual_tween.is_running():
		visual_tween.kill()
	
	squash_stretch_scale = target_squash
	visual_tween = create_tween()
	visual_tween.tween_property(self, "squash_stretch_scale", Vector2(1.0, 1.0), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	# Debug rendering for player collision shape
	var col = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col and col.shape is CapsuleShape2D:
		var shape = col.shape as CapsuleShape2D
		var radius = shape.radius
		var height = shape.height
		var rect = Rect2(-radius, -height * 0.5, radius * 2.0, height)
		draw_rect(rect, Color(0.2, 0.9, 0.3, 0.35), true)
		draw_rect(rect, Color(0.0, 1.0, 0.4, 0.9), false, 2.0)
