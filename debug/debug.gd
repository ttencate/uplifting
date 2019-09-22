extends Node2D

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		match event.scancode:
			KEY_ESCAPE:
				get_tree().quit()
			KEY_K:
				get_tree().call_group("pawns", "_debug_expire")