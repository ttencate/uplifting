extends Node2D

var flr: int = 0
var destination: int = 0

signal entered_lift
signal arrived
signal expired

enum State { MOVING_INTO_VIEW, MOVING_TO_LIFT, IN_LIFT, ARRIVED, EXPIRED }

var _state = State.MOVING_INTO_VIEW
var _walk_in_speed: float = 48
var _walk_to_lift_speed: float = 64
var _walk_out_speed: float = 96
var _patience: float = 100
var _lifetime: float = 0
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
	var full_saturation = 1.0
	var empty_saturation = 0.5
	var empty_value = rand_range(0.7, 1.0)
	var full_value = empty_value
	$body.self_modulate = Color.from_hsv(hue, empty_saturation, empty_value)
	$body/head.self_modulate = Color.from_hsv(hue, empty_saturation, empty_value)
	$body/fill.self_modulate = Color.from_hsv(hue, full_saturation, full_value)
	$body/head/fill.self_modulate = Color.from_hsv(hue, full_saturation, full_value)
	_update_hourglass()

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
		State.EXPIRED:
			pass
	if position.x != orig_x:
		$animation_player.play("walk")
	else:
		$animation_player.play("stand")

func _process(delta):
	match _state:
		State.ARRIVED, State.EXPIRED:
			pass
		_:
			_lifetime += delta
			_update_hourglass()
			if _lifetime > _patience:
				_state = State.EXPIRED
				emit_signal("expired")

func _update_hourglass():
	var f = 1.0 - (_lifetime / _patience)
	var width = 48
	var head_height = 48
	var body_height = 96
	var total_height = head_height + body_height
	var hh = clamp(f * total_height - body_height, 0, head_height)
	var bh = clamp(f * total_height, 0, body_height)
	var body_fill = $body/fill
	var head_fill = $body/head/fill
	head_fill.region_enabled = true
	body_fill.region_enabled = true
	head_fill.region_rect = Rect2(Vector2(0, head_height - hh), Vector2(width, hh))
	body_fill.region_rect = Rect2(Vector2(0, body_height - bh), Vector2(width, bh))
	head_fill.offset.y = -hh
	body_fill.offset.y = -bh

func _debug_expire():
	_lifetime = _patience
	_update_hourglass()