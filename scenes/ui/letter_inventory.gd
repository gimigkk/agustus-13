extends CanvasLayer

## Letter Inventory modal - 3x7 Grid of 21 Letter slots
@onready var control: Control = $Control
@onready var title_label: Label = $Control/Panel/MarginContainer/VBoxContainer/Header/TitleLabel
@onready var grid_container: GridContainer = $Control/Panel/MarginContainer/VBoxContainer/GridContainer
@onready var close_btn: Button = $Control/Panel/MarginContainer/VBoxContainer/CloseBtn

func _ready() -> void:
	control.hide()
	close_btn.pressed.connect(hide_inventory)

func open_inventory() -> void:
	var lm = get_node_or_null("/root/LetterManager")
	var count: int = lm.collected_letter_ids.size() if lm else 0
	title_label.text = "Letters (%d / 21)" % count
	
	_populate_grid()
	control.show()
	get_tree().paused = true

func hide_inventory() -> void:
	control.hide()
	get_tree().paused = false

func _populate_grid() -> void:
	# Clear existing items
	for child in grid_container.get_children():
		child.queue_free()
		
	var lm = get_node_or_null("/root/LetterManager")
	
	for i in range(1, 22):
		var is_collected: bool = lm.is_letter_collected(i) if lm else false
		
		var card := Button.new()
		card.custom_minimum_size = Vector2(175, 95)
		card.add_theme_font_size_override("font_size", 18)
		
		if is_collected:
			card.text = "Letter #%d" % i
			card.pressed.connect(_on_letter_clicked.bind(i))
		else:
			card.text = "Locked"
			card.disabled = true
			
		grid_container.add_child(card)

func _on_letter_clicked(letter_id: int) -> void:
	var popup = get_node_or_null("../LetterPopup")
	if not popup:
		popup = get_node_or_null("/root/TestLevel/HUD/LetterPopup")
	if popup and popup.has_method("show_letter"):
		popup.show_letter(letter_id)
