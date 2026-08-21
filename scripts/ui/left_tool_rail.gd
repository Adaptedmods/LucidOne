extends VBoxContainer

var tools = {
	"Select": $SelectTool,
	"Move": $MoveTool,
	"Rotate": $RotateTool,
	"Scale": $ScaleTool,
	"Sculpt": $SculptTool,
	"Paint": $PaintTool,
	"Logic": $LogicTool,
	"Behavior": $BehaviorTool,
	"More": $MoreTool
}

var current_tool: String = "Select"

func _ready():
	# Connect all tool buttons
	for tool_name in tools:
		var button = tools[tool_name]
		button.pressed.connect(_on_tool_pressed.bindv([tool_name]))
	
	# Set initial tool as selected
	_set_tool_selected("Select")

func _on_tool_pressed(tool_name: String):
	_set_tool_selected(tool_name)
	current_tool = tool_name
	print("Tool selected: ", tool_name)

func _set_tool_selected(tool_name: String):
	for tool in tools:
		var button = tools[tool]
		# Update visual state (button appearance)
		button.modulate = Color.WHITE if tool == tool_name else Color(0.7, 0.7, 0.7, 1.0)
