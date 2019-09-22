extends Node2D

onready var _building = $building
onready var _pawns = $building/pawns

var _transported: int = 0
var _time: float = 0
var _game_over: bool = false

onready var _overlay = $overlay
onready var _hud = find_node("hud")

func _ready():
	# randomize()
	
	$spawn_timer.connect("timeout", self, "_spawn")
	_building.connect("cell_clicked", self, "_cell_clicked")
	
	_update_lights()
	
	_rescale()

func _spawn():
	var pawn = preload("res://pawn/pawn.tscn").instance()
	pawn.init(_building)
	pawn.connect("expired", self, "_pawn_expired")
	_pawns.add_child(pawn)
	
	$spawn_timer.start(rand_range(2, 4))

func _physics_process(delta):
	if _game_over:
		return
	
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

func _cell_clicked(flr, lift_index):
	if _game_over:
		return
	_building.lifts[lift_index].move_to_floor(flr)

func _pawn_arrived():
	if _game_over:
		return
	_transported += 1
	_hud.transported = _transported

func _pawn_expired():
	if _game_over:
		return
	_game_over = true
	var scene = preload("res://hud/game_over.tscn").instance()
	scene.init(_transported, _time)
	scene.rect_size = get_viewport().get_visible_rect().size
	scene.connect("dismissed", self, "_game_over_dismissed")
	_overlay.add_child(scene)

func _game_over_dismissed():
	get_tree().reload_current_scene()

func _rescale():
	var size = _building.size
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_VIEWPORT, SceneTree.STRETCH_ASPECT_KEEP, size)
	_building.position = Vector2(0, _building.size.y)
	_hud.rect_size.x = size.x