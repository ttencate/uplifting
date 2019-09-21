extends Node2D

onready var _building = $building
onready var _pawns = $building/pawns

func _ready():
	# randomize()
	
	$spawn_timer.connect("timeout", self, "_spawn")
	_building.connect("cell_clicked", self, "_cell_clicked")

func _spawn():
	var pawn = preload("res://pawn/pawn.tscn").instance()
	pawn.init(_building)
	pawn.connect("button_pressed", self, "_pawn_button_pressed")
	_pawns.add_child(pawn)
	
	$spawn_timer.start(rand_range(2, 4))

func _physics_process(_delta):
	for pawn in _pawns.get_children():
		pawn.tick(_building)
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
	_building.lifts[lift_index].move_to_floor(flr)