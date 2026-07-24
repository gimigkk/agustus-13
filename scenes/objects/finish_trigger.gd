extends Area2D

## Finish Goal Trigger at the Summit Peak with Cutscene Sequence
@export var required_letters: int = 21

## Cutscene Positions (relative or absolute)
@export var left_landing_offset: Vector2 = Vector2(-200, 0)
@export var right_target_offset: Vector2 = Vector2(400, 0)
@export var pop_up_height: float = 220.0
@export var pause_before_run: float = 2 # Brief pause on left platform before running right

@onready var visual: ColorRect = $Visual
@onready var label: Label = $Visual/Label

var is_triggered: bool = false

func _ready() -> void:
	if not Engine.is_editor_hint():
		if visual:
			visual.hide() # Make visual invisible during gameplay
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_triggered or not (body is CharacterBody2D):
		return
		
	var lm = get_node_or_null("/root/LetterManager")
	var collected: int = lm.get_collected_count() if lm else 0
	
	if collected >= required_letters:
		is_triggered = true
		_play_finish_sequence(body as CharacterBody2D)
	else:
		_show_incomplete_prompt(collected, required_letters)

func _play_finish_sequence(player: CharacterBody2D) -> void:
	# 1. Lock player controls and disable collision during cutscene
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	var player_col = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if is_instance_valid(player_col):
		player_col.set_deferred("disabled", true)
	
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud and hud.has_node("Control"):
		hud.get_node("Control").hide()
	var touch_ui = get_tree().current_scene.get_node_or_null("TouchControls")
	if touch_ui:
		touch_ui.hide()

	# Calculate positions
	var start_pos := player.global_position
	var left_land := global_position + left_landing_offset
	var right_target := left_land + right_target_offset
	var peak_y: float = minf(start_pos.y, left_land.y) - pop_up_height

	var arc_duration: float = 1.2
	var half_arc: float = arc_duration * 0.5

	# Create cutscene animation tween sequence
	var tween := create_tween().set_parallel(true)
	
	# Parabolic Arc: X and Y synced perfectly
	# 1. Horizontal: X moves linearly across full 1.2s
	tween.tween_property(player, "global_position:x", left_land.x, arc_duration).set_trans(Tween.TRANS_LINEAR)

	# 2. Vertical Rise: 0.0s -> 0.6s (Ease Out to 0 speed at peak)
	tween.tween_property(player, "global_position:y", peak_y, half_arc).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3. Vertical Fall: 0.6s -> 1.2s (Ease In down to platform)
	tween.tween_property(player, "global_position:y", left_land.y, half_arc).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(half_arc)

	# Phase C: Happy bounce emote & turn right on left platform
	var player_visual = player.get_node_or_null("Visual")
	if player_visual:
		tween.tween_property(player_visual, "scale:y", 1.35, 0.15).set_delay(arc_duration)
		tween.tween_property(player_visual, "scale:y", 1.0, 0.15).set_delay(arc_duration + 0.15)
		tween.tween_callback(func():
			player_visual.scale.x = 1.0 # Face right towards girlfriend
		).set_delay(arc_duration + 0.3)

	# Phase D: Brief Pause before starting to walk right
	var run_start_delay: float = arc_duration + 0.3 + pause_before_run
	tween.tween_property(player, "global_position:x", right_target.x, 1.8).set_trans(Tween.TRANS_LINEAR).set_delay(run_start_delay)

	# Phase E: Trigger Victory Celebration Screen!
	var finish_time: float = run_start_delay + 1.8
	tween.tween_callback(func():
		_trigger_victory()
	).set_delay(finish_time)

func _trigger_victory() -> void:
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud and hud.has_method("show_summit_celebration"):
		hud.show_summit_celebration()
	else:
		var celeb_scene = load("res://scenes/ui/summit_celebration.tscn")
		if celeb_scene:
			var celeb = celeb_scene.instantiate()
			get_tree().current_scene.add_child(celeb)

func _show_incomplete_prompt(collected: int, required: int) -> void:
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud and hud.has_method("show_incomplete_prompt"):
		hud.show_incomplete_prompt(collected, required)
