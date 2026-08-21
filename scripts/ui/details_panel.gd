extends PanelContainer

@onready var object_label = $VBoxContainer/HeaderSection/ObjectNameLabel
@onready var transform_section = $VBoxContainer/TransformSection
@onready var appearance_section = $VBoxContainer/AppearanceSection
@onready var physics_section = $VBoxContainer/PhysicsSection
@onready var behavior_section = $VBoxContainer/BehaviorSection
@onready var advanced_section = $VBoxContainer/AdvancedSection

# Transform field references
var position_fields = {}
var rotation_fields = {}
var scale_fields = {}

func _ready():
	# Connect to selection signals
	EditorState.object_selected.connect(_on_object_selected)
	EditorState.object_deselected.connect(_on_object_deselected)
	
	# Initialize transform field references
	_setup_transform_fields()
	
	# Start with no selection
	_set_empty_state()

func _setup_transform_fields():
	# Position fields
	position_fields = {
		"X": $VBoxContainer/TransformSection/PositionContainer/PosXValue,
		"Y": $VBoxContainer/TransformSection/PositionContainer/PosYValue,
		"Z": $VBoxContainer/TransformSection/PositionContainer/PosZValue
	}
	
	# Rotation fields
	rotation_fields = {
		"X": $VBoxContainer/TransformSection/RotationContainer/RotXValue,
		"Y": $VBoxContainer/TransformSection/RotationContainer/RotYValue,
		"Z": $VBoxContainer/TransformSection/RotationContainer/RotZValue
	}
	
	# Scale fields
	scale_fields = {
		"X": $VBoxContainer/TransformSection/ScaleContainer/ScaleXValue,
		"Y": $VBoxContainer/TransformSection/ScaleContainer/ScaleYValue,
		"Z": $VBoxContainer/TransformSection/ScaleContainer/ScaleZValue
	}
	
	# Connect field changes
	for field in position_fields.values():
		field.text_changed.connect(_on_transform_changed)
	for field in rotation_fields.values():
		field.text_changed.connect(_on_transform_changed)
	for field in scale_fields.values():
		field.text_changed.connect(_on_transform_changed)

func _on_object_selected(obj: Node3D):
	object_label.text = obj.name
	_update_transform_display(obj)
	_enable_sections(true)

func _on_object_deselected():
	_set_empty_state()
	_enable_sections(false)

func _set_empty_state():
	object_label.text = "No Selection"

func _enable_sections(enabled: bool):
	transform_section.visible = enabled
	appearance_section.visible = enabled
	physics_section.visible = enabled
	behavior_section.visible = enabled
	advanced_section.visible = enabled

func _update_transform_display(obj: Node3D):
	# Update position
	position_fields["X"].text = "%.2f" % obj.position.x
	position_fields["Y"].text = "%.2f" % obj.position.y
	position_fields["Z"].text = "%.2f" % obj.position.z
	
	# Update rotation (convert to degrees)
	var rot_deg = obj.rotation_degrees
	rotation_fields["X"].text = "%.1f°" % rot_deg.x
	rotation_fields["Y"].text = "%.1f°" % rot_deg.y
	rotation_fields["Z"].text = "%.1f°" % rot_deg.z
	
	# Update scale
	scale_fields["X"].text = "%.2f" % obj.scale.x
	scale_fields["Y"].text = "%.2f" % obj.scale.y
	scale_fields["Z"].text = "%.2f" % obj.scale.z

func _on_transform_changed(_new_text: String):
	if not EditorState.selected_object:
		return
	
	var obj = EditorState.selected_object
	
	# Update position
	obj.position.x = float(position_fields["X"].text) if position_fields["X"].text != "" else 0
	obj.position.y = float(position_fields["Y"].text) if position_fields["Y"].text != "" else 0
	obj.position.z = float(position_fields["Z"].text) if position_fields["Z"].text != "" else 0
	
	# Update rotation
	var rot = Vector3.ZERO
	rot.x = float(rotation_fields["X"].text.trim_suffix("°")) if rotation_fields["X"].text != "" else 0
	rot.y = float(rotation_fields["Y"].text.trim_suffix("°")) if rotation_fields["Y"].text != "" else 0
	rot.z = float(rotation_fields["Z"].text.trim_suffix("°")) if rotation_fields["Z"].text != "" else 0
	obj.rotation_degrees = rot
	
	# Update scale
	obj.scale.x = float(scale_fields["X"].text) if scale_fields["X"].text != "" else 1
	obj.scale.y = float(scale_fields["Y"].text) if scale_fields["Y"].text != "" else 1
	obj.scale.z = float(scale_fields["Z"].text) if scale_fields["Z"].text != "" else 1
