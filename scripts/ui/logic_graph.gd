extends Control

# ============================================================================
# LUCIDITY LOGIC GRAPH EDITOR
# Node-based visual programming for game logic and behaviors
# ============================================================================

var graph_nodes = []
var graph_wires = []
var pan_offset = Vector2.ZERO
var zoom_level = 1.0
var selected_node: Control = null
var dragging_node: Control = null
var dragging_wire: bool = false
var wire_start_pos: Vector2 = Vector2.ZERO

# ============================================================================
# LIFECYCLE
# ============================================================================
func _ready():
	# Initialize graph editor
	_create_test_nodes()
	
	# Set up input handling
	mouse_filter = Control.MOUSE_FILTER_STOP

# ============================================================================
# TEST NODE CREATION
# ============================================================================
func _create_test_nodes():
	"""Create placeholder logic nodes for demonstration."""
	var node1 = _create_logic_node("On Game Start", Vector2(50, 50), Color(0.3, 0.6, 0.9))
	var node2 = _create_logic_node("Spawn Player", Vector2(250, 50), Color(0.9, 0.6, 0.3))
	var node3 = _create_logic_node("Enable Input", Vector2(450, 50), Color(0.6, 0.9, 0.3))
	
	graph_nodes = [node1, node2, node3]

# ============================================================================
# NODE CREATION
# ============================================================================
func _create_logic_node(label: String, position: Vector2, color: Color) -> Control:
	"""Create a new logic node with dragging support."""
	var node = PanelContainer.new()
	node.position = position
	node.custom_minimum_size = Vector2(150, 70)
	node.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Node style
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color.WHITE
	style.set_border_enabled_all(true)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.set_corner_radius_all(6)
	node.add_theme_stylebox_override("panel", style)
	
	# Label
	var label_node = Label.new()
	label_node.text = label
	label_node.add_theme_font_size_override("font_size", 11)
	label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(label_node)
	
	# Store node data
	node.set_meta("is_logic_node", true)
	node.set_meta("node_label", label)
	
	add_child(node)
	return node

# ============================================================================
# INPUT HANDLING
# ============================================================================
func _input(event: InputEvent):
	"""Handle mouse input for node manipulation."""
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_handle_mouse_press(event.position)
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_level = min(zoom_level + 0.1, 3.0)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_level = max(zoom_level - 0.1, 0.5)
		else:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_handle_mouse_release(event.position)
	
	elif event is InputEventMouseMotion:
		if dragging_node:
			_handle_node_drag(event.relative)
		elif event.button_mask & MOUSE_BUTTON_MIDDLE:
			pan_offset += event.relative

func _handle_mouse_press(pos: Vector2):
	"""Handle mouse press on graph."""
	# Check if clicking on a node
	for node in graph_nodes:
		var node_rect = node.get_global_rect()
		if node_rect.has_point(pos):
			_select_node(node)
			dragging_node = node
			return
	
	# Deselect if clicking empty space
	_select_node(null)

func _handle_mouse_release(pos: Vector2):
	"""Handle mouse release."""
	dragging_node = null

func _handle_node_drag(delta: Vector2):
	"""Handle dragging selected node."""
	if dragging_node:
		dragging_node.position += delta

# ============================================================================
# NODE SELECTION
# ============================================================================
func _select_node(node: Control):
	"""Select a node and update visual state."""
	# Deselect previous
	if selected_node:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.6, 0.9)
		style.border_color = Color.WHITE
		style.set_border_enabled_all(true)
		style.set_corner_radius_all(6)
		selected_node.add_theme_stylebox_override("panel", style)
	
	# Select new
	selected_node = node
	if node:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.5, 0.8, 1.0)
		style.border_color = Color(1.0, 1.0, 0.0)
		style.set_border_enabled_all(true)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.set_corner_radius_all(6)
		node.add_theme_stylebox_override("panel", style)

# ============================================================================
# NODE MANAGEMENT
# ============================================================================
func delete_selected_node():
	"""Delete currently selected node."""
	if selected_node and selected_node in graph_nodes:
		graph_nodes.erase(selected_node)
		selected_node.queue_free()
		selected_node = null

func duplicate_selected_node():
	"""Duplicate currently selected node."""
	if selected_node and selected_node in graph_nodes:
		var label = selected_node.get_meta("node_label")
		var new_pos = selected_node.position + Vector2(50, 50)
		var new_node = _create_logic_node(label, new_pos, Color(0.6, 0.6, 0.6))
		graph_nodes.append(new_node)

# ============================================================================
# WIRE MANAGEMENT
# ============================================================================
func add_wire(from_node: Control, to_node: Control):
	"""Create a wire connection between two nodes."""
	graph_wires.append({"from": from_node, "to": to_node})

func remove_wire(wire: Dictionary):
	"""Remove a wire connection."""
	graph_wires.erase(wire)

# ============================================================================
# DRAWING (Optional - for visual feedback)
# ============================================================================
func _draw():
	"""Draw wires between connected nodes."""
	for wire in graph_wires:
		var from_node = wire["from"]
		var to_node = wire["to"]
		
		if from_node and to_node:
			var from_pos = from_node.position + from_node.size / 2
			var to_pos = to_node.position + to_node.size / 2
			
			# Draw bezier curve
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			var control_offset = (to_pos.x - from_pos.x) / 2
			draw_bezier(from_pos, to_pos, 
						from_pos + Vector2(control_offset, 0),
						to_pos - Vector2(control_offset, 0),
						Color(0.7, 0.7, 1.0), 2.0)

func _process(_delta):
	"""Redraw wires each frame."""
	queue_redraw()
