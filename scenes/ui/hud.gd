extends CanvasLayer

## HUD script managing in-game counter button, menu, and inventory modal
@onready var control: Control = $Control
@onready var letter_counter_btn: Button = $Control/TopBar/MarginContainer/HBoxContainer/LetterCounterBtn
@onready var menu_btn: Control = $Control/TopBar/MarginContainer/HBoxContainer/MenuBtn
@onready var letter_inventory: CanvasLayer = $LetterInventory

func _ready() -> void:
	if control:
		control.show()
		
	var lm = get_node_or_null("/root/LetterManager")
	var count: int = lm.get_collected_count() if lm else 0
	update_counter(count)
	
	if lm:
		if not lm.letter_collected.is_connected(_on_letter_collected):
			lm.letter_collected.connect(_on_letter_collected)
	if letter_counter_btn:
		if not letter_counter_btn.pressed.is_connected(_on_counter_pressed):
			letter_counter_btn.pressed.connect(_on_counter_pressed)
	if menu_btn:
		if menu_btn.has_signal("pressed") and not menu_btn.pressed.is_connected(_on_menu_pressed):
			menu_btn.pressed.connect(_on_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			_on_debug_end_pressed()
		elif event.keycode == KEY_F2:
			_on_debug_intro_pressed()

func update_counter(count: int) -> void:
	if letter_counter_btn:
		var lm = get_node_or_null("/root/LetterManager")
		var total_available: int = lm.TOTAL_LETTERS if lm else 21
		var safe_count: int = clampi(count, 0, total_available)
		letter_counter_btn.text = "%d / %d Letters" % [safe_count, total_available]

func show_summit_celebration() -> void:
	var celeb_scene = load("res://scenes/ui/summit_celebration.tscn")
	if celeb_scene:
		var celeb = celeb_scene.instantiate()
		add_child(celeb)

func show_incomplete_prompt(collected: int, required: int) -> void:
	var popup_scene = load("res://scenes/ui/letter_popup.tscn")
	if popup_scene:
		var popup = popup_scene.instantiate()
		add_child(popup)
		if popup.has_method("display_message"):
			popup.display_message("Summit Reached!", "You made it to the top! But you still need to collect all %d letters to unlock the birthday surprise! (%d/%d collected)" % [required, collected, required])

func _on_letter_collected(_id: int, _msg: String, total: int) -> void:
	update_counter(total)

func _on_counter_pressed() -> void:
	if letter_inventory:
		letter_inventory.open_inventory()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_debug_intro_pressed() -> void:
	var current = get_tree().current_scene
	if current and current.has_method("play_intro_sequence"):
		current.play_intro_sequence()

func _on_debug_end_pressed() -> void:
	# Grant all 21 letters for testing
	var lm = get_node_or_null("/root/LetterManager")
	if lm:
		lm.collect_letter_bundle(1, 21)
		
	# Find FinishTrigger and trigger cutscene directly
	var current = get_tree().current_scene
	var finish_trigger = current.get_node_or_null("FinishTrigger") if current else null
	var player = current.get_node_or_null("Player") if current else null
	
	if finish_trigger and player and finish_trigger.has_method("_play_finish_sequence"):
		player.global_position = finish_trigger.global_position
		finish_trigger._play_finish_sequence(player)
	else:
		show_summit_celebration()
