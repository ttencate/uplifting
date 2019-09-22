extends MarginContainer

signal dismissed

func init(transported, time):
	find_node("transported_label").text = str(transported) + " people"
	find_node("time_label").text = Constants.format_time(time) + " seconds"

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		accept_event()
		emit_signal("dismissed")