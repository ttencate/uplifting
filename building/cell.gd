extends Node2D

var _floor: int
onready var _light = $light
onready var _coming = $coming

signal clicked

func _ready():
	_light.number = _floor
	$button.connect("pressed", self, "_button_pressed")

func init(flr, lift_index):
	_floor = flr
	position = Constants.cell_pos(flr, lift_index)

func set_light_on(on):
	if on == _light.visible:
		return
	if on:
		$light_animation.play("show")
	else:
		$light_animation.play("hide")

func set_coming_on(on):
	_coming.visible = on

func _button_pressed():
	emit_signal("clicked")