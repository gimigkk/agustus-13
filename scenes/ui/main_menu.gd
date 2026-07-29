extends CanvasLayer

## Main Menu UI overlay for starting a New Game or continuing progress.

## Emitted when the user confirms starting a New Game. Listened to by level scene controllers.
signal new_game_started

## Emitted when the user continues gameplay. Listened to by level scene controllers.
signal continue_started

@onready var btn_new_game: UiverseButton = $ButtonContainer/BtnNewGame
@onready var btn_read_letters: UiverseButton = $ButtonContainer/BtnReadLetters
@onready var btn_continue: UiverseButton = $ButtonContainer/BtnContinue

# Configuration flags set by level controller:
# - is_boot_menu: active at boot summit before gameplay; closing unblocks Stage 2 cutscene.
# - is_save_menu: active over existing save data during gameplay.
var is_boot_menu: bool = false
var is_save_menu: bool = false

func _ready() -> void:
	_set_gameplay_ui_visible(false)
	tree_exiting.connect(_on_tree_exiting)

	var has_save: bool = SaveManager.has_save_data()
	var is_in_game: bool = not is_boot_menu
	
	btn_continue.disabled = not (has_save or is_in_game)
	btn_read_letters.visible = SaveManager.current_save_data.get("has_finished_game", false)
	
	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_read_letters.pressed.connect(_on_read_letters_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)

func _on_tree_exiting() -> void:
	if not is_boot_menu:
		_set_gameplay_ui_visible(true)

func _set_gameplay_ui_visible(p_visible: bool) -> void:
	var current = get_tree().current_scene if get_tree() else null
	if not current:
		return
	var hud = current.get_node_or_null("HUD")
	if hud and hud.has_node("Control"):
		hud.get_node("Control").visible = p_visible
	var touch = current.get_node_or_null("TouchControls")
	if touch:
		touch.visible = p_visible

# New Game flow:
# - Clears SaveManager & LetterManager state.
# - If called from boot menu: frees menu to trigger cutscene in test_level.gd.
# - If called in-game: reloads level scene to reset player position to summit.
func _on_new_game_pressed() -> void:
	SaveManager.clear_save()
	SaveManager.force_intro_on_launch = not is_boot_menu
	LetterManager.reset_progress()
	
	new_game_started.emit()
	
	if is_boot_menu:
		queue_free()
	else:
		get_tree().reload_current_scene()

# Continue flow:
# - Restores saved position via SaveManager.load_game().
# - Frees menu layer to expose underlying gameplay.
func _on_continue_pressed() -> void:
	if SaveManager.has_save_data():
		SaveManager.load_game()
	continue_started.emit()
	queue_free()

func _on_read_letters_pressed() -> void:
	var current = get_tree().current_scene if get_tree() else null
	if not current: return
	var hud = current.get_node_or_null("HUD")
	if hud and "letter_inventory" in hud and hud.letter_inventory:
		hud.letter_inventory.open_inventory(true)
