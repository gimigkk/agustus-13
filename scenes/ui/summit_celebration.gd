extends CanvasLayer

const UIThemeHelper = preload("res://scenes/ui/ui_theme_helper.gd")

## Summit Celebration Modal triggered when reaching the peak with all 21 letters
@onready var panel: Control = $Control
@onready var album_btn: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/AlbumBtn
@onready var menu_btn: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/MenuBtn

func _ready() -> void:
	if panel:
		panel.show()
	if album_btn:
		UIThemeHelper.apply_fake_3d_style(album_btn, Color(0.15, 0.18, 0.28, 0.95), Color(1.0, 0.8, 0.3, 1.0), Color(1.0, 0.9, 0.4, 1.0), Color(0.1, 0.1, 0.1, 1.0), Color(0.68, 1.0, 0.18, 1.0), 24)
		album_btn.pressed.connect(_on_album_pressed)
	if menu_btn:
		UIThemeHelper.apply_fake_3d_style(menu_btn, Color(0.12, 0.14, 0.2, 0.95), Color(0.9, 0.95, 1.0, 0.9), Color(1.0, 1.0, 1.0, 1.0), Color(0.1, 0.1, 0.1, 1.0), Color(0.68, 1.0, 0.18, 1.0), 24)
		menu_btn.pressed.connect(_on_menu_pressed)

func _on_album_pressed() -> void:
	panel.hide()
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud and hud.letter_inventory:
		hud.letter_inventory.open_inventory()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
