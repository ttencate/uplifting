extends Node2D

onready var _building = $building
onready var _pawns = $building/pawns

func _ready():
	randomize()
	
	$spawn_timer.connect("timeout", self, "_spawn")

func _spawn():
	var pawn = preload("res://pawn/pawn.tscn").instance()
	var flr = randi() % _building.num_floors
	print("Spawning on floor %d" % [flr])
	pawn.position.x = rand_range(32, _building.size.x - 32)
	pawn.position.y = flr - 96
	_pawns.add_child(pawn)
	
	$spawn_timer.start(rand_range(5, 10))