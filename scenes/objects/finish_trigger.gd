extends Area2D

## Summit Victory Goal Trigger.
## Dependencies:
## - Required Autoload: LetterManager (checks get_collected_count() >= required_letters).
## - Root Level Nodes: "WalkTarget" (defines end walking destination X/Y), "HUD", "TouchControls", "Player".

@export var required_letters: int = 21

@export_group("Cutscene Timing & Motion")
@export var pop_up_height: float = 180.0
@export var pause_before_run: float = 0.4

@onready var visual: Sprite2D = $Visual
@onready var well_barrier: StaticBody2D = get_node_or_null("WellBarrier")

var is_triggered: bool = false
var player_ref: CharacterBody2D = null
var crate_ref: Sprite2D = null
var _prompt_cooldown_timer: float = 0.0

func _ready() -> void:
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		if LetterManager:
			LetterManager.letter_collected.connect(func(_id, _msg, _total, _pos): _update_barrier_state())
		_update_barrier_state()

func _physics_process(delta: float) -> void:
	if _prompt_cooldown_timer > 0.0:
		_prompt_cooldown_timer -= delta

func _update_barrier_state() -> void:
	if not LetterManager:
		return
	var collected: int = LetterManager.get_collected_count()
	if is_instance_valid(well_barrier):
		var shape = well_barrier.get_node_or_null("BarrierCollision") as CollisionShape2D
		if is_instance_valid(shape):
			shape.set_deferred("disabled", collected >= required_letters)

# Checks letter collection threshold:
# - If count < 21: displays incomplete prompt via HUD & blocks/bounces player.
# - If count >= 21: freezes player & initiates summit cutscene sequence.
func _on_body_entered(body: Node2D) -> void:
	if is_triggered or not (body is CharacterBody2D):
		return
		
	var collected: int = LetterManager.get_collected_count()
	
	if collected >= required_letters:
		is_triggered = true
		_update_barrier_state()
		_play_finish_sequence(body as CharacterBody2D)
	else:
		var player = body as CharacterBody2D
		if is_instance_valid(player):
			var bounce_dir: float = -1.0 if player.global_position.x < global_position.x else 1.0
			player.velocity = Vector2(bounce_dir * 240.0, -280.0)
		if _prompt_cooldown_timer <= 0.0:
			_prompt_cooldown_timer = 1.2
			var hud = get_tree().current_scene.get_node_or_null("HUD")
			if hud and hud.has_method("shake_counter"):
				hud.shake_counter()

func _play_finish_sequence(player: CharacterBody2D) -> void:
	var level_node = get_tree().current_scene

	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	var player_col = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if is_instance_valid(player_col):
		player_col.set_deferred("disabled", true)
	
	var hud = level_node.get_node_or_null("HUD")
	if is_instance_valid(hud) and hud.has_node("Control"):
		hud.get_node("Control").hide()
	var touch_ui = level_node.get_node_or_null("TouchControls")
	if is_instance_valid(touch_ui):
		touch_ui.hide()

	var walk_target_node = level_node.get_node_or_null("WalkTarget")

	var ground_surface_y: float = global_position.y + 35.0
	if is_instance_valid(walk_target_node):
		ground_surface_y = walk_target_node.global_position.y

	var player_ground_y: float = ground_surface_y - 30.0
	var start_pos := player.global_position
	var left_land_x: float = global_position.x - 88.0

	var right_target_x: float = left_land_x + 270.0
	if is_instance_valid(walk_target_node):
		right_target_x = walk_target_node.global_position.x

	var peak_y: float = minf(start_pos.y, player_ground_y) - pop_up_height

	var gf = level_node.get_node_or_null("GirlfriendVisual")
	if not is_instance_valid(gf):
		var gf_node := TextureRect.new()
		gf_node.name = "GirlfriendVisual"
		var gf_tex = load("res://scenes/player/p2_gf.png") as Texture2D
		if gf_tex:
			gf_node.texture = gf_tex
		gf_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		gf_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		gf_node.custom_minimum_size = Vector2(65, 65)
		gf_node.size = Vector2(65, 65)
		gf_node.pivot_offset = Vector2(32.5, 65.0)
		gf_node.global_position = Vector2(right_target_x, ground_surface_y - 65.0)
		gf_node.scale = Vector2(1.0, 1.0)
		level_node.add_child(gf_node)
		gf = gf_node

	var arc_duration: float = 0.9
	var half_arc: float = arc_duration * 0.5

	var x_tween := level_node.create_tween()
	x_tween.tween_property(player, "global_position:x", left_land_x, arc_duration).set_trans(Tween.TRANS_LINEAR)

	var y_tween := level_node.create_tween()
	y_tween.tween_property(player, "global_position:y", peak_y, half_arc).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	y_tween.tween_property(player, "global_position:y", player_ground_y, half_arc).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var player_visual = player.get_node_or_null("Visual")
	if is_instance_valid(player_visual):
		var spin_tween := level_node.create_tween()
		spin_tween.tween_property(player_visual, "rotation_degrees", 360.0, arc_duration)

	var landing_delay := level_node.create_tween()
	landing_delay.tween_interval(arc_duration)
	landing_delay.tween_callback(func():
		if is_instance_valid(player):
			player.global_position.y = player_ground_y
			# Attach crate to player during walk after bounce & landing
			var existing_crate = player.get_node_or_null("OutroLetterCrate")
			if is_instance_valid(existing_crate):
				existing_crate.queue_free()

			var crate_delivered := Sprite2D.new()
			crate_delivered.name = "OutroLetterCrate"
			var crate_tex = load("res://assets/objects/crate_with_letters.png") as Texture2D
			if crate_tex:
				crate_delivered.texture = crate_tex
			crate_delivered.scale = Vector2(0.11, 0.11)
			crate_delivered.position = Vector2(0, -32)
			player.add_child(crate_delivered)
			player_ref = player
			crate_ref = crate_delivered

		if is_instance_valid(player_visual):
			player_visual.rotation_degrees = 0.0
			player_visual.scale = Vector2(-1.35, 0.65)
	)
	landing_delay.tween_property(player_visual, "scale", Vector2(-1.0, 1.0), 0.12)

	if is_instance_valid(gf):
		var gf_bounce := level_node.create_tween()
		gf_bounce.tween_interval(arc_duration + 0.1)
		gf_bounce.tween_property(gf, "scale", Vector2(1.25, 0.65), 0.10)
		gf_bounce.tween_property(gf, "scale", Vector2(1.0, 1.0), 0.10)

	var walk_start_time: float = arc_duration + 0.3 + pause_before_run
	var walk_target_x: float = right_target_x - 35.0
	var walk_dist: float = absf(walk_target_x - left_land_x)
	var walk_dur: float = clampf(walk_dist / 220.0, 0.6, 2.0)

	var walk_x_tween := level_node.create_tween()
	walk_x_tween.tween_interval(walk_start_time)
	walk_x_tween.tween_property(player, "global_position:x", walk_target_x, walk_dur).set_trans(Tween.TRANS_LINEAR)

	var waddle_timer := level_node.create_tween()
	waddle_timer.tween_interval(walk_start_time)
	waddle_timer.tween_callback(func():
		if not is_instance_valid(player) or not is_instance_valid(player_visual):
			return
		var waddle_tween := level_node.create_tween()
		var num_steps := int(walk_dur / 0.12)
		for s in range(num_steps):
			var rot := 6.0 if (s % 2 == 0) else -6.0
			var bounce_y := player_ground_y - (3.0 if (s % 2 == 0) else 0.0)
			waddle_tween.tween_property(player_visual, "rotation_degrees", rot, 0.06)
			waddle_tween.parallel().tween_property(player, "global_position:y", bounce_y, 0.06)
		waddle_tween.chain().tween_callback(func():
			if is_instance_valid(player_visual):
				player_visual.rotation_degrees = 0.0
			if is_instance_valid(player):
				player.global_position.y = player_ground_y
		)
	)

	var reunion_time: float = walk_start_time + walk_dur
	var crouch_duration: float = 2.0

	var reunion_tween := level_node.create_tween()
	reunion_tween.tween_interval(reunion_time)
	reunion_tween.tween_callback(func():
		if is_instance_valid(player):
			player.global_position.y = player_ground_y
		if is_instance_valid(player_visual):
			player_visual.rotation_degrees = 0.0
			player_visual.scale = Vector2(-1.0, 1.0)
		if is_instance_valid(gf):
			gf.rotation_degrees = 0.0
			gf.scale = Vector2(1.0, 1.0)

		# Detach crate from player and place down on summit ground between BF and GF
		if is_instance_valid(crate_ref):
			crate_ref.reparent(level_node)
			crate_ref.global_position = Vector2(right_target_x - 55.0, ground_surface_y - 14.0)
			crate_ref.scale = Vector2(0.11, 0.11)

			var crate_pop := level_node.create_tween()
			crate_pop.tween_property(crate_ref, "scale", Vector2(0.15, 0.08), 0.08)
			crate_pop.tween_property(crate_ref, "scale", Vector2(0.11, 0.11), 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

		var step_dur := 0.08
		var num_cycles := 11

		var p_tween := level_node.create_tween()
		var gf_tween := level_node.create_tween()

		for i in range(num_cycles):
			if is_instance_valid(player_visual):
				p_tween.tween_property(player_visual, "scale", Vector2(-1.35, 0.60), step_dur)
			if is_instance_valid(gf):
				gf_tween.tween_property(gf, "scale", Vector2(0.70, 1.35), step_dur)

			if is_instance_valid(player_visual):
				p_tween.tween_property(player_visual, "scale", Vector2(-0.70, 1.35), step_dur)
			if is_instance_valid(gf):
				gf_tween.tween_property(gf, "scale", Vector2(1.35, 0.60), step_dur)

		if is_instance_valid(player_visual):
			p_tween.tween_property(player_visual, "scale", Vector2(-1.0, 1.0), 0.10)
		if is_instance_valid(gf):
			gf_tween.tween_property(gf, "scale", Vector2(1.0, 1.0), 0.10)
	)

	var finish_time: float = reunion_time + crouch_duration
	var victory_tween := level_node.create_tween()
	victory_tween.tween_interval(finish_time)
	victory_tween.tween_callback(func():
		_trigger_victory()
	)

func _trigger_victory() -> void:
	var level_node = get_tree().current_scene
	if not level_node: return
	
	SaveManager.current_save_data["has_finished_game"] = true
	SaveManager.current_save_data["is_completed_run"] = true
	SaveManager.save_current_state()
	var menu_scene = load("res://scenes/ui/main_menu.tscn")
	if menu_scene:
		var menu = menu_scene.instantiate()
		menu.is_save_menu = true
		level_node.add_child(menu)




