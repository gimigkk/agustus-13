extends CanvasLayer

## Modal popup displaying individual letter textures or custom message dialogs.

@onready var title_label: Label = $Control/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var letter_image: TextureRect = $Control/Panel/MarginContainer/VBoxContainer/LetterImage
@onready var fallback_label: Label = $Control/Panel/MarginContainer/VBoxContainer/FallbackLabel
@onready var close_btn: Button = $Control/Panel/MarginContainer/VBoxContainer/CloseBtn
@onready var control: Control = $Control

func _ready() -> void:
	control.hide()
	close_btn.pressed.connect(hide_popup)

## Displays the letter image or text content for a specific letter ID.
func show_letter(letter_id: int) -> void:
	title_label.text = "Letter #%d" % letter_id
	
	var data = LetterManager.get_letter_data(letter_id)
	var img_path = data.get("image", "")
	
	if img_path != "" and ResourceLoader.exists(img_path):
		letter_image.texture = load(img_path) as Texture2D
		letter_image.show()
		fallback_label.hide()
	else:
		letter_image.hide()
		fallback_label.text = data.get("text", LetterManager.get_letter_message(letter_id))
		fallback_label.show()
	
	control.show()

## Shows a custom title and text message inside the popup panel.
func display_message(title: String, message: String) -> void:
	title_label.text = title
	letter_image.hide()
	fallback_label.text = message
	fallback_label.show()
	control.show()

## Closes the active popup modal.
func hide_popup() -> void:
	control.hide()
