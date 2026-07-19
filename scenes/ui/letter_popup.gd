extends CanvasLayer

## Popup Modal displaying collected letter text
@onready var title_label: Label = $Control/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var message_label: Label = $Control/Panel/MarginContainer/VBoxContainer/MessageLabel
@onready var close_btn: Button = $Control/Panel/MarginContainer/VBoxContainer/CloseBtn
@onready var control: Control = $Control

func _ready() -> void:
	control.hide()
	close_btn.pressed.connect(hide_popup)
	var lm = get_node_or_null("/root/LetterManager")
	if lm:
		lm.letter_popup_requested.connect(show_popup)

func show_popup(letter_id: int, message: String) -> void:
	title_label.text = "💌 Letter #%d / 21" % letter_id
	message_label.text = message
	control.show()
	get_tree().paused = true

func hide_popup() -> void:
	control.hide()
	get_tree().paused = false
