extends Node

# ============================================================================
# LUCIDITY EDITOR STATE MANAGEMENT
# Central hub for editor state, selection, and configuration
# ============================================================================

# ============================================================================
# MODES
# ============================================================================
var current_mode: String = "EDIT"

# ============================================================================
# SELECTION STATE
# ============================================================================
var selected_object: Node3D = null
var selected_asset: String = ""
var current_tool: String = "Select"

# ============================================================================
# PROJECT STATE
# ============================================================================
var project_name: String = "My World"
var last_autosave: float = 0.0
var unsaved_changes: bool = false

# ============================================================================
# TRANSFORM STATE (for viewport manipulation)
# ============================================================================
var is_transforming: bool = false
var transform_mode: String = "select"  # "select", "move", "rotate", "scale"

# ============================================================================
# VIEWPORT STATE
# ============================================================================
var viewport_camera: Camera3D = null
var viewport_scene_root: Node3D = null
var viewport_size: Vector2 = Vector2(800, 600)

# ============================================================================
# SIGNALS
# ============================================================================
signal object_selected(obj: Node3D)
signal object_deselected()
signal mode_changed(new_mode: String)
signal tool_changed(new_tool: String)
signal transform_changed()
signal project_saved()

# ============================================================================
# LIFECYCLE
# ============================================================================
func _ready():
	last_autosave = Time.get_ticks_msec()

# ============================================================================
# OBJECT SELECTION
# ============================================================================
func select_object(obj: Node3D) -> void:
	"""Select an object and emit selection signal."""
	if selected_object == obj:
		return
	
	if selected_object:
		object_deselected.emit()
	
	selected_object = obj
	unsaved_changes = true
	object_selected.emit(obj)

func deselect_object() -> void:
	"""Deselect current object."""
	if selected_object:
		selected_object = null
		unsaved_changes = true
		object_deselected.emit()

func get_selected_object() -> Node3D:
	"""Get currently selected object, or null."""
	return selected_object

# ============================================================================
# MODE MANAGEMENT
# ============================================================================
func set_mode(mode: String) -> void:
	"""Change editor mode (CREATE, EDIT, PLAY, HOME)."""
	if current_mode == mode:
		return
	
	current_mode = mode
	mode_changed.emit(mode)

func get_mode() -> String:
	"""Get current editor mode."""
	return current_mode

# ============================================================================
# TOOL MANAGEMENT
# ============================================================================
func set_tool(tool: String) -> void:
	"""Change current editor tool."""
	if current_tool == tool:
		return
	
	current_tool = tool
	tool_changed.emit(tool)

func get_tool() -> String:
	"""Get current editor tool."""
	return current_tool

# ============================================================================
# VIEWPORT STATE
# ============================================================================
func set_viewport_camera(camera: Camera3D) -> void:
	"""Register viewport camera."""
	viewport_camera = camera

func set_viewport_scene_root(root: Node3D) -> void:
	"""Register viewport scene root."""
	viewport_scene_root = root

func set_viewport_size(new_size: Vector2) -> void:
	"""Update viewport dimensions."""
	viewport_size = new_size

# ============================================================================
# TRANSFORM OPERATIONS
# ============================================================================
func set_transforming(transforming: bool) -> void:
	"""Set transform in-progress state."""
	is_transforming = transforming

func is_currently_transforming() -> bool:
	"""Check if transform is in progress."""
	return is_transforming

# ============================================================================
# PROJECT STATE
# ============================================================================
func mark_dirty() -> void:
	"""Mark project as having unsaved changes."""
	unsaved_changes = true

func save_project() -> void:
	"""Save current project (placeholder)."""
	unsaved_changes = false
	last_autosave = Time.get_ticks_msec()
	project_saved.emit()

# ============================================================================
# AUTOSAVE
# ============================================================================
func get_autosave_time() -> String:
	"""Get human-readable autosave time."""
	var elapsed_ms = Time.get_ticks_msec() - last_autosave
	var elapsed_s = elapsed_ms / 1000.0
	var elapsed_m = int(elapsed_s / 60.0)
	
	if elapsed_m == 0:
		return "now"
	elif elapsed_m == 1:
		return "1m ago"
	else:
		return "%dm ago" % elapsed_m
