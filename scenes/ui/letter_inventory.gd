extends CanvasLayer

## Letter Inventory modal to view all 21 collected letters
@onready var control: Control = $Control
@onready var title_label: Label = $Control/Panel/MarginContainer/VBoxContainer/Header/TitleLabel
@onready var grid_container: GridContainer = $Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/GridContainer
@onready var selected_title: Label = $Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/ReadingPane/SelectedTitle
@onready var selected_text: Label = $Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/ReadingPane/SelectedText
@onready var close_btn: Button = $Control/Panel/MarginContainer/VBoxContainer/CloseBtn

var selected_id: int = -1

func _ready() -> void:
	control.hide()
	close_btn.pressed.connect(hide_inventory)

func open_inventory() -> void:
	var lm = get_node_or_null("/root/LetterManager")
	var count = lm.collected_letter_ids.size() if lm else 0
	title_label.text = "💌 Collected Letters (%d / 21)" % count
	
	_populate_grid()
	
	# Select first collected letter if available
	if lm and count > 0:
		_select_letter(lm.collected_letter_ids[0])
	else:
		selected_title.text = "Select a Letter"
		selected_text.text = "Climb higher to collect letters scattered across the platforms!"
		
	control.show()
	get_tree().paused = true

func hide_inventory() -> void:
	control.hide()
	get_tree().paused = false

func _populate_grid() -> void:
	# Clear previous buttons
	for child in grid_container.get_children():
		child.queue_free()
		
	var lm = get_node_or_null("/root/LetterManager")
	
	for i in range(1, 22):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(70, 70)
		btn.add_theme_font_size_override("font_size", 18)
		
		var is_collected: bool = lm.is_letter_collected(i) if lm else false
		if is_collected:
			btn.text = "💌\n#%d" % i
			btn.pressed.connect(_select_letter.bind(i))
		else:
			btn.text = "🔒\n#%d" % i
			btn.disabled = true
			
		grid_container.add_child(btn)

func _select_letter(id: int) -> void:
	selected_id = id
	var lm = get_node_or_null("/root/LetterManager")
	var msg: String = lm.get_letter_message(id) if lm else ""
	
	selected_title.text = "💌 Letter #%d" % id
	selected_text.text = msg
