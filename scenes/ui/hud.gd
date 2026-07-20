extends CanvasLayer

## HUD script managing in-game counter button, menu, and inventory modal
@onready var letter_counter_btn: Button = $Control/TopBar/MarginContainer/HBoxContainer/LetterCounterBtn
@onready var menu_btn: Button = $Control/TopBar/MarginContainer/HBoxContainer/MenuBtn
@onready var letter_inventory: CanvasLayer = $LetterInventory

func _ready() -> void:
	var lm = get_node_or_null("/root/LetterManager")
	var count = lm.collected_letter_ids.size() if lm else 0
	update_counter(count)
	
	if lm:
		lm.letter_collected.connect(_on_letter_collected)
	if letter_counter_btn:
		letter_counter_btn.pressed.connect(_on_counter_pressed)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)

func update_counter(count: int) -> void:
	if letter_counter_btn:
		letter_counter_btn.text = "💌 %d / 21  (Open Journal)" % count

func _on_letter_collected(_id: int, _msg: String, total: int) -> void:
	update_counter(total)

func _on_counter_pressed() -> void:
	if letter_inventory:
		letter_inventory.open_inventory()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
