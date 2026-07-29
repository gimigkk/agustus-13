extends Node

## Autoload Singleton managing disk save file serialization, position tracking, and progress persistence.

## Emitted when save data is loaded into memory. Listened to by game state restore logic.
signal save_loaded(data: Dictionary)

const SAVE_PATH: String = "user://save_data.json"

# Set true by MainMenu on New Game to force cutscene flow on next level load.
var force_intro_on_launch: bool = false

var current_save_data: Dictionary = {
	"player_pos_x": 0.0,
	"player_pos_y": 1180.0,
	"collected_letters": [],
	"global_collected_letters": [],
	"has_save": false,
	"has_finished_game": false,
	"is_completed_run": false
}

func _ready() -> void:
	load_game()

# OS Window Close / Mobile Back Button Hook: automatically triggers save on app termination.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save_current_state()

func has_save_data() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

# Queries current_scene for "Player" (CharacterBody2D). Saves position ONLY if player physics is active.
func save_current_state() -> bool:
	if not get_tree() or not get_tree().current_scene:
		return false
	var player = get_tree().current_scene.get_node_or_null("Player") as CharacterBody2D
	if not is_instance_valid(player):
		return false
		
	if not player.is_physics_processing():
		return false
		
	return save_game(player.global_position, LetterManager.collected_letter_ids, LetterManager.global_letter_ids)

func save_game(player_pos: Vector2, collected_letters: Array, global_letters: Array) -> bool:
	var finished = current_save_data.get("has_finished_game", false)
	var completed = current_save_data.get("is_completed_run", false)
	var data := {
		"player_pos_x": player_pos.x,
		"player_pos_y": player_pos.y,
		"collected_letters": collected_letters,
		"global_collected_letters": global_letters,
		"has_save": true,
		"has_finished_game": finished,
		"is_completed_run": completed,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: Failed to open save file for writing.")
		return false
		
	var json_string := JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()
	
	current_save_data = data
	return true

## Reads save data from JSON file into current_save_data dictionary.
func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return current_save_data
		
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("SaveManager: Failed to open save file for reading.")
		return current_save_data
		
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		push_error("SaveManager: Failed to parse save JSON.")
		return current_save_data
		
	if json.data is Dictionary:
		current_save_data = json.data
		save_loaded.emit(current_save_data)
		
	return current_save_data

func clear_save() -> void:
	var global_letters = current_save_data.get("global_collected_letters", [])
	var finished_game = current_save_data.get("has_finished_game", false)
	
	current_save_data = {
		"player_pos_x": 0.0,
		"player_pos_y": 1180.0,
		"collected_letters": [],
		"global_collected_letters": global_letters,
		"has_save": false,
		"has_finished_game": finished_game,
		"is_completed_run": false
	}
	force_intro_on_launch = true
	
	var data := current_save_data.duplicate()
	data["timestamp"] = Time.get_unix_time_from_system()
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func clear_all_save_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	current_save_data = {
		"player_pos_x": 0.0,
		"player_pos_y": 1180.0,
		"collected_letters": [],
		"global_collected_letters": [],
		"has_save": false,
		"has_finished_game": false
	}
	force_intro_on_launch = true
	if LetterManager:
		LetterManager.collected_letter_ids.clear()
		if "global_letter_ids" in LetterManager:
			LetterManager.global_letter_ids.clear()
