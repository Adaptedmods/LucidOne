extends VBoxContainer

# ============================================================================
# LUCIDITY LEFT TOOL RAIL
# Primary editor tools for scene manipulation
# ============================================================================

var tools = {}
var current_tool: String = "Select"

# Tool configuration (data-driven approach)
var tool_config = [
	{"name": "Select", "icon": "◆", "tooltip": "Select objects"},
	{"name": "Move", "icon": "↔", "tooltip": "Move objects"},
	{"name": "Rotate", "icon": "⟳", "tooltip": "Rotate objects"},
	{"name": "Scale", "icon": "⊡", "tooltip": "Scale objects"},
	{"name": "Sculpt", "icon": "✎", "tooltip": "Sculpt forms"},
	{"name": "Paint", "icon": "🖌", "tooltip": "Paint surfaces"},
	{"name": "Logic", "icon": "⚙", "tooltip": "Logic editor"},
	{"name": "Behavior", "icon": "⊕", "tooltip": "Add behaviors"},
	{"name": "More", "icon": "≡", "tooltip": "Additional tools"}
]

# ============================================================================
# LIFECYCLE
# ============================================================================
func _ready():
	# Cache tool buttons
	_cache_tool_buttons()
	
	# Connect tool signals
	_connect_tool_signals()
	
	# Set initial tool
	_set_tool_selected("Select")
	
	# Connect to editor state
	EditorState.tool_changed.connect(_on_editor_tool_changed)

# ============================================================================
# TOOL BUTTON CACHING
# ============================================================================
func _cache_tool_buttons():
	"""Cache references to tool buttons from scene tree."""
	for config in tool_config:
		var tool_name = config["name"]
		var button_path = tool_name + "Tool"
		
		if has_node(button_path):
			tools[tool_name] = get_node(button_path)

# ============================================================================
# SIGNAL CONNECTION
# ============================================================================
func _connect_tool_signals():
	"""Connect all tool buttons to press handler."""
	for tool_name in tools:
		var button = tools[tool_name]
		button.pressed.connect(_on_tool_pressed.bindv([tool_name]))
		button.tooltip_text = _get_tool_tooltip(tool_name)

func _get_tool_tooltip(tool_name: String) -> String:
	"""Get tooltip for a tool."""
	for config in tool_config:
		if config["name"] == tool_name:
			return config["tooltip"]
	return ""

# ============================================================================
# TOOL SELECTION
# ============================================================================
func _on_tool_pressed(tool_name: String):
	"""Handle tool button press."""
	_set_tool_selected(tool_name)
	EditorState.set_tool(tool_name)

func _on_editor_tool_changed(tool: String):
	"""Handle tool change from editor state."""
	_set_tool_selected(tool)

func _set_tool_selected(tool_name: String):
	"""Update visual state of all tool buttons."""
	current_tool = tool_name
	
	for tool in tools:
		var button = tools[tool]
		# Visual feedback: brighten selected tool, dim others
		var selected_color = Color.WHITE
		var deselected_color = Color(0.6, 0.6, 0.6, 1.0)
		button.modulate = selected_color if tool == tool_name else deselected_color

func _get_current_tool() -> String:
	"""Get currently selected tool."""
	return current_tool
