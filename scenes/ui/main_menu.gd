extends Control

## Main Menu script handling New Game and Continue flows
@onready var btn_new_game: Button = $VBoxContainer/BtnNewGame
@onready var btn_continue: Button = $VBoxContainer/BtnContinue

func _ready() -> void:
	# Enable Continue button only if save file exists
	var sm = get_node_or_null("/root/SaveManager")
	var has_save: bool = sm.has_save_data() if sm else false
	btn_continue.disabled = not has_save
	
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
