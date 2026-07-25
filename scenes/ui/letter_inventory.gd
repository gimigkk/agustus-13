extends CanvasLayer

const UIThemeHelper = preload("res://scenes/ui/ui_theme_helper.gd")

## Letter Inventory modal - 3x7 Grid of 21 Letter slots
@onready var control: Control = $Control
@onready var title_label: Label = $Control/Panel/MarginContainer/VBoxContainer/Header/TitleLabel
@onready var grid_container: GridContainer = $Control/Panel/MarginContainer/VBoxContainer/GridContainer
@onready var close_btn: Button = $Control/Panel/MarginContainer/VBoxContainer/CloseBtn

func _ready() -> void:
	control.hide()
	if close_btn:
		UIThemeHelper.apply_fake_3d_style(close_btn, Color(0.18, 0.15, 0.28, 0.95), Color(0.9, 0.7, 0.2, 1.0), Color(1.0, 0.85, 0.4, 1.0), Color(0.1, 0.1, 0.1, 1.0), Color(0.68, 1.0, 0.18, 1.0), 24)
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
			UIThemeHelper.apply_fake_3d_style(card, Color(0.12, 0.18, 0.24, 0.95), Color(0.3, 0.8, 1.0, 0.9), Color(1.0, 1.0, 1.0, 1.0), Color(0.1, 0.1, 0.1, 1.0), Color(0.68, 1.0, 0.18, 1.0), 18)
			card.pressed.connect(_on_letter_clicked.bind(i))
		else:
			card.text = "Locked"
			card.disabled = true
			UIThemeHelper.apply_fake_3d_style(card, Color(0.1, 0.1, 0.12, 0.5), Color(0.3, 0.3, 0.35, 0.4), Color(0.2, 0.2, 0.2, 0.5), Color(0.5, 0.5, 0.5, 1.0), Color(0.5, 0.5, 0.5, 1.0), 18)
			
		grid_container.add_child(card)

func _on_letter_clicked(letter_id: int) -> void:
	var popup = get_node_or_null("../LetterPopup")
	if not popup:
		popup = get_node_or_null("/root/TestLevel/HUD/LetterPopup")
	if popup and popup.has_method("show_letter"):
		popup.show_letter(letter_id)
