extends Node2D

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		match event.scancode:
			KEY_ESCAPE:
				get_tree().quit()
			KEY_K:
				get_tree().call_group("pawns", "set_remaining_time", 0.0)
			KEY_L:
				get_tree().call_group("pawns", "set_remaining_time", 10.0)