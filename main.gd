extends Node2D

const LEVELS = {
	0: {'num_floors': 2, 'num_lifts': 1, 'spawn_interval': 4.0, 'patience': 30},
	1: {'num_floors': 2, 'num_lifts': 2, 'spawn_interval': 3.0, 'patience': 45},
	5: {'num_floors': 3, 'num_lifts': 2},
	20: {'num_floors': 4, 'num_lifts': 2, 'patience': 60},
	30: {'num_floors': 4, 'num_lifts': 2, 'spawn_interval': 2.5},
	40: {'num_floors': 4, 'num_lifts': 3},
	50: {'num_floors': 4, 'num_lifts': 3, 'spawn_interval': 2.0},
	60: {'num_floors': 5, 'num_lifts': 3},
	70: {'num_floors': 5, 'num_lifts': 3, 'spawn_interval': 1.5},
	80: {'num_floors': 6, 'num_lifts': 3},
	90: {'num_floors': 7, 'num_lifts': 4},
	100: {'num_floors': 7, 'num_lifts': 4, 'spawn_interval': 1.0},
	110: {'num_floors': 8, 'num_lifts': 4},
	120: {'num_floors': 8, 'num_lifts': 5, 'spawn_interval': 0.8},
}

var _spawn_interval: float = 0
var _patience: float = 0
var _transported: int = 0
var _time: float = 0
var _game_over: bool = false

onready var _building = $building
onready var _pawns = $building/pawns
onready var _overlay = $overlay
onready var _hud = find_node("hud")

func _ready():
	randomize()
	
	_switch_level(LEVELS[0], false)
	
	$spawn_timer.connect("timeout", self, "_spawn")
	_building.connect("cell_clicked", self, "_cell_clicked")
	
	_update_lights()
	_rescale()
	_spawn()
	
	get_tree().paused = false

func _spawn():
	var pawn = preload("res://pawn/pawn.tscn").instance()
	pawn.init(_building, _patience)
	pawn.connect("arrived", self, "_pawn_arrived")
	pawn.connect("expired", self, "_pawn_expired")
	_pawns.add_child(pawn)
	
	$spawn_timer.start(_spawn_interval)

func _physics_process(delta):
	for pawn in _pawns.get_children():
		pawn.tick(delta, _building)
	_update_lights()
	
	_time += delta
	_hud.time = _time

func _update_lights():
	for lift_index in _building.num_lifts:
		var lift = _building.lifts[lift_index]
		for flr in _building.num_floors:
			var on = false
			for pawn in lift.get_pawns():
				if pawn.destination == flr:
					on = true
					break
			_building.set_light_on(flr, lift_index, on)
			_building.set_coming_on(flr, lift_index, lift._destination == flr and lift.flr != flr)

func _cell_clicked(flr, lift_index):
	if _game_over:
		return
	_building.lifts[lift_index].move_to_floor(flr)

func _pawn_arrived():
	if _game_over:
		return
	_transported += 1
	_hud.transported = _transported
	if LEVELS.has(_transported):
		_switch_level(LEVELS[_transported])

func _switch_level(level, tween=true):
	var prev_size = _building.size
	if level.has('num_floors'):
		_building.num_floors = level['num_floors']
	if level.has('num_lifts'):
		_building.num_lifts = level['num_lifts']
	if level.has('spawn_interval'):
		_spawn_interval = level['spawn_interval']
	if level.has('patience'):
		_patience = level['patience']
	if tween:
		$tween.interpolate_method(self, "_set_size", prev_size, _building.size, 1.0, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		$tween.start()

func _pawn_expired():
	if _game_over:
		return
	_game_over = true
	get_tree().paused = true
	var scene = preload("res://hud/game_over.tscn").instance()
	scene.init(_transported, _time)
	scene.rect_size = get_viewport().get_visible_rect().size
	scene.connect("dismissed", self, "_game_over_dismissed")
	_overlay.add_child(scene)

func _game_over_dismissed():
	get_tree().reload_current_scene()

func _rescale():
	_set_size(_building.size)

func _set_size(size):
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_VIEWPORT, SceneTree.STRETCH_ASPECT_KEEP, size)
	_building.position = Vector2(0, size.y)
	_hud.rect_size.x = size.x