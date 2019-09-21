extends Node2D

export var number: int = 0 setget _set_number

func _set_number(n):
	number = n
	$label.text = str(number)