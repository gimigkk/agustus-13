extends CanvasLayer

## Summit victory celebration screen offering options to view album or exit to main menu.

@onready var panel: Control = $Control
@onready var album_btn: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/AlbumBtn
@onready var menu_btn: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/MenuBtn

func _ready() -> void:
	panel.show()
	album_btn.pressed.connect(_on_album_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)

## Opens the letter inventory album from the celebration dialog.
func _on_album_pressed() -> void:
	panel.hide()
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud and "letter_inventory" in hud and hud.letter_inventory:
		hud.letter_inventory.open_inventory()

## Returns player to main menu screen.
func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
