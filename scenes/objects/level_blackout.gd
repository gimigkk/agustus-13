extends Node2D
class_name LevelBlackout

## Level Blackout object covering the world area under the well shaft.
## Features a smooth top gradient transition and fades out during intro.

@export var blackout_size: Vector2 = Vector2(1400, 5500):
	set(val):
		blackout_size = val
		_update_bounds()

@export var top_gradient_height: float = 120.0:
	set(val):
		top_gradient_height = val
		_update_bounds()

@export var start_black: bool = true
@export var fade_duration: float = 3.0

@onready var top_gradient: TextureRect = $TopGradient
@onready var solid_body: ColorRect = $SolidBody

signal fade_out_completed
signal fade_in_completed

var tween: Tween

func _ready() -> void:
	_update_bounds()
	if start_black:
		modulate.a = 1.0
		show()
	else:
		modulate.a = 0.0
		hide()

func _update_bounds() -> void:
	if top_gradient:
		top_gradient.size = Vector2(blackout_size.x, top_gradient_height)
		top_gradient.position = Vector2(-blackout_size.x / 2.0, -top_gradient_height)
	if solid_body:
		solid_body.size = blackout_size
		solid_body.position = Vector2(-blackout_size.x / 2.0, 0.0)

func blackout_instant() -> void:
	if tween:
		tween.kill()
	show()
	modulate.a = 1.0

func fade_out(duration: float = -1.0) -> void:
	var d := fade_duration if duration <= 0.0 else duration
	show()
	if tween:
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate:a", 0.0, d)
	tween.finished.connect(func():
		hide()
		fade_out_completed.emit()
	)

func fade_in(duration: float = -1.0) -> void:
	var d := fade_duration if duration <= 0.0 else duration
	show()
	if tween:
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate:a", 1.0, d)
	tween.finished.connect(func():
		fade_in_completed.emit()
	)
