extends MarginContainer

export var transported: int setget _set_transported
export var time: float setget _set_time

onready var _transported_label = find_node("transported")
onready var _time_label = find_node("time")

func _set_transported(t: int):
	_transported_label.text = str(t)

func _set_time(t: float):
	_time_label.text = Constants.format_time(t)