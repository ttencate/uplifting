extends MarginContainer

signal dismissed

var _can_dismiss: bool = false

func _ready():
	$click_timer.connect("timeout", self, "_click_timer_timeout")

func _click_timer_timeout():
	_can_dismiss = true

func _gui_input(event):
	if _can_dismiss and event is InputEventScreenTouch and event.pressed:
		accept_event()
		emit_signal("dismissed")