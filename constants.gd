class_name Constants

const CELL_SIZE = Vector2(256, 384)

static func cell_pos(flr, lift_index):
	return Vector2(1 + lift_index, -flr) * CELL_SIZE

static func format_time(t):
	var minutes = floor(t / 60)
	t = fmod(t, 60)
	var seconds = floor(t)
	t = fmod(t, 1)
	var centiseconds = floor(t * 10)
	return "%d:%02d.%01d" % [minutes, seconds, centiseconds]