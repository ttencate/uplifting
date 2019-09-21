extends Node2D

enum State { WAITING_FOR_LIFT, IN_LIFT, ARRIVED }

var state = State.WAITING_FOR_LIFT
var flr: int = 0
var destination: int = 0

signal button_pressed
signal arrived

var _lift = null
var _slot = null

func init(building):
	var random = randf()
	if random < 0.4:
		flr = 1 + randi() % (building.num_floors - 1)
		destination = 0
	elif random < 0.8:
		flr = 0
		destination = 1 + randi() % (building.num_floors - 1)
	else:
		flr = randi() % building.num_floors
		destination = flr
		while destination == flr:
			destination = randi() % building.num_floors
	position.x = rand_range(32, building.size.x - 32)
	position.y = building.cell_pos(flr, 0).y - 96

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

func tick(building):
	match state:
		State.WAITING_FOR_LIFT:
			for lift in building.lifts:
				if lift.flr == flr and lift.doors_open() and lift.has_room():
					print("Entering lift")
					_slot = lift.get_free_slot()
					_slot.remote_path = get_path()
					_lift = lift
					z_index = -50
					state = State.IN_LIFT
					emit_signal("button_pressed", destination, lift)
					break
		State.IN_LIFT:
			if _lift.flr == destination:
				print("Arrived at destination")
				_slot.remote_path = NodePath("")
				_slot = null
				_lift = null
				z_index = 0
				# TODO move onto floor
				state = State.ARRIVED
				emit_signal("arrived")
		State.ARRIVED:
			queue_free()