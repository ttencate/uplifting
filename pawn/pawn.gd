extends Node2D

var flr: int = 0
var destination: int = 0
var patience: float = 60

signal entered_lift
signal arrived
signal expired

enum State { MOVING_INTO_VIEW, MOVING_TO_LIFT, IN_LIFT, ARRIVED, EXPIRED }

var _state = State.MOVING_INTO_VIEW
var _walk_in_speed: float = 48
var _walk_to_lift_speed: float = 96
var _walk_out_speed: float = 96
var _lifetime: float = 0
var _lift = null
var _slot = null
var _preferred_x: float = 0
var _voice_index: int

onready var _speech: AudioStreamPlayer2D = $speech

func init(building, patience):
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
	
	self.patience = patience

func _ready():
	var hue = randf()
	var full_saturation = 1.0
	var empty_saturation = 0.3
	var empty_value = rand_range(0.7, 1.0)
	var full_value = empty_value
	$feet/body.self_modulate = Color.from_hsv(hue, empty_saturation, empty_value)
	$feet/body/head.self_modulate = Color.from_hsv(hue, empty_saturation, empty_value)
	$feet/body/fill.self_modulate = Color.from_hsv(hue, full_saturation, full_value)
	$feet/body/head/fill.self_modulate = Color.from_hsv(hue, full_saturation, full_value)
	_update_hourglass()
	
	_voice_index = randi() % 2
	_speech.pitch_scale = rand_range(0.7, 1.3)
	
	$speech_timer.connect("timeout", self, "_speak")
	_speak()

func _speak():
	if _speech.playing:
		return
	var num_pawns = len(get_tree().get_nodes_in_group("pawns"))
	var type = "impatient" if _is_impatient() else "idle"
	var num_variants = {
		0: {"idle": 10, "impatient": 3},
		1: {"idle": 14, "impatient": 5},
	}[_voice_index][type]
	var path = "res://pawn/voice_%d/%s_%d.wav" % [_voice_index, type, randi() % num_variants]
	_speech.stream = load(path)
	_speech.volume_db = (-12 if _is_impatient() else -18) - 0.5 * num_pawns
	_speech.play()
	$speech_timer.start(rand_range(5, 10))

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
			_slot = destination_slot
			_slot.remote_path = get_path()
			_lift = destination_lift
			z_index = -50
			_state = State.IN_LIFT
			$button_press.pitch_scale = rand_range(0.9, 1.1)
			$button_press.play()
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
				flr = destination
				_slot.remote_path = NodePath("")
				position.y = Constants.cell_pos(flr, _lift.index).y - 96 + rand_range(-32, 32)
				z_index = 10
				_state = State.ARRIVED
				modulate = Color(1, 1, 1, 0.5)
				_slot = null
				_lift = null
				$blinker.stop()
				$fade_out_tween.interpolate_property(self, "modulate", Color.white, Color(1, 1, 1, 0), 1.0, Tween.TRANS_SINE, Tween.EASE_IN)
				$fade_out_tween.connect("tween_all_completed", self, "queue_free")
				$fade_out_tween.start()
				emit_signal("arrived")
		State.ARRIVED:
			var direction = sign(position.x - building.size.x / 2)
			if direction == 0:
				direction = 1
			position.x += delta * _walk_out_speed * direction
		State.EXPIRED:
			pass
	if position.x != orig_x:
		$animation_player.play("walk")
	else:
		$animation_player.play("stand")

func _is_impatient():
	return _lifetime > 0.7 * patience

func _process(delta):
	match _state:
		State.ARRIVED, State.EXPIRED:
			$blinker.play("steady")
		_:
			_lifetime += delta
			_update_hourglass()
			if _is_impatient():
				$blinker.play("blink")
			else:
				$blinker.play("steady")
			if _lifetime > patience:
				_state = State.EXPIRED
				emit_signal("expired")

func _update_hourglass():
	var f = 1.0 - (_lifetime / patience)
	var pad = 4
	var width = 48 + 2*pad
	var head_height = 48
	var body_height = 96
	var total_height = head_height + body_height
	var hh = clamp(f * total_height - body_height + pad, 0, head_height + 2*pad)
	var bh = clamp(f * total_height + pad, 0, body_height + 2*pad)
	var body_fill = $feet/body/fill
	var head_fill = $feet/body/head/fill
	head_fill.region_enabled = true
	body_fill.region_enabled = true
	head_fill.region_rect = Rect2(Vector2(0, head_height + pad - hh), Vector2(width, hh))
	body_fill.region_rect = Rect2(Vector2(0, body_height + pad - bh), Vector2(width, bh))
	head_fill.position.y = head_height + pad - hh
	body_fill.position.y = body_height + pad - bh

func set_remaining_time(t):
	_lifetime = patience - t
	_update_hourglass()