extends CanvasLayer

## Letter Inventory modal displaying a grid of collected letters and locked slots.

@onready var control: Control = $Control
@onready var title_label: Label = $Control/Panel/MarginContainer/VBoxContainer/Header/TitleLabel
@onready var grid_container: GridContainer = $Control/Panel/MarginContainer/VBoxContainer/GridContainer
@onready var close_btn: Button = $Control/Panel/MarginContainer/VBoxContainer/CloseBtn

func _ready() -> void:
	control.hide()
	close_btn.pressed.connect(hide_inventory)

## Opens the inventory grid overlay and pauses gameplay.
func open_inventory() -> void:
	var count: int = LetterManager.collected_letter_ids.size()
	title_label.text = "Letters (%d / 21)" % count
	
	_populate_grid()
	control.show()
	get_tree().paused = true

## Closes the inventory grid overlay and unpauses gameplay.
func hide_inventory() -> void:
	control.hide()
	get_tree().paused = false

## Clears and rebuilds letter collection card buttons.
func _populate_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	
	var mail_icon = load("res://assets/objects/inventory_mail.png") as Texture2D
	for i in range(1, 22):
		var is_collected: bool = LetterManager.is_letter_collected(i)
		var card := Button.new()
		card.custom_minimum_size = Vector2(175, 95)
		card.add_theme_font_size_override("font_size", 18)
		
		if is_collected:
			card.text = "Letter #%d" % i
			if mail_icon:
				card.icon = mail_icon
				card.expand_icon = true
			card.pressed.connect(_on_letter_clicked.bind(i))
		else:
			card.text = "Locked"
			card.disabled = true
			
		grid_container.add_child(card)

## Opens full letter popup view for a selected collected letter ID.
func _on_letter_clicked(letter_id: int) -> void:
	var popup = get_node_or_null("../LetterPopup")
	if not popup and get_tree().current_scene:
		popup = get_tree().current_scene.get_node_or_null("HUD/LetterPopup")
	if popup:
		popup.show_letter(letter_id)
