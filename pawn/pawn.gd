extends Node2D

var flr: int = 0
var destination: int = 0

signal entered_lift
signal arrived

enum State { MOVING_INTO_VIEW, MOVING_TO_LIFT, IN_LIFT, ARRIVED }

var _state = State.MOVING_INTO_VIEW
var _walk_in_speed: float = 48
var _walk_to_lift_speed: float = 64
var _walk_out_speed: float = 96
var _lift = null
var _slot = null
var _preferred_x: float = 0

func init(building):
	var random = randi() % 3
	if random == 0:
		flr = 1 + randi() % (building.num_floors - 1)
		destination = 0
	elif random == 2:
		flr = 0
		destination = 1 + randi() % (building.num_floors - 1)
	else:
		flr = randi() % building.num_floors
		destination = flr
		while destination == flr:
			destination = randi() % building.num_floors
	position = Constants.cell_pos(flr, 0)
	if randi() % 2 == 0:
		position.x = -64
		_preferred_x = Constants.cell_pos(flr, rand_range(0, 1)).x
	else:
		position.x = building.size.x + 64
		_preferred_x = Constants.cell_pos(flr, rand_range(building.num_lifts - 1, building.num_lifts)).x
	position.y -= 96 + rand_range(-32, 32)
	z_index = 10

func _ready():
	var hue = randf()
	var saturation = 1
	var head_value = 0
	var body_value = 0
	while abs(head_value - body_value) < 0.2:
		head_value = rand_range(0.5, 1)
		body_value = rand_range(0.5, 1)
	$body/head.self_modulate = Color.from_hsv(hue, saturation, head_value)
	$body.self_modulate = Color.from_hsv(hue, saturation, body_value)

func _sort_slots(a, b):
	return global_position.distance_squared_to(a[0].global_position) < global_position.distance_squared_to(b[0].global_position)

func _move_to_lift(delta, building):
	var free_slots = building.get_free_slots(flr)
	free_slots.sort_custom(self, "_sort_slots")
	if len(free_slots) > 0:
		var destination_slot = free_slots[0][0]
		var destination_lift = free_slots[0][1]
		var distance = global_position.x - destination_slot.global_position.x
		if abs(distance) < 32:
			print("Entering lift")
			_slot = destination_slot
			_slot.remote_path = get_path()
			_lift = destination_lift
			z_index = -50
			_state = State.IN_LIFT
			emit_signal("entered_lift", destination, _lift)
		else:
			position.x -= delta * _walk_to_lift_speed * sign(distance)
		return true
	else:
		return false

func tick(delta, building):
	var orig_x = position.x
	match _state:
		State.MOVING_INTO_VIEW:
			var distance = position.x - _preferred_x
			if abs(distance) <= 32:
				_state = State.MOVING_TO_LIFT
			if not _move_to_lift(delta, building):
				position.x -= delta * _walk_in_speed * sign(distance)
		State.MOVING_TO_LIFT:
			_move_to_lift(delta, building)
		State.IN_LIFT:
			if _lift.flr == destination:
				print("Arrived at destination")
				flr = destination
				_slot.remote_path = NodePath("")
				position.y = Constants.cell_pos(flr, _lift.index).y - 96 + rand_range(-32, 32)
				z_index = 10
				_state = State.ARRIVED
				if position.x < building.size.x / 2:
					_preferred_x = -64
				else:
					_preferred_x = building.size.x + 64
				modulate = Color(1, 1, 1, 0.5)
				_slot = null
				_lift = null
				emit_signal("arrived")
		State.ARRIVED:
			var distance = position.x - _preferred_x
			position.x -= delta * _walk_out_speed * sign(distance)
			if not $visibility_notifier.is_on_screen():
				queue_free()
	if position.x != orig_x:
		$animation_player.play("walk")
	else:
		$animation_player.play("stand")