extends Control

var graph_nodes = []
var graph_wires = []
var pan_offset = Vector2.ZERO
var zoom_level = 1.0

func _ready():
	# Initialize graph editor
	_create_test_nodes()

func _create_test_nodes():
	# Create placeholder logic nodes for demonstration
	var node1 = _create_logic_node("On Interact\n(Player)", Vector2(50, 50), Color(0.3, 0.6, 0.9))
	var node2 = _create_logic_node("Player", Vector2(200, 80), Color(0.9, 0.6, 0.3))
	var node3 = _create_logic_node("Has Key?", Vector2(350, 60), Color(0.6, 0.9, 0.3))
	var node4 = _create_logic_node("Unlock Door", Vector2(500, 80), Color(0.9, 0.3, 0.6))
	var node5 = _create_logic_node("Play Sound", Vector2(500, 200), Color(0.6, 0.3, 0.9))
	var node6 = _create_logic_node("Door_Open", Vector2(650, 140), Color(0.9, 0.9, 0.3))
	
	graph_nodes = [node1, node2, node3, node4, node5, node6]

func _create_logic_node(label: String, position: Vector2, color: Color) -> PanelContainer:
	var node = PanelContainer.new()
	node.position = position
	node.custom_minimum_size = Vector2(120, 60)
	node.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_border_enabled_all(true)
	style.set_corner_radius_all(6)
	node.add_theme_stylebox_override("panel", style)
	
	var label_node = Label.new()
	label_node.text = label
	label_node.add_theme_font_size_override("font_size", 10)
	label_node.set_anchors_preset(Control.PRESET_CENTER)
	node.add_child(label_node)
	
	add_child(node)
	return node

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_level = min(zoom_level + 0.1, 3.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_level = max(zoom_level - 0.1, 0.5)
	
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MIDDLE:
			pan_offset += event.relative
