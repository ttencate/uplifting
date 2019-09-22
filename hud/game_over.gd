extends MarginContainer

signal dismissed

var _can_dismiss: bool = false

func init(transported, time):
	find_node("transported_label").text = str(transported) + " people"
	find_node("time_label").text = Constants.format_time(time) + " seconds"
	
	var best_transported = 0
	var best_time = 0
	var best_file = File.new()
	if best_file.open("user://best.json", File.READ) == OK:
		var json = parse_json(best_file.get_line())
		best_transported = _json_get(json, "best_transported", TYPE_INT, 0.0)
		best_time = _json_get(json, "best_time", TYPE_REAL, 0)
		best_file.close()
	var new_best = transported > best_transported or (transported == best_transported and time > best_time)
	find_node("best").text = "%s best: %d people in %s seconds." % [
		"Previous" if new_best else "Personal",
		best_transported,
		Constants.format_time(best_time)
	]
	
	if new_best:
		if best_file.open("user://best.json", File.WRITE) == OK:
			best_file.store_line(to_json({"best_transported": transported, "best_time": time}))
			best_file.close()
	
	$click_timer.connect("timeout", self, "_click_timer_timeout")

func _json_get(json, key, type, default):
	if typeof(json) == TYPE_DICTIONARY:
		var value = json.get(key, default)
		if typeof(value) == type:
			return value
	return default

func _click_timer_timeout():
	_can_dismiss = true

func _gui_input(event):
	if _can_dismiss and event is InputEventScreenTouch and event.pressed:
		accept_event()
		emit_signal("dismissed")