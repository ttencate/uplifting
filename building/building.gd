extends Node2D

export var num_floors: int = 3 setget _set_num_floors
export var num_lifts: int = 3 setget _set_num_lifts

var size: Vector2 setget , _get_size

var _cells: Array = []
var _lifts: Array = []

func _ready():
	_update_cells()

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
			var cell = row.pop_back()
			cell.queue_free()
		while len(row) < num_lifts:
			var cell = preload("res://building/cell.tscn").instance()
			cell.init(flr, len(row))
			add_child(cell)
			row.push_back(cell)
	while len(_lifts) > num_lifts:
		var lift = _lifts.pop_back()
		lift.queue_free()
	while len(_lifts) < num_lifts:
		var lift = preload("res://lift/lift.tscn").instance()
		lift.position = Vector2(len(_lifts), 0) * _cells[0][0].size
		add_child(lift)
		_lifts.push_back(lift)

func _set_num_floors(n: int):
	num_floors = n
	_update_cells()

func _set_num_lifts(n: int):
	num_lifts = n
	_update_cells()

func _get_size() -> Vector2:
	return Vector2(num_lifts, num_floors) * _cells[0][0].size