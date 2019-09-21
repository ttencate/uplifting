extends Node2D

func _ready():
	var hue = randf()
	var saturation = 1
	var head_value = 0
	var body_value = 0
	while abs(head_value - body_value) < 0.2:
		head_value = rand_range(0.5, 1)
		body_value = rand_range(0.5, 1)
	$head.modulate = Color.from_hsv(hue, saturation, head_value)
	$body.modulate = Color.from_hsv(hue, saturation, body_value)