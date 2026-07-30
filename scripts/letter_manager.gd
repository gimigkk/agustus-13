extends Node

## Autoload Singleton managing letter messages, collection tracking, and save state synchronization.

## Emitted when a letter or bundle of letters is collected in-game.
## Listened to by: HUD (_on_letter_collected triggers flying paper UI animation).
signal letter_collected(letter_id: int, message: String, total_collected: int, collect_pos: Vector2)
## Emitted when a collected letter is opened and read by the player.
signal letter_read(letter_id: int)

## Total number of collectible letters in the game.
const TOTAL_LETTERS: int = 21

var messages: Dictionary = {}
var collected_letter_ids: Array = []
var global_letter_ids: Array = []
var read_letter_ids: Array = []

func _ready() -> void:
	load_messages()
	SaveManager.save_loaded.connect(_on_save_loaded)
	_on_save_loaded(SaveManager.current_save_data)

func _on_save_loaded(data: Dictionary) -> void:
	if data.has("collected_letters"):
		var raw_list: Array = data["collected_letters"]
		collected_letter_ids.clear()
		for item in raw_list:
			var int_id := int(item)
			if int_id >= 1 and int_id <= TOTAL_LETTERS and not collected_letter_ids.has(int_id):
				collected_letter_ids.append(int_id)
				
	if data.has("global_collected_letters"):
		var raw_global: Array = data["global_collected_letters"]
		global_letter_ids.clear()
		for item in raw_global:
			var int_id := int(item)
			if int_id >= 1 and int_id <= TOTAL_LETTERS and not global_letter_ids.has(int_id):
				global_letter_ids.append(int_id)

	if data.has("read_letter_ids"):
		var raw_read: Array = data["read_letter_ids"]
		read_letter_ids.clear()
		for item in raw_read:
			var int_id := int(item)
			if int_id >= 1 and int_id <= TOTAL_LETTERS and not read_letter_ids.has(int_id):
				read_letter_ids.append(int_id)

## Returns true if the specified letter ID has been read.
func is_letter_read(letter_id: int) -> bool:
	return read_letter_ids.has(int(letter_id))

## Marks a letter as read, persists state, and emits letter_read signal.
func mark_letter_as_read(letter_id: int) -> void:
	var int_id := int(letter_id)
	if int_id >= 1 and int_id <= TOTAL_LETTERS and not read_letter_ids.has(int_id):
		read_letter_ids.append(int_id)
		SaveManager.save_game(Vector2.ZERO, collected_letter_ids, global_letter_ids)
		letter_read.emit(int_id)

## Parses messages from the letters JSON data configuration.
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

## Returns the dictionary data for a given letter ID.
func get_letter_data(letter_id: int) -> Dictionary:
	var key := str(letter_id)
	if messages.has(key):
		var data = messages[key]
		if data is Dictionary:
			return data
		elif typeof(data) == TYPE_STRING:
			# Fallback for old save/json format
			return {
				"text": data,
				"author": "Unknown",
				"image": "res://assets/ui/placeholder_decorated_letter.png"
			}
	return {
		"title": "Letter #%d" % letter_id,
		"text": "Letter #%d: A special memory..." % letter_id,
		"author": "Unknown",
		"image": "res://assets/ui/placeholder_decorated_letter.png"
	}

## Returns the text message associated with a given letter ID.
func get_letter_message(letter_id: int) -> String:
	return get_letter_data(letter_id).get("text", "Letter #%d: A special memory..." % letter_id)

## Returns true if the specified letter ID has been collected.
func is_letter_collected(letter_id: int) -> bool:
	return collected_letter_ids.has(int(letter_id))

## Returns true if the specified letter ID has been collected globally.
func is_global_letter_collected(letter_id: int) -> bool:
	return global_letter_ids.has(int(letter_id))

## Returns total count of unique valid letters collected so far.
func get_collected_count() -> int:
	var unique_ids: Array = []
	for id in collected_letter_ids:
		var int_id := int(id)
		if int_id >= 1 and int_id <= TOTAL_LETTERS and not unique_ids.has(int_id):
			unique_ids.append(int_id)
	return unique_ids.size()

## Returns true if all letters in a specified sequence range are collected.
func is_bundle_collected(start_id: int, count: int) -> bool:
	for i in range(count):
		var id := start_id + i
		if id <= TOTAL_LETTERS and not is_letter_collected(id):
			return false
	return true

func collect_letter(letter_id: int, player_pos: Vector2 = Vector2.ZERO, collect_world_pos: Vector2 = Vector2.ZERO) -> bool:
	return collect_letter_bundle(letter_id, 1, player_pos, collect_world_pos)

func collect_letter_bundle(start_id: int, count: int, player_pos: Vector2 = Vector2.ZERO, collect_world_pos: Vector2 = Vector2.ZERO) -> bool:
	var newly_collected := false
	var last_id := start_id
	var last_msg := ""
	
	for i in range(count):
		var curr_id := start_id + i
		if curr_id >= 1 and curr_id <= TOTAL_LETTERS and not is_letter_collected(curr_id):
			collected_letter_ids.append(curr_id)
			if not is_global_letter_collected(curr_id):
				global_letter_ids.append(curr_id)
			last_id = curr_id
			last_msg = get_letter_message(curr_id)
			newly_collected = true
			
	if newly_collected:
		var total := get_collected_count()
		SaveManager.save_game(player_pos, collected_letter_ids, global_letter_ids)
		var final_collect_pos := collect_world_pos if collect_world_pos != Vector2.ZERO else player_pos
		letter_collected.emit(last_id, last_msg, total, final_collect_pos)
		return true
		
	return false

func reset_progress() -> void:
	collected_letter_ids.clear()
