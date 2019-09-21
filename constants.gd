class_name Constants

const CELL_SIZE = Vector2(256, 384)

static func cell_pos(flr, lift_index):
	return Vector2(1 + lift_index, -flr) * CELL_SIZE