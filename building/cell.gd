extends Node2D

var _floor: int
onready var _light = $light

signal clicked

func _ready():
	_light.number = _floor
	$button.connect("pressed", self, "_button_pressed")

func init(flr, lift_index):
	_floor = flr
	position = Vector2(lift_index, -flr) * Constants.CELL_SIZE

func set_light_on(on):
	_light.visible = on

func _button_pressed():
	emit_signal("clicked")