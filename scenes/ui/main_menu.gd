extends CanvasLayer

## Main Menu HUD overlay controller
signal new_game_started
signal continue_started

@onready var btn_new_game: UiverseButton = $ButtonContainer/BtnNewGame
@onready var btn_continue: UiverseButton = $ButtonContainer/BtnContinue

var is_boot_menu: bool = false
var is_save_menu: bool = false

func _ready() -> void:
	# Hide gameplay HUD and touch controls while main menu is active
	_set_gameplay_ui_visible(false)
	tree_exiting.connect(_on_tree_exiting)

	var sm = get_node_or_null("/root/SaveManager")
	var has_save: bool = sm.has_save_data() if sm else false
	var is_in_game: bool = not is_boot_menu
	
	# Enable Continue if save data exists OR if currently in active gameplay
	btn_continue.disabled = not (has_save or is_in_game)
	
	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)

func _on_tree_exiting() -> void:
	if not is_boot_menu:
		_set_gameplay_ui_visible(true)

func _set_gameplay_ui_visible(p_visible: bool) -> void:
	if not is_inside_tree() or not get_tree():
		return
	var current = get_tree().current_scene
	if not current:
		return
	var hud = current.get_node_or_null("HUD")
	if hud:
		hud.visible = p_visible
	var touch = current.get_node_or_null("TouchControls")
	if touch:
		touch.visible = p_visible

func _on_new_game_pressed() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		sm.clear_save()
		if is_boot_menu:
			sm.force_intro_on_launch = false
		else:
			sm.force_intro_on_launch = true
	var lm = get_node_or_null("/root/LetterManager")
	if lm:
		lm.reset_progress()
	
	new_game_started.emit()
	
	if is_boot_menu:
		queue_free()
	else:
		get_tree().reload_current_scene()


func _on_continue_pressed() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.has_save_data():
		sm.load_game()
	continue_started.emit()
	queue_free()
