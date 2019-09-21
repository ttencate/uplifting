extends Node2D

const size = Vector2(256, 384)

var _floor: int
onready var _button = $button

func _ready():
	_button.number = _floor

func init(flr, lift):
	_floor = flr
	position = Vector2(lift, -flr) * size