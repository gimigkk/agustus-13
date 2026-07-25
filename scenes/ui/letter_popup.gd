extends CanvasLayer

const UIThemeHelper = preload("res://scenes/ui/ui_theme_helper.gd")

## Popup Modal displaying a single letter's decorated PNG content
@onready var title_label: Label = $Control/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var letter_image: TextureRect = $Control/Panel/MarginContainer/VBoxContainer/LetterImage
@onready var fallback_label: Label = $Control/Panel/MarginContainer/VBoxContainer/FallbackLabel
@onready var close_btn: Button = $Control/Panel/MarginContainer/VBoxContainer/CloseBtn
@onready var control: Control = $Control

func _ready() -> void:
	control.hide()
	if close_btn:
		UIThemeHelper.apply_fake_3d_style(close_btn, Color(0.18, 0.15, 0.28, 0.95), Color(0.9, 0.7, 0.2, 1.0), Color(1.0, 0.85, 0.4, 1.0), Color(0.1, 0.1, 0.1, 1.0), Color(0.68, 1.0, 0.18, 1.0), 24)
		close_btn.pressed.connect(hide_popup)

## Called from LetterInventory grid when a collected letter is clicked
func show_letter(letter_id: int) -> void:
	title_label.text = "Letter #%d" % letter_id
	
	# Try to load decorated PNG from res://assets/letters/letter_XX.png
	var img_path := "res://assets/letters/letter_%02d.png" % letter_id
	if ResourceLoader.exists(img_path):
		var tex = load(img_path) as Texture2D
		letter_image.texture = tex
		letter_image.show()
		fallback_label.hide()
	else:
		# Fallback: show text from JSON if no PNG exists yet
		letter_image.hide()
		var lm = get_node_or_null("/root/LetterManager")
		var msg: String = lm.get_letter_message(letter_id) if lm else ""
		fallback_label.text = msg
		fallback_label.show()
	
	control.show()

func hide_popup() -> void:
	control.hide()
