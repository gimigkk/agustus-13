extends Node

## LetterManager Autoload Singleton to handle letter messages and collection state
signal letter_collected(letter_id: int, message: String, total_collected: int)

const TOTAL_LETTERS: int = 21

var messages: Dictionary = {}
var collected_letter_ids: Array = []

func _ready() -> void:
	load_messages()
	# Restore collected letters from save (sanitized & deduplicated)
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.current_save_data.has("collected_letters"):
		var raw_list: Array = sm.current_save_data["collected_letters"]
		collected_letter_ids.clear()
		for item in raw_list:
			var int_id := int(item)
			if int_id >= 1 and int_id <= TOTAL_LETTERS and not collected_letter_ids.has(int_id):
				collected_letter_ids.append(int_id)

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
	return collected_letter_ids.has(int(letter_id))

func get_collected_count() -> int:
	var unique_ids: Array = []
	for id in collected_letter_ids:
		var int_id := int(id)
		if int_id >= 1 and int_id <= TOTAL_LETTERS and not unique_ids.has(int_id):
			unique_ids.append(int_id)
	return unique_ids.size()

func is_bundle_collected(start_id: int, count: int) -> bool:
	for i in range(count):
		var id := start_id + i
		if id <= TOTAL_LETTERS and not is_letter_collected(id):
			return false
	return true

func collect_letter(letter_id: int, player_pos: Vector2 = Vector2.ZERO) -> bool:
	return collect_letter_bundle(letter_id, 1, player_pos)

func collect_letter_bundle(start_id: int, count: int, player_pos: Vector2 = Vector2.ZERO) -> bool:
	var newly_collected := false
	var last_id := start_id
	var last_msg := ""
	
	for i in range(count):
		var curr_id := start_id + i
		if curr_id >= 1 and curr_id <= TOTAL_LETTERS and not is_letter_collected(curr_id):
			collected_letter_ids.append(curr_id)
			last_id = curr_id
			last_msg = get_letter_message(curr_id)
			newly_collected = true
			
	if newly_collected:
		var total := get_collected_count()
		# Auto-save game state
		var sm = get_node_or_null("/root/SaveManager")
		if sm:
			sm.save_game(player_pos, collected_letter_ids)
			
		emit_signal("letter_collected", last_id, last_msg, total)
		return true
		
	return false

func reset_progress() -> void:
	collected_letter_ids.clear()
