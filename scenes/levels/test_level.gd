extends Node2D

## Main Level Script managing Intro Cutscene, Main Menu Overlay & Global level state
const IntroCutsceneScript = preload("res://scripts/intro_cutscene.gd")
const MainMenuScene = preload("res://scenes/ui/main_menu.tscn")

@export var auto_play_intro_on_editor_test: bool = true

var intro_manager: Node = null

func _ready() -> void:
	print("[TestLevel] _ready() called")
	var sm = get_node_or_null("/root/SaveManager")
	var force_full_intro: bool = false
	
	if sm:
		if sm.force_intro_on_launch:
			force_full_intro = true
			sm.force_intro_on_launch = false

	if force_full_intro:
		# Mid-game "New Game" forces the full intro instantly
		print("[TestLevel] force_intro_on_launch is true -> starting full intro cutscene directly.")
		call_deferred("play_full_intro_sequence")
	elif sm and sm.has_save_data():
		# Save Boot: bypass intro, teleport player, show menu
		print("[TestLevel] Save file found -> Bypassing intro and teleporting player.")
		
		# Move player directly to saved position
		var px: float = float(sm.current_save_data.get("player_pos_x", 0.0))
		var py: float = float(sm.current_save_data.get("player_pos_y", 1140.0))
		var player = get_node_or_null("Player")
		if is_instance_valid(player):
			player.global_position = Vector2(px, py)
			if "velocity" in player:
				player.velocity = Vector2.ZERO
			var cam = player.get_node_or_null("Camera2D")
			if is_instance_valid(cam):
				cam.reset_smoothing()
				
		call_deferred("_instantiate_main_menu", true)
	else:
		# Boot flow: Play Stage 1, then show menu
		print("[TestLevel] Booting level -> playing Stage 1 Boot Cutscene.")
		call_deferred("play_boot_intro_stage_1")


func play_boot_intro_stage_1() -> void:
	print("[TestLevel] play_boot_intro_stage_1() called")
	_setup_intro_manager()
	
	# When Stage 1 completes, pause the cutscene and show the Main Menu
	intro_manager.stage_1_completed.connect(func():
		print("[TestLevel] Stage 1 finished. Pausing cutscene and instantiating Main Menu.")
		_instantiate_main_menu(false)
	)
	
	intro_manager.play_intro_stage_1(self)


func play_full_intro_sequence() -> void:
	print("[TestLevel] play_full_intro_sequence() called")
	_setup_intro_manager()
	
	intro_manager.stage_1_completed.connect(func():
		print("[TestLevel] Full Intro: Stage 1 finished -> Continuing instantly to Stage 2.")
		intro_manager.play_intro_stage_2()
	)
	
	intro_manager.play_intro_stage_1(self)


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
		print("[TestLevel] MainMenu -> New Game selected. Resuming Cutscene (Stage 2).")
		if is_instance_valid(intro_manager) and intro_manager.has_method("play_intro_stage_2"):
			intro_manager.play_intro_stage_2()
	)

	menu.continue_started.connect(func():
		print("[TestLevel] MainMenu -> Continue selected. Aborting cutscene and teleporting.")
		if is_instance_valid(intro_manager) and intro_manager.has_method("abort_intro"):
			intro_manager.abort_intro()
			
		var sm = get_node_or_null("/root/SaveManager")
		if sm and sm.current_save_data.get("has_save", false):
			var px: float = float(sm.current_save_data.get("player_pos_x", 0.0))
			var py: float = float(sm.current_save_data.get("player_pos_y", 1140.0))
			
			var player = get_node_or_null("Player")
			if is_instance_valid(player):
				player.global_position = Vector2(px, py)
				if "velocity" in player:
					player.velocity = Vector2.ZERO
				var cam = player.get_node_or_null("Camera2D")
				if is_instance_valid(cam):
					cam.reset_smoothing()
	)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F2:
		print("[TestLevel] F2 pressed -> triggering intro")
		play_full_intro_sequence()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		print("[TestLevel] F3 pressed -> clearing save and reloading scene")
		var sm = get_node_or_null("/root/SaveManager")
		if sm and sm.has_method("clear_save"):
			sm.clear_save()
			sm.force_intro_on_launch = false
		get_tree().reload_current_scene()
