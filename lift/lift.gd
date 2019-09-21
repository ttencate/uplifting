extends Node2D

var flr: int = 0 setget _set_flr
var index: int = 0

signal arrived

onready var _slots: Array = [$slot1, $slot2, $slot3, $slot4]

func init(index):
	self.index = index
	self.position.x = index * Constants.CELL_SIZE.x

func doors_open():
	return flr == floor(flr)

func has_room():
	return get_free_slot() != null

func get_free_slot():
	var shuffled_slots = _slots.duplicate()
	shuffled_slots.shuffle()
	for slot in shuffled_slots:
		if not slot.remote_path:
			return slot
	return null

func get_pawns():
	var pawns = []
	for slot in _slots:
		if slot.remote_path:
			pawns.push_back(slot.get_node(slot.remote_path))
	return pawns

func move_to_floor(flr):
	self.flr = flr

func _set_flr(f):
	flr = f
	position.y = flr * -Constants.CELL_SIZE.y
	if doors_open(): # TODO
		emit_signal("arrived", flr)