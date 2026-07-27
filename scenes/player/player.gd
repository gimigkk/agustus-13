extends CharacterBody2D

## Player Movement & Jump Controller implementing Jump King style charge-jumping physics.

## Maximum horizontal ground movement speed.
@export var speed: float = 320.0

## Minimum vertical jump impulse when instantly tapped.
@export var min_jump_velocity: float = -350.0

## Maximum vertical jump impulse reached at full 100% charge.
@export var max_jump_velocity: float = -800.0

## Hold time required in seconds to reach maximum jump power.
@export var max_charge_time: float = 0.55

## Ground acceleration rate.
@export var acceleration: float = 4500.0

## Ground friction deceleration rate.
@export var friction: float = 2000.0

## Air acceleration rate.
@export var air_acceleration: float = 800.0

## Base gravity multiplier.
@export var gravity_scale: float = 1.3

## Fall gravity multiplier for snappy downward physics.
@export var fall_gravity_multiplier: float = 1.4

## Max allowed grace period after walking off edges to trigger a jump.
@export var coyote_time_max: float = 0.12

## Airborne flip rotation speed in degrees per second.
@export var jump_flip_speed: float = 720.0

## Load player position from SaveManager on ready if true.
@export var load_save_position: bool = false

# Gravity settings
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

# State timers
var coyote_timer: float = 0.0

# Charging state
var is_charging_jump: bool = false
var charge_timer: float = 0.0
var charge_ratio: float = 0.0

# Juice & Animation variables
var was_on_floor: bool = true
var facing_dir: float = -1.0 # -1.0 = Facing Right, 1.0 = Facing Left
var squash_stretch_scale: Vector2 = Vector2(1.0, 1.0)
var visual_tween: Tween
var walk_anim_time: float = 0.0
var last_global_pos_x: float = 0.0

var base_visual_pos: Vector2 = Vector2(-32.5, -35.0)

@onready var visual: Control = $Visual
@onready var camera: Camera2D = $Camera2D
@onready var glow: Sprite2D = get_node_or_null("Glow")
@onready var shadow: Control = get_node_or_null("Shadow")

func _ready() -> void:
	base_visual_pos = visual.position
	camera.top_level = true
	if not Engine.is_editor_hint() and load_save_position:
		if SaveManager.current_save_data.get("has_save", false):
			var px: float = float(SaveManager.current_save_data.get("player_pos_x", global_position.x))
			var py: float = float(SaveManager.current_save_data.get("player_pos_y", global_position.y))
			global_position = Vector2(px, py)

## Returns the current jump charge percentage (0.0 to 1.0).
func get_charge_ratio() -> float:
	return charge_ratio if is_charging_jump else 0.0

func _process(delta: float) -> void:
	camera.global_position.x = 0.0
	camera.global_position.y = roundf(global_position.y)

	var well_exit_y: float = -3850.0
	var is_inside_well: bool = global_position.y > well_exit_y
	
	if glow:
		var target_glow_alpha: float = 0.035 if is_inside_well else 0.0
		glow.modulate.a = move_toward(glow.modulate.a, target_glow_alpha, delta * 2.0)
		glow.visible = glow.modulate.a > 0.001

	if shadow:
		var target_shadow_alpha: float = 1.0 if is_inside_well else 0.0
		shadow.modulate.a = move_toward(shadow.modulate.a, target_shadow_alpha, delta * 2.0)
		shadow.visible = shadow.modulate.a > 0.001

	var calc_vel_x: float = 0.0
	if delta > 0.0001:
		calc_vel_x = (global_position.x - last_global_pos_x) / delta
	last_global_pos_x = global_position.x
	
	_update_visual_animation(delta, calc_vel_x)

func _physics_process(delta: float) -> void:
	var currently_on_floor := is_on_floor()

	# Detect Landing event (was in air -> now on floor)
	if currently_on_floor and not was_on_floor:
		_on_landed()

	# Detect edge slip / fall off ledge while charging jump -> Auto-jump!
	if not currently_on_floor and was_on_floor and is_charging_jump:
		_execute_charged_jump()

	# Apply gravity when in air
	if not currently_on_floor:
		var current_gravity := gravity * gravity_scale
		if velocity.y > 0.0:
			current_gravity *= fall_gravity_multiplier
		velocity.y += current_gravity * delta
		coyote_timer -= delta
		
		# Reset ground charge state while airborne so holding jump pre-arms for landing
		is_charging_jump = false
		charge_timer = 0.0
		charge_ratio = 0.0
		
		# Rotate player sprite smoothly while airborne
		if visual:
			visual.rotation_degrees += jump_flip_speed * delta * (-facing_dir)
	else:
		coyote_timer = coyote_time_max

	# Jump King Charge Mechanic (Supports pre-holding in air: charges whenever on floor and jump is held)
	if currently_on_floor:
		if Input.is_action_pressed("jump"):
			if not is_charging_jump:
				is_charging_jump = true
				charge_timer = 0.0
			
			charge_timer = minf(charge_timer + delta, max_charge_time)
			charge_ratio = charge_timer / max_charge_time
		else:
			if is_charging_jump:
				_execute_charged_jump()

	# Horizontal movement
	var direction := Input.get_axis("move_left", "move_right")
	var current_accel := acceleration if currently_on_floor else air_acceleration
	var current_friction := friction if currently_on_floor else friction * 0.2

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, current_accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_friction * delta)

	was_on_floor = currently_on_floor
	move_and_slide()

func _update_visual_animation(delta: float, calc_vel_x: float = 0.0) -> void:
	var is_phys_proc := is_physics_processing()
	var move_speed_x := calc_vel_x if (not is_phys_proc or absf(calc_vel_x) > 15.0) else velocity.x
	var currently_on_floor := is_on_floor() if is_phys_proc else true

	if absf(move_speed_x) > 15.0:
		facing_dir = 1.0 if move_speed_x < 0 else -1.0

	# Procedural Walk Animation (Bobbing step, Waddle Tilt & Walk Squish/Stretch)
	var walk_rotation: float = 0.0
	var walk_y_offset: float = 0.0
	var target_squash := Vector2(1.0, 1.0)

	if currently_on_floor:
		if absf(move_speed_x) > 15.0:
			walk_anim_time += delta * (absf(move_speed_x) / speed) * 18.0
			var sin_val := sin(walk_anim_time)
			var cos_val := cos(walk_anim_time)
			
			var step_squish_x = 1.0 + sin_val * 0.08
			var step_squish_y = 1.0 - sin_val * 0.08
			if is_charging_jump:
				target_squash = Vector2((1.0 + charge_ratio * 0.35) * step_squish_x, (1.0 - charge_ratio * 0.45) * step_squish_y)
			else:
				target_squash = Vector2(step_squish_x, step_squish_y)
				
			walk_rotation = cos_val * 7.0 * (-facing_dir)
			walk_y_offset = -absf(sin_val) * 4.0
		else:
			walk_anim_time = 0.0
			walk_y_offset = 0.0
			if is_charging_jump:
				target_squash = Vector2(1.0 + charge_ratio * 0.35, 1.0 - charge_ratio * 0.45)
	else:
		walk_anim_time = 0.0
		walk_y_offset = 0.0

	# Smoothly lerp towards target squash scale when no tween is actively driving scale
	if visual_tween == null or not visual_tween.is_running():
		squash_stretch_scale = squash_stretch_scale.lerp(target_squash, delta * 20.0)

	# Update visual sprite scale, pivot, charge shake & walk animation
	if visual:
		if currently_on_floor and absf(visual.rotation_degrees) < 15.0:
			visual.pivot_offset = Vector2(visual.size.x / 2.0, visual.size.y)
			visual.rotation_degrees = walk_rotation
		else:
			visual.pivot_offset = visual.size / 2.0
		
		# Apply shake proportional to charge ratio plus walk step bob offset
		if is_charging_jump:
			var shake_mag := charge_ratio * 4.5
			visual.position = base_visual_pos + Vector2(randf_range(-shake_mag, shake_mag), randf_range(-shake_mag, shake_mag) + walk_y_offset)
		else:
			visual.position = base_visual_pos + Vector2(0.0, walk_y_offset)

		visual.scale = Vector2(squash_stretch_scale.x * facing_dir, squash_stretch_scale.y)

		if shadow:
			var dynamic_shadow_x: float = global_position.x * 0.08
			shadow.position = visual.position + Vector2(dynamic_shadow_x, 12.0)
			shadow.scale = visual.scale
			shadow.rotation_degrees = visual.rotation_degrees
			shadow.pivot_offset = visual.pivot_offset

func _execute_charged_jump() -> void:
	if not is_charging_jump:
		return
	var launch_vel := lerpf(min_jump_velocity, max_jump_velocity, charge_ratio)
	velocity.y = launch_vel
	is_charging_jump = false
	charge_timer = 0.0
	charge_ratio = 0.0
	coyote_timer = 0.0
	_on_jumped()

func _on_jumped() -> void:
	# Stretch vertically on jump launch (X=0.55, Y=1.45)
	_apply_squash_stretch(Vector2(0.55, 1.45), 0.38)

func _on_landed() -> void:
	SaveManager.save_current_state()

	if visual:
		var current_rot := fmod(visual.rotation_degrees, 360.0)
		if current_rot > 180.0:
			current_rot -= 360.0
		elif current_rot < -180.0:
			current_rot += 360.0
		visual.rotation_degrees = current_rot
		
		var land_tween := create_tween()
		land_tween.tween_property(visual, "rotation_degrees", 0.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	if not Input.is_action_pressed("jump"):
		_apply_squash_stretch(Vector2(1.4, 0.6), 0.32)

func _apply_squash_stretch(target_squash: Vector2, duration: float) -> void:
	if visual_tween and visual_tween.is_running():
		visual_tween.kill()
	
	squash_stretch_scale = target_squash
	visual_tween = create_tween()
	visual_tween.tween_property(self, "squash_stretch_scale", Vector2(1.0, 1.0), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

