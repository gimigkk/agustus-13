extends Control

## Main Menu script handling New Game and Continue flows
@onready var btn_new_game: Button = $VBoxContainer/BtnNewGame
@onready var btn_continue: Button = $VBoxContainer/BtnContinue

func _ready() -> void:
	# Enable Continue button only if save file exists
	var has_save := SaveManager.has_save_data() if SaveManager else false
	btn_continue.disabled = not has_save
	
	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)

func _on_new_game_pressed() -> void:
	if SaveManager:
		SaveManager.clear_save()
	if LetterManager:
		LetterManager.reset_progress()
	get_tree().change_scene_to_file("res://scenes/levels/test_level.tscn")

func _on_continue_pressed() -> void:
	if SaveManager:
		SaveManager.load_game()
	get_tree().change_scene_to_file("res://scenes/levels/test_level.tscn")
