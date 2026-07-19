extends Node

## SaveManager Autoload Singleton
signal save_loaded(data: Dictionary)

const SAVE_PATH: String = "user://save_data.json"

var current_save_data: Dictionary = {
	"player_pos_x": 0.0,
	"player_pos_y": 1180.0,
	"collected_letters": [],
	"has_save": false
}

func _ready() -> void:
	load_game()

func has_save_data() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game(player_pos: Vector2, collected_letters: Array) -> bool:
	var data := {
		"player_pos_x": player_pos.x,
		"player_pos_y": player_pos.y,
		"collected_letters": collected_letters,
		"has_save": true,
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
		emit_signal("save_loaded", current_save_data)
		
	return current_save_data

func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	current_save_data = {
		"player_pos_x": 0.0,
		"player_pos_y": 1180.0,
		"collected_letters": [],
		"has_save": false
	}
