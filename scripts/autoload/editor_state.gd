extends Node

# Editor state management
var current_mode: String = "EDIT"
var selected_object: Node3D = null
var selected_asset: String = ""
var project_name: String = "My World"
var last_autosave: float = 0.0

signal object_selected(obj: Node3D)
signal object_deselected()
signal mode_changed(new_mode: String)

func _ready():
	last_autosave = Time.get_ticks_msec()

func select_object(obj: Node3D):
	if selected_object:
		object_deselected.emit()
	selected_object = obj
	object_selected.emit(obj)

func deselect_object():
	selected_object = null
	object_deselected.emit()

func set_mode(mode: String):
	current_mode = mode
	mode_changed.emit(mode)

func get_autosave_time() -> String:
	var elapsed_ms = Time.get_ticks_msec() - last_autosave
	var elapsed_s = elapsed_ms / 1000.0
	var elapsed_m = int(elapsed_s / 60.0)
	
	if elapsed_m == 0:
		return "now"
	elif elapsed_m == 1:
		return "1m ago"
	else:
		return "%dm ago" % elapsed_m
