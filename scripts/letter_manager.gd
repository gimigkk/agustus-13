extends Node

## LetterManager Autoload Singleton to handle letter messages and collection state
signal letter_collected(letter_id: int, message: String, total_collected: int)
signal letter_popup_requested(letter_id: int, message: String)

const TOTAL_LETTERS: int = 21

var messages: Dictionary = {}
var collected_letter_ids: Array = []

func _ready() -> void:
	load_messages()
	# Restore collected letters from save
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.current_save_data.has("collected_letters"):
		collected_letter_ids = sm.current_save_data["collected_letters"].duplicate()

func load_messages() -> void:
	var path := "res://letters.json"
	if not FileAccess.file_exists(path):
		path = "res://letters.example.json"
		
	if not FileAccess.file_exists(path):
		push_error("LetterManager: No letters JSON file found!")
		return
		
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return
		
	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	if json.parse(json_text) == OK and json.data is Dictionary:
		messages = json.data
	else:
		push_error("LetterManager: Invalid JSON in letters file.")

func get_letter_message(letter_id: int) -> String:
	var key := str(letter_id)
	if messages.has(key):
		return str(messages[key])
	return "Letter #%d: A special memory..." % letter_id

func is_letter_collected(letter_id: int) -> bool:
	return collected_letter_ids.has(letter_id)

func collect_letter(letter_id: int, player_pos: Vector2 = Vector2.ZERO) -> bool:
	if is_letter_collected(letter_id):
		return false
		
	collected_letter_ids.append(letter_id)
	var msg := get_letter_message(letter_id)
	
	# Auto-save game state
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		sm.save_game(player_pos, collected_letter_ids)
		
	emit_signal("letter_collected", letter_id, msg, collected_letter_ids.size())
	emit_signal("letter_popup_requested", letter_id, msg)
	return true

func reset_progress() -> void:
	collected_letter_ids.clear()
