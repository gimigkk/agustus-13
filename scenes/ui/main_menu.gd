extends Control

const UIThemeHelper = preload("res://scenes/ui/ui_theme_helper.gd")

## Main Menu script handling New Game and Continue flows
@onready var btn_new_game: Button = $VBoxContainer/BtnNewGame
@onready var btn_continue: Button = $VBoxContainer/BtnContinue

func _ready() -> void:
	# Enable Continue button only if save file exists
	var sm = get_node_or_null("/root/SaveManager")
	var has_save: bool = sm.has_save_data() if sm else false
	btn_continue.disabled = not has_save

	# Style buttons with Fake 3D / AnimatedButton look
	if btn_continue:
		UIThemeHelper.apply_fake_3d_style(btn_continue, Color(0.15, 0.18, 0.28, 0.95), Color(0.3, 0.8, 1.0, 0.9), Color(1.0, 1.0, 1.0, 1.0), Color(0.1, 0.1, 0.1, 1.0), Color(0.68, 1.0, 0.18, 1.0), 32)
	if btn_new_game:
		UIThemeHelper.apply_fake_3d_style(btn_new_game, Color(0.18, 0.15, 0.28, 0.95), Color(1.0, 0.8, 0.3, 0.9), Color(1.0, 0.9, 0.4, 1.0), Color(0.1, 0.1, 0.1, 1.0), Color(0.68, 1.0, 0.18, 1.0), 32)
	
	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)

func _on_new_game_pressed() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		sm.clear_save()
	var lm = get_node_or_null("/root/LetterManager")
	if lm:
		lm.reset_progress()
	get_tree().change_scene_to_file("res://scenes/levels/test_level.tscn")

func _on_continue_pressed() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		sm.load_game()
	get_tree().change_scene_to_file("res://scenes/levels/test_level.tscn")
