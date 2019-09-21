extends Node2D

export var num_floors: int = 3 setget _set_num_floors
export var num_lifts: int = 3 setget _set_num_lifts

var size: Vector2 setget , _get_size
var lifts: Array = []

signal cell_clicked
signal lift_arrived

var _cells: Array = []

func _ready():
	_update_cells()

func cell_pos(flr, lift):
	return Vector2(lift, -flr) * Constants.CELL_SIZE

func set_light_on(flr, lift_index, on):
	var cell = _cells[flr][lift_index]
	cell.set_light_on(on)

func _update_cells():
	while len(_cells) > num_floors:
		var row = _cells.pop_back()
		for cell in row:
			cell.queue_free()
	while len(_cells) < num_floors:
		_cells.push_back([])
	for flr in len(_cells):
		var row = _cells[flr]
		while len(row) > num_lifts:
			row.pop_back().queue_free()
		while len(row) < num_lifts:
			var lift_index = len(row)
			var cell = preload("res://building/cell.tscn").instance()
			cell.init(flr, lift_index)
			cell.connect("clicked", self, "_cell_clicked", [flr, lift_index])
			add_child(cell)
			row.push_back(cell)
	
	while len(lifts) > num_lifts:
		lifts.pop_back().queue_free()
	while len(lifts) < num_lifts:
		var lift_index = len(lifts)
		var lift = preload("res://lift/lift.tscn").instance()
		lift.init(lift_index)
		lift.connect("arrived", self, "_lift_arrived", [lift_index])
		add_child(lift)
		lifts.push_back(lift)

func _set_num_floors(n: int):
	num_floors = n
	_update_cells()

func _set_num_lifts(n: int):
	num_lifts = n
	_update_cells()

func _get_size() -> Vector2:
	return Vector2(num_lifts, num_floors) * Constants.CELL_SIZE

func _cell_clicked(flr, lift_index):
	emit_signal("cell_clicked", flr, lift_index)

func _lift_arrived(lift_index, flr):
	emit_signal("lift_arrived", lift_index, flr)