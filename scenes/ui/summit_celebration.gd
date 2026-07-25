extends CanvasLayer

## Summit Celebration Modal triggered when reaching the peak with all 21 letters
@onready var panel: Control = $Control
@onready var album_btn: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/AlbumBtn
@onready var menu_btn: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/MenuBtn

func _ready() -> void:
	if panel:
		panel.show()
	if album_btn:
		album_btn.pressed.connect(_on_album_pressed)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)

func _on_album_pressed() -> void:
	panel.hide()
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud and hud.letter_inventory:
		hud.letter_inventory.open_inventory()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
