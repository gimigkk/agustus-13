extends Node2D

## Root level controller orchestrating boot flow, cutscene sequences, and main menu loading.

const IntroCutsceneScript = preload("res://scripts/intro_cutscene.gd")
const MainMenuScene = preload("res://scenes/ui/main_menu.tscn")

@export var auto_play_intro_on_editor_test: bool = true

var intro_manager: Node = null

# Boot decision tree:
# 1. Force Intro flag -> play full 2-stage intro.
# 2. Existing Save -> restore Player position and show in-game menu.
# 3. Fresh Boot -> play Stage 1 summit intro, then show boot main menu.
func _ready() -> void:
	var force_full_intro: bool = false
	if SaveManager.force_intro_on_launch:
		force_full_intro = true
		SaveManager.force_intro_on_launch = false

	if force_full_intro:
		call_deferred("play_full_intro_sequence")
	elif SaveManager.has_save_data():
		var px: float = float(SaveManager.current_save_data.get("player_pos_x", 0.0))
		var py: float = float(SaveManager.current_save_data.get("player_pos_y", 1140.0))
		var player = get_node_or_null("Player") as CharacterBody2D
		if is_instance_valid(player):
			player.global_position = Vector2(px, py)
			player.velocity = Vector2.ZERO
			var cam = player.get_node_or_null("Camera2D") as Camera2D
			if is_instance_valid(cam):
				cam.reset_smoothing()
				
		call_deferred("_instantiate_main_menu", true)
	else:
		call_deferred("play_boot_intro_stage_1")

# Triggers Stage 1 cutscene -> on completion opens Boot Main Menu.
func play_boot_intro_stage_1() -> void:
	_setup_intro_manager()
	intro_manager.stage_1_completed.connect(func():
		_instantiate_main_menu(false)
	)
	intro_manager.play_intro_stage_1(self)

# Triggers Stage 1 cutscene -> automatically chains into Stage 2 (New Game sequence).
func play_full_intro_sequence() -> void:
	_setup_intro_manager()
	intro_manager.stage_1_completed.connect(func():
		intro_manager.play_intro_stage_2()
	)
	intro_manager.play_intro_stage_1(self)

## Creates and attaches an IntroCutscene node instance to the level.
func _setup_intro_manager() -> void:
	if is_instance_valid(intro_manager):
		intro_manager.queue_free()

	intro_manager = IntroCutsceneScript.new()
	intro_manager.name = "IntroCutsceneManager"
	add_child(intro_manager)
	
	intro_manager.intro_completed.connect(func():
		if is_instance_valid(intro_manager):
			intro_manager.queue_free()
	)

## Spawns the main menu overlay configured for boot or existing save resumption.
func _instantiate_main_menu(is_save_boot: bool = false) -> void:
	var hud = get_node_or_null("HUD")
	if hud:
		hud.visible = false
	var touch = get_node_or_null("TouchControls")
	if touch:
		touch.visible = false
		
	await RenderingServer.frame_post_draw
	if not is_inside_tree():
		return
	var menu = MainMenuScene.instantiate()
	menu.is_boot_menu = not is_save_boot
	menu.is_save_menu = is_save_boot
	add_child(menu)
	
	menu.new_game_started.connect(func():
		if is_instance_valid(intro_manager):
			intro_manager.play_intro_stage_2()
	)

	menu.continue_started.connect(func():
		if is_instance_valid(intro_manager):
			intro_manager.abort_intro()
			
		if SaveManager.current_save_data.get("has_save", false):
			var px: float = float(SaveManager.current_save_data.get("player_pos_x", 0.0))
			var py: float = float(SaveManager.current_save_data.get("player_pos_y", 1140.0))
			var player = get_node_or_null("Player") as CharacterBody2D
			if is_instance_valid(player):
				player.global_position = Vector2(px, py)
				player.velocity = Vector2.ZERO
				var cam = player.get_node_or_null("Camera2D") as Camera2D
				if is_instance_valid(cam):
					cam.reset_smoothing()
	)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F2:
			play_full_intro_sequence()
		elif event.keycode == KEY_F3:
			SaveManager.clear_save()
			SaveManager.force_intro_on_launch = false
			get_tree().reload_current_scene()
