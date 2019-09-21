extends Node2D

var flr: float = 0 setget _set_flr
var index: int = 0

signal arrived

var _destination: float = 0
var _speed: float = 0
var _max_speed: float = 0.3
var _acceleration: float = 0.3
var _deceleration: float = 0.3
onready var _tween: Tween = $tween
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
	if flr == _destination or flr == self.flr:
		return
	_destination = flr

func _set_flr(f):
	flr = f
	position.y = flr * -Constants.CELL_SIZE.y

func _physics_process(delta):
	var distance = _destination - flr
	var destination_direction = sign(distance)
	var stop_time = abs(_speed) / _deceleration
	var stop_distance = 0.5 * _speed * stop_time
	var overshooting = sign(flr + stop_distance - _destination) * sign(_speed) == 1
	if overshooting:
		var direction = sign(_speed)
		_speed -= delta * sign(_speed) * _deceleration
		if sign(_speed) != direction and abs(flr - _destination) < 0.1:
			_speed = 0
			flr = _destination
			emit_signal("arrived", flr)
	else:
		_speed = clamp(_speed + delta * destination_direction * _acceleration, -_max_speed, _max_speed)
	self.flr += delta * _speed