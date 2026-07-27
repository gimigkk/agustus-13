extends Node

## Two-Stage Intro Cutscene Orchestrator.
## Dependencies:
## - Level Node Children: "Player" (CharacterBody2D + "Camera2D" + "Visual"), "BananaPeel", "HUD", "TouchControls".
## - Dynamically Created Nodes: "GirlfriendVisual" (TextureRect), Blackout ColorRect.
## - Autoloads: SaveManager, LetterManager.
##
## State Flow:
## Stage 1: Player & GF walk on summit -> crouch -> emits stage_1_completed -> triggers MainMenu.
## Stage 2: New Game click -> banana slip -> parabolic jump -> well skydive -> land -> emits intro_completed.

signal stage_1_completed
signal intro_completed

@export_group("Summit Motion Bounds")
@export var walk_start_x: float = -400.0
@export var banana_x: float = -191.0
@export var well_x: float = -2.0
@export var gf_start_x: float = 400.0
@export var gf_stop_x: float = 150.0
@export var summit_y: float = -4017.0
@export var arc_peak_height: float = 200.0
@export var bottom_ground_y: float = 1190.0

var is_playing: bool = false

# Persistent state variables between Stage 1 and Stage 2
var _player: CharacterBody2D
var _gf: TextureRect
var _box: ColorRect
var _camera: Camera2D
var _banana_prop: Node2D
var _level_node: Node2D
var _hud: CanvasLayer
var _touch_ui: CanvasLayer
var _player_visual: Control

var _ground_surface_y: float
var _player_ground_center_y: float
var _bf_stop1_x: float = -260.0
var _gf_stop1_x: float = 200.0
var _gf_final_x: float = 140.0

# Stage 1: Initializes player & girlfriend offscreen, waddles to summit center, disables collision/physics.
func play_intro_stage_1(level_node: Node2D) -> void:
	if is_playing:
		return
	is_playing = true

	if not is_instance_valid(level_node) or not level_node.is_inside_tree():
		push_error("IntroCutscene: Invalid level_node!")
		is_playing = false
		return
	_level_node = level_node

	_player = level_node.get_node_or_null("Player") as CharacterBody2D
	if not is_instance_valid(_player):
		push_error("IntroCutscene: Player node not found!")
		is_playing = false
		return

	_banana_prop = level_node.get_node_or_null("BananaPeel")
	_ground_surface_y = summit_y
	if is_instance_valid(_banana_prop):
		_ground_surface_y = _banana_prop.global_position.y
		banana_x = _banana_prop.global_position.x
		_banana_prop.global_position = Vector2(banana_x, _ground_surface_y)
		_banana_prop.rotation_degrees = 0.0
		_banana_prop.modulate.a = 1.0

	var fall_target = level_node.get_node_or_null("FallTarget")
	if is_instance_valid(fall_target):
		bottom_ground_y = fall_target.global_position.y
		well_x = fall_target.global_position.x

	_player_ground_center_y = _ground_surface_y - 30.0

	_hud = level_node.get_node_or_null("HUD") as CanvasLayer
	if is_instance_valid(_hud):
		_hud.visible = false
	_touch_ui = level_node.get_node_or_null("TouchControls") as CanvasLayer
	if is_instance_valid(_touch_ui):
		_touch_ui.visible = false

	_player.set_physics_process(false)
	_player.velocity = Vector2.ZERO
	_player.z_index = 0
	var player_col = _player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if is_instance_valid(player_col):
		player_col.set_deferred("disabled", true)

	_camera = _player.get_node_or_null("Camera2D") as Camera2D
	if is_instance_valid(_camera):
		_camera.position_smoothing_enabled = false
		_camera.position = Vector2.ZERO
		_camera.reset_smoothing()

	_player.global_position = Vector2(walk_start_x, _player_ground_center_y)
	if _player.get("last_global_pos_x") != null:
		_player.last_global_pos_x = walk_start_x
	_player.facing_dir = -1.0 

	_player_visual = _player.get_node_or_null("Visual") as Control
	if is_instance_valid(_player_visual):
		_player_visual.rotation_degrees = 0.0
		_player_visual.scale = Vector2(-1.0, 1.0)

	if is_instance_valid(_camera):
		_camera.global_position = Vector2(0.0, _ground_surface_y - 50.0)
		_camera.reset_smoothing()

	var existing_gf = level_node.get_node_or_null("GirlfriendVisual")
	if is_instance_valid(existing_gf):
		existing_gf.queue_free()

	_gf = TextureRect.new()
	_gf.name = "GirlfriendVisual"
	var gf_tex = load("res://scenes/player/p2_gf.png") as Texture2D
	if gf_tex:
		_gf.texture = gf_tex
	_gf.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gf.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_gf.custom_minimum_size = Vector2(65, 65)
	_gf.size = Vector2(65, 65)
	_gf.pivot_offset = Vector2(32.5, 32.5)
	_gf.global_position = Vector2(gf_start_x, _ground_surface_y - 65.0)
	level_node.add_child(_gf)

	var existing_box = _player.get_node_or_null("LetterBox")
	if is_instance_valid(existing_box):
		existing_box.queue_free()

	_box = ColorRect.new()
	_box.name = "LetterBox"
	_box.size = Vector2(28, 20)
	_box.color = Color(0.85, 0.6, 0.3, 1.0)
	_box.position = Vector2(-14, -50)
	_player.add_child(_box)
	var box_label := Label.new()
	box_label.text = "🎁"
	box_label.add_theme_font_size_override("font_size", 14)
	box_label.position = Vector2(4, 0)
	_box.add_child(box_label)

	var tween := level_node.create_tween().set_parallel(true)
	
	if is_instance_valid(_gf):
		_gf.pivot_offset = Vector2(32.5, 65.0)
		var gf_base_y = _ground_surface_y - 65.0
		tween.tween_property(_gf, "global_position:x", _gf_stop1_x, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		var gf_waddle := level_node.create_tween()
		for step in range(6):
			var phase := float(step) * 0.45
			var sin_val := sin(phase * 16.0)
			var cos_val := cos(phase * 16.0)
			var rot := cos_val * 7.0
			var y_off := -absf(sin_val) * 4.0
			gf_waddle.tween_property(_gf, "rotation_degrees", rot, 0.10)
			gf_waddle.parallel().tween_property(_gf, "position:y", gf_base_y + y_off, 0.10)
		gf_waddle.chain().tween_callback(func():
			if is_instance_valid(_gf):
				_gf.rotation_degrees = 0.0
				_gf.position.y = gf_base_y
				_gf.scale = Vector2(1.0, 1.0)
		)

	tween.tween_property(_player, "global_position:x", _bf_stop1_x, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if is_instance_valid(_gf):
		var gf_crouch := level_node.create_tween()
		gf_crouch.tween_interval(0.70)
		gf_crouch.tween_property(_gf, "scale", Vector2(1.25, 0.65), 0.10)
		gf_crouch.tween_property(_gf, "scale", Vector2(1.0, 1.0), 0.10)
		gf_crouch.tween_property(_gf, "scale", Vector2(1.25, 0.65), 0.10)
		gf_crouch.tween_property(_gf, "scale", Vector2(1.0, 1.0), 0.10)

	if is_instance_valid(_player_visual):
		var bf_crouch := level_node.create_tween()
		bf_crouch.tween_interval(1.20)
		bf_crouch.tween_property(_player_visual, "scale", Vector2(-1.25, 0.65), 0.10)
		bf_crouch.tween_property(_player_visual, "scale", Vector2(-1.0, 1.0), 0.10)
		bf_crouch.tween_property(_player_visual, "scale", Vector2(-1.25, 0.65), 0.10)
		bf_crouch.tween_property(_player_visual, "scale", Vector2(-1.0, 1.0), 0.10)

	var completion_time := 1.70
	tween.tween_callback(func():
		stage_1_completed.emit()
	).set_delay(completion_time)

## Plays Stage 2 of the intro sequence (Banana peel slip, parabolic launch, and skydive down the well).
func play_intro_stage_2() -> void:
	if not is_instance_valid(_level_node) or not is_instance_valid(_player):
		push_error("IntroCutscene: Invalid state for Stage 2!")
		return

	if is_instance_valid(_hud):
		_hud.visible = false
	if is_instance_valid(_touch_ui):
		_touch_ui.visible = false

	var tween := _level_node.create_tween().set_parallel(true)
	var crouch_delay := 1.20
	
	if is_instance_valid(_gf):
		var gf_crouch := _level_node.create_tween()
		gf_crouch.tween_interval(0.10)
		gf_crouch.tween_property(_gf, "scale", Vector2(1.25, 0.65), 0.10)
		gf_crouch.tween_property(_gf, "scale", Vector2(1.0, 1.0), 0.10)
		gf_crouch.tween_property(_gf, "scale", Vector2(1.25, 0.65), 0.10)
		gf_crouch.tween_property(_gf, "scale", Vector2(1.0, 1.0), 0.10)

	if is_instance_valid(_player_visual):
		var bf_crouch := _level_node.create_tween()
		bf_crouch.tween_interval(0.60)
		bf_crouch.tween_property(_player_visual, "scale", Vector2(-1.25, 0.65), 0.10)
		bf_crouch.tween_property(_player_visual, "scale", Vector2(-1.0, 1.0), 0.10)
		bf_crouch.tween_property(_player_visual, "scale", Vector2(-1.25, 0.65), 0.10)
		bf_crouch.tween_property(_player_visual, "scale", Vector2(-1.0, 1.0), 0.10)

	if is_instance_valid(_gf):
		var gf_walk2 := _level_node.create_tween()
		gf_walk2.tween_interval(crouch_delay)
		gf_walk2.tween_property(_gf, "global_position:x", _gf_final_x, 0.30).set_trans(Tween.TRANS_LINEAR)

	var bf_walk2 := _level_node.create_tween()
	bf_walk2.tween_interval(crouch_delay)
	bf_walk2.tween_property(_player, "global_position:x", banana_x, 0.28).set_trans(Tween.TRANS_LINEAR)

	var slip_time: float = crouch_delay + 0.30

	tween.tween_callback(func():
		if is_instance_valid(_player):
			_player.set_physics_process(false)
			var col = _player.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if is_instance_valid(col):
				col.set_deferred("disabled", true)
	).set_delay(slip_time)

	if is_instance_valid(_player_visual):
		tween.tween_property(_player_visual, "scale", Vector2(1.4, 0.5), 0.1).set_delay(slip_time)
		tween.tween_property(_player_visual, "scale", Vector2(1.0, 1.0), 0.1).set_delay(slip_time + 0.1)

	if is_instance_valid(_banana_prop):
		tween.tween_property(_banana_prop, "global_position", _banana_prop.global_position + Vector2(-350.0, -450.0), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(slip_time)
		tween.tween_property(_banana_prop, "rotation_degrees", -1080.0, 0.8).set_delay(slip_time)
		tween.tween_property(_banana_prop, "modulate:a", 0.0, 0.3).set_delay(slip_time + 0.5)

	if is_instance_valid(_box):
		tween.tween_property(_box, "position:y", -100.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(slip_time)
		tween.tween_property(_box, "modulate:a", 0.0, 0.2).set_delay(slip_time + 0.2)

	tween.tween_callback(func():
		if not is_instance_valid(_level_node) or not is_instance_valid(_player):
			return
		for i in range(12):
			var lp := Label.new()
			lp.text = "✉️"
			lp.add_theme_font_size_override("font_size", 14)
			lp.global_position = _player.global_position + Vector2(randf_range(-20, 20), -50)
			_level_node.add_child(lp)
			var lt := _level_node.create_tween().set_parallel(true)
			var target_offset := Vector2(randf_range(-120, 120), randf_range(-180, -30))
			lt.tween_property(lp, "global_position", lp.global_position + target_offset, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			lt.tween_property(lp, "modulate:a", 0.0, 0.5).set_delay(0.4)
			lt.chain().tween_callback(func():
				if is_instance_valid(lp):
					lp.queue_free()
			)
	).set_delay(slip_time)

	var arc_start: float = slip_time
	var arc_duration: float = 1.0
	var half_arc: float = arc_duration * 0.5
	var peak_y: float = _player_ground_center_y - arc_peak_height

	tween.tween_property(_player, "global_position:x", well_x, arc_duration).set_trans(Tween.TRANS_LINEAR).set_delay(arc_start)
	tween.tween_property(_player, "global_position:y", peak_y, half_arc).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(arc_start)
	tween.tween_property(_player, "global_position:y", _player_ground_center_y, half_arc).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(arc_start + half_arc)

	if is_instance_valid(_player_visual):
		tween.tween_property(_player_visual, "rotation_degrees", -360.0, arc_duration).set_delay(arc_start)

	var fall_start: float = arc_start + arc_duration
	var fall_duration: float = 3.0
	var player_bottom_landing_y: float = bottom_ground_y - 30.0

	tween.tween_property(_player, "global_position:y", player_bottom_landing_y, fall_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(fall_start)

	if is_instance_valid(_player_visual):
		tween.tween_property(_player_visual, "rotation_degrees", -1800.0, fall_duration).set_delay(fall_start)

	tween.tween_callback(func():
		if not is_instance_valid(_level_node) or not is_instance_valid(_player):
			return
		var sway_tween := _level_node.create_tween()
		var max_sway: float = 80.0
		var sway_speed: float = 0.25
		var num_sways: int = int(fall_duration / (sway_speed * 2))
		for i in range(num_sways):
			var progress: float = float(i) / float(num_sways)
			var envelope: float = sin(progress * PI)
			var amp: float = max_sway * envelope
			sway_tween.tween_property(_player, "global_position:x", well_x + amp, sway_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			sway_tween.tween_property(_player, "global_position:x", well_x - amp, sway_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		sway_tween.tween_property(_player, "global_position:x", well_x, sway_speed * 0.5).set_trans(Tween.TRANS_SINE)
	).set_delay(fall_start)

	var land_time: float = fall_start + fall_duration

	tween.tween_callback(func():
		if is_instance_valid(_player_visual):
			_player_visual.rotation_degrees = 0.0
	).set_delay(land_time)

	if is_instance_valid(_player_visual):
		tween.tween_property(_player_visual, "scale", Vector2(1.6, 0.4), 0.15).set_delay(land_time)
		tween.tween_property(_player_visual, "scale", Vector2(1.0, 1.0), 0.2).set_delay(land_time + 0.15)

	tween.tween_callback(func():
		if is_instance_valid(_box):
			_box.queue_free()
	).set_delay(land_time)

	var start_game_time: float = land_time + 0.4
	tween.tween_callback(func():
		_restore_gameplay_state()
		intro_completed.emit()
	).set_delay(start_game_time)

## Aborts an active intro cutscene and cleans up spawned story nodes.
func abort_intro() -> void:
	if is_instance_valid(_gf):
		_gf.queue_free()
	if is_instance_valid(_box):
		_box.queue_free()
		
	_restore_gameplay_state()

## Restores player collision, physics processing, and UI overlays after cutscenes.
func _restore_gameplay_state() -> void:
	is_playing = false
	if is_instance_valid(_player):
		_player.set_physics_process(true)
		var col_shape = _player.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if is_instance_valid(col_shape):
			col_shape.set_deferred("disabled", false)

	if is_instance_valid(_camera):
		_camera.position_smoothing_enabled = true
		_camera.reset_smoothing()

	if is_instance_valid(_hud):
		_hud.visible = true
	if is_instance_valid(_touch_ui):
		_touch_ui.visible = true
