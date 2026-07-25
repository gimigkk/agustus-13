extends Node

## IntroCutscene Manager orchestrating the opening story animation
signal intro_completed

## Summit layout positions (read from level)
@export var walk_start_x: float = -400.0 # Off-screen left
@export var banana_x: float = -191.0 # Where the banana peel is
@export var well_x: float = -2.0 # Center of the well hole
@export var gf_start_x: float = 400.0 # Off-screen right
@export var gf_stop_x: float = 150.0 # GF stops on right platform
@export var summit_y: float = -4017.0 # Fallback summit platform surface Y
@export var arc_peak_height: float = 200.0 # How high the parabolic bounce goes
@export var bottom_ground_y: float = 1190.0

var is_playing: bool = false

func play_intro(level_node: Node2D) -> void:
	print("[IntroCutscene] play_intro() called. is_playing=", is_playing)
	if is_playing:
		return
	is_playing = true

	if not is_instance_valid(level_node) or not level_node.is_inside_tree():
		push_error("IntroCutscene: Invalid level_node!")
		is_playing = false
		return

	var player = level_node.get_node_or_null("Player") as CharacterBody2D
	print("[IntroCutscene] Player node: ", player)
	if not is_instance_valid(player):
		push_error("IntroCutscene: Player node not found!")
		is_playing = false
		return

	# 1. Dynamically pull Summit Y & Banana X from BananaPeel prop in level
	var banana_prop = level_node.get_node_or_null("BananaPeel")
	var ground_surface_y: float = summit_y
	if is_instance_valid(banana_prop):
		ground_surface_y = banana_prop.global_position.y
		banana_x = banana_prop.global_position.x
		print("[IntroCutscene] Referenced BananaPeel at position: ", banana_prop.global_position)
	else:
		print("[IntroCutscene] BananaPeel node not found, using fallback Y=", summit_y)

	# 2. Dynamically pull Landing Y & Shaft X from FallTarget prop in level
	var fall_target = level_node.get_node_or_null("FallTarget")
	if is_instance_valid(fall_target):
		bottom_ground_y = fall_target.global_position.y
		well_x = fall_target.global_position.x
		print("[IntroCutscene] Referenced FallTarget at position: ", fall_target.global_position)
	else:
		print("[IntroCutscene] FallTarget node not found, using fallback Y=", bottom_ground_y)

	# 3. Setup or instantiate LevelBlackout object under the well shaft
	var blackout = level_node.get_node_or_null("LevelBlackout") as Node2D
	if not is_instance_valid(blackout):
		var blackout_scene = load("res://scenes/objects/level_blackout.tscn")
		if blackout_scene:
			blackout = blackout_scene.instantiate() as Node2D
			blackout.position = Vector2(well_x, ground_surface_y + 80.0)
			level_node.add_child(blackout)
	
	if is_instance_valid(blackout) and blackout.has_method("blackout_instant"):
		blackout.blackout_instant()

	# Calculate player center Y so player feet (30px below center) rest on ground surface
	var player_ground_center_y: float = ground_surface_y - 30.0

	# 1. Lock player physics during cutscene & set z_index behind blackout (LevelBlackout z_index = 20)
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	player.z_index = 0
	var player_col = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if is_instance_valid(player_col):
		player_col.set_deferred("disabled", true)

	# Hide UI during intro
	var hud = level_node.get_node_or_null("HUD")
	if is_instance_valid(hud) and hud.has_node("Control"):
		hud.get_node("Control").hide()
	var touch_ui = level_node.get_node_or_null("TouchControls")
	if is_instance_valid(touch_ui):
		touch_ui.hide()

	# 2. Position player off-screen left with feet resting on ground surface
	player.global_position = Vector2(walk_start_x, player_ground_center_y)
	if "last_global_pos_x" in player:
		player.last_global_pos_x = walk_start_x
	if "facing_dir" in player:
		player.facing_dir = -1.0 # -1.0 = Facing Right

	var player_visual = player.get_node_or_null("Visual")
	if is_instance_valid(player_visual):
		player_visual.rotation_degrees = 0.0
		player_visual.scale = Vector2(-1.0, 1.0)

	# Snap camera instantly centered around summit
	var camera = player.get_node_or_null("Camera2D") as Camera2D
	if is_instance_valid(camera):
		camera.position_smoothing_enabled = false
		camera.global_position = Vector2(0.0, ground_surface_y - 50.0)
		camera.reset_smoothing()

	# 3. Create Girlfriend walking in from off-screen right with feet resting on ground surface
	var existing_gf = level_node.get_node_or_null("GirlfriendVisual")
	if is_instance_valid(existing_gf):
		existing_gf.queue_free()

	var gf := TextureRect.new()
	gf.name = "GirlfriendVisual"
	var gf_tex = load("res://scenes/player/p2_gf.png") as Texture2D
	if gf_tex:
		gf.texture = gf_tex
	gf.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gf.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gf.custom_minimum_size = Vector2(65, 65)
	gf.size = Vector2(65, 65)
	gf.pivot_offset = Vector2(32.5, 32.5)
	gf.global_position = Vector2(gf_start_x, ground_surface_y - 65.0)
	level_node.add_child(gf)

	# 4. Create letter box above player's head
	var existing_box = player.get_node_or_null("LetterBox")
	if is_instance_valid(existing_box):
		existing_box.queue_free()

	var box := ColorRect.new()
	box.name = "LetterBox"
	box.size = Vector2(28, 20)
	box.color = Color(0.85, 0.6, 0.3, 1.0)
	box.position = Vector2(-14, -50)
	player.add_child(box)

	var box_label := Label.new()
	box_label.text = "🎁"
	box_label.add_theme_font_size_override("font_size", 14)
	box_label.position = Vector2(4, 0)
	box.add_child(box_label)

	# ============================================
	# CUTSCENE TIMELINE
	# ============================================
	var tween := level_node.create_tween().set_parallel(true)
	print("[IntroCutscene] Tween created, starting new timeline...")

	var bf_stop1_x: float = -260.0
	var gf_stop1_x: float = 200.0
	var gf_final_x: float = 140.0

	# --- STAGE 1: Both walk in smoothly to initial greeting spots ---
	# GF walks in from right to gf_stop1_x (0.65s)
	if is_instance_valid(gf):
		gf.pivot_offset = Vector2(32.5, 65.0)
		var gf_base_y = ground_surface_y - 65.0
		tween.tween_property(gf, "global_position:x", gf_stop1_x, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		var gf_waddle := level_node.create_tween()
		for step in range(6):
			var phase := float(step) * 0.45
			var sin_val := sin(phase * 16.0)
			var cos_val := cos(phase * 16.0)
			var rot := cos_val * 7.0
			var y_off := -absf(sin_val) * 4.0
			gf_waddle.tween_property(gf, "rotation_degrees", rot, 0.10)
			gf_waddle.parallel().tween_property(gf, "position:y", gf_base_y + y_off, 0.10)
		gf_waddle.chain().tween_callback(func():
			if is_instance_valid(gf):
				gf.rotation_degrees = 0.0
				gf.position.y = gf_base_y
				gf.scale = Vector2(1.0, 1.0)
		)

	# Player (BF) walks in smoothly from left to bf_stop1_x (0.65s)
	tween.tween_property(player, "global_position:x", bf_stop1_x, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# --- STAGE 2: GF Minecraft crouch "squish squish" (at t=0.70s) ---
	if is_instance_valid(gf):
		var gf_crouch := level_node.create_tween()
		gf_crouch.tween_interval(0.70)
		gf_crouch.tween_property(gf, "scale", Vector2(1.25, 0.65), 0.10)
		gf_crouch.tween_property(gf, "scale", Vector2(1.0, 1.0), 0.10)
		gf_crouch.tween_property(gf, "scale", Vector2(1.25, 0.65), 0.10)
		gf_crouch.tween_property(gf, "scale", Vector2(1.0, 1.0), 0.10)

	# --- STAGE 3: Player (BF) Minecraft crouch "squish squish" back (at t=1.20s) ---
	if is_instance_valid(player_visual):
		var bf_crouch := level_node.create_tween()
		bf_crouch.tween_interval(1.20)
		bf_crouch.tween_property(player_visual, "scale", Vector2(-1.25, 0.65), 0.10)
		bf_crouch.tween_property(player_visual, "scale", Vector2(-1.0, 1.0), 0.10)
		bf_crouch.tween_property(player_visual, "scale", Vector2(-1.25, 0.65), 0.10)
		bf_crouch.tween_property(player_visual, "scale", Vector2(-1.0, 1.0), 0.10)

	# --- STAGE 4: Both walk closer (at t=1.75s) ---
	if is_instance_valid(gf):
		var gf_walk2 := level_node.create_tween()
		gf_walk2.tween_interval(1.75)
		gf_walk2.tween_property(gf, "global_position:x", gf_final_x, 0.30).set_trans(Tween.TRANS_LINEAR)

	var bf_walk2 := level_node.create_tween()
	bf_walk2.tween_interval(1.75)
	bf_walk2.tween_property(player, "global_position:x", banana_x, 0.28).set_trans(Tween.TRANS_LINEAR)

	# --- STAGE 5: SLIP on banana peel at t=2.05s ---
	var slip_time: float = 2.05

	tween.tween_callback(func():
		if is_instance_valid(player):
			player.set_physics_process(false)
			var col = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if is_instance_valid(col):
				col.set_deferred("disabled", true)
	).set_delay(slip_time)

	# Slip squash (compressed spring before launch)
	if is_instance_valid(player_visual):
		tween.tween_property(player_visual, "scale", Vector2(1.4, 0.5), 0.1).set_delay(slip_time)
		tween.tween_property(player_visual, "scale", Vector2(1.0, 1.0), 0.1).set_delay(slip_time + 0.1)

	# Banana peel spins rapidly and flies offscreen on slip!
	if is_instance_valid(banana_prop):
		tween.tween_property(banana_prop, "global_position", banana_prop.global_position + Vector2(-350.0, -450.0), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(slip_time)
		tween.tween_property(banana_prop, "rotation_degrees", -1080.0, 0.8).set_delay(slip_time)
		tween.tween_property(banana_prop, "modulate:a", 0.0, 0.3).set_delay(slip_time + 0.5)

	# Box flies up and bursts immediately on slip
	if is_instance_valid(box):
		tween.tween_property(box, "position:y", -100.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(slip_time)
		tween.tween_property(box, "modulate:a", 0.0, 0.2).set_delay(slip_time + 0.2)

	# Scatter letter particles
	tween.tween_callback(func():
		if not is_instance_valid(level_node) or not level_node.is_inside_tree():
			return
		if not is_instance_valid(player):
			return
		for i in range(12):
			var lp := Label.new()
			lp.text = "✉️"
			lp.add_theme_font_size_override("font_size", 14)
			lp.global_position = player.global_position + Vector2(randf_range(-20, 20), -50)
			level_node.add_child(lp)
			var lt := level_node.create_tween().set_parallel(true)
			var target_offset := Vector2(randf_range(-120, 120), randf_range(-180, -30))
			lt.tween_property(lp, "global_position", lp.global_position + target_offset, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			lt.tween_property(lp, "modulate:a", 0.0, 0.5).set_delay(0.4)
			lt.chain().tween_callback(func():
				if is_instance_valid(lp):
					lp.queue_free()
			)
	).set_delay(slip_time)

	# --- PHASE 3: PARABOLIC ARC — slip launches player into the well ---
	var arc_start: float = slip_time # Immediate! Slip = launch
	var arc_duration: float = 1.0
	var half_arc: float = arc_duration * 0.5
	var peak_y: float = player_ground_center_y - arc_peak_height

	# X: Linear slide from banana_x to well_x over full arc
	tween.tween_property(player, "global_position:x", well_x, arc_duration).set_trans(Tween.TRANS_LINEAR).set_delay(arc_start)

	# Y rise: Ease Out up to peak (decelerates at top)
	tween.tween_property(player, "global_position:y", peak_y, half_arc).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(arc_start)

	# Y fall: Ease In down into well (accelerates down)
	tween.tween_property(player, "global_position:y", player_ground_center_y, half_arc).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(arc_start + half_arc)

	# Spin during arc
	if is_instance_valid(player_visual):
		tween.tween_property(player_visual, "rotation_degrees", -360.0, arc_duration).set_delay(arc_start)

	# --- PHASE 4: SKYDIVE FALL from well down to bottom ---
	var fall_start: float = arc_start + arc_duration
	var fall_duration: float = 3.0
	var blackout_delay: float = 1.1
	var blackout_fade_dur: float = fall_duration - blackout_delay
	var player_bottom_landing_y: float = bottom_ground_y - 30.0

	# Delay blackout fade out slightly (0.6s) after player enters well, then fade out over remaining 2.4s
	tween.tween_callback(func():
		if is_instance_valid(blackout) and blackout.has_method("fade_out"):
			blackout.fade_out(blackout_fade_dur)
	).set_delay(fall_start + blackout_delay)

	# Plunge straight down
	tween.tween_property(player, "global_position:y", player_bottom_landing_y, fall_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(fall_start)

	# Skydiving spin (continues counter-clockwise from -360 to -1800)
	if is_instance_valid(player_visual):
		tween.tween_property(player_visual, "rotation_degrees", -1800.0, fall_duration).set_delay(fall_start)

	# Sway left-right during fall with amplitude envelope (0 → peak → 0)
	tween.tween_callback(func():
		if not is_instance_valid(level_node) or not level_node.is_inside_tree():
			return
		if not is_instance_valid(player):
			return
		var sway_tween := level_node.create_tween()
		var max_sway: float = 80.0
		var sway_speed: float = 0.25
		var num_sways: int = int(fall_duration / (sway_speed * 2))
		for i in range(num_sways):
			var progress: float = float(i) / float(num_sways)
			var envelope: float = sin(progress * PI)
			var amp: float = max_sway * envelope
			sway_tween.tween_property(player, "global_position:x", well_x + amp, sway_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			sway_tween.tween_property(player, "global_position:x", well_x - amp, sway_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# End centered
		sway_tween.tween_property(player, "global_position:x", well_x, sway_speed * 0.5).set_trans(Tween.TRANS_SINE)
	).set_delay(fall_start)

	# --- PHASE 5: IMPACT at bottom (t=5.6s) ---
	var land_time: float = fall_start + fall_duration

	tween.tween_callback(func():
		if is_instance_valid(player_visual):
			player_visual.rotation_degrees = 0.0
	).set_delay(land_time)

	if is_instance_valid(player_visual):
		tween.tween_property(player_visual, "scale", Vector2(1.6, 0.4), 0.15).set_delay(land_time)
		tween.tween_property(player_visual, "scale", Vector2(1.0, 1.0), 0.2).set_delay(land_time + 0.15)

	# Clean up box
	tween.tween_callback(func():
		if is_instance_valid(box):
			box.queue_free()
	).set_delay(land_time)

	# --- PHASE 6: Unlock controls & start game (t=6.0s) ---
	var start_game_time: float = land_time + 0.4
	tween.tween_callback(func():
		print("[IntroCutscene] Cutscene finished! Restoring controls.")
		is_playing = false
		if is_instance_valid(player):
			player.set_physics_process(true)
			var col_shape = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if is_instance_valid(col_shape):
				col_shape.set_deferred("disabled", false)

		if is_instance_valid(camera):
			camera.position_smoothing_enabled = true
			camera.reset_smoothing()

		if is_instance_valid(hud) and hud.has_node("Control"):
			hud.get_node("Control").show()
		if is_instance_valid(touch_ui):
			touch_ui.show()

		emit_signal("intro_completed")
	).set_delay(start_game_time)

	print("[IntroCutscene] Timeline ready! Duration ~", start_game_time, "s")
