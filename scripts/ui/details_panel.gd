extends PanelContainer

# ============================================================================
# LUCIDITY DETAILS PANEL
# Context-sensitive properties and transform controls for selected objects
# ============================================================================

@onready var detail_content = $DetailContent
@onready var object_label = $DetailContent/HeaderSection/ObjectNameLabel
@onready var transform_section = $DetailContent/TransformSection
@onready var appearance_section = $DetailContent/AppearanceSection
@onready var physics_section = $DetailContent/PhysicsSection
@onready var behavior_section = $DetailContent/BehaviorSection
@onready var advanced_section = $DetailContent/AdvancedSection

# Transform field references
var position_fields = {}
var rotation_fields = {}
var scale_fields = {}

# State
var is_updating_display: bool = false

# ============================================================================
# LIFECYCLE
# ============================================================================
func _ready():
	# Connect to selection signals
	EditorState.object_selected.connect(_on_object_selected)
	EditorState.object_deselected.connect(_on_object_deselected)
	
	# Initialize transform field references
	_setup_transform_fields()
	
	# Start with no selection
	_set_empty_state()

# ============================================================================
# TRANSFORM FIELD SETUP
# ============================================================================
func _setup_transform_fields():
	"""Cache and connect transform input fields."""
	# Position fields
	position_fields = {
		"X": $DetailContent/TransformSection/PositionContainer/PosXValue,
		"Y": $DetailContent/TransformSection/PositionContainer/PosYValue,
		"Z": $DetailContent/TransformSection/PositionContainer/PosZValue
	}
	
	# Rotation fields
	rotation_fields = {
		"X": $DetailContent/TransformSection/RotationContainer/RotXValue,
		"Y": $DetailContent/TransformSection/RotationContainer/RotYValue,
		"Z": $DetailContent/TransformSection/RotationContainer/RotZValue
	}
	
	# Scale fields
	scale_fields = {
		"X": $DetailContent/TransformSection/ScaleContainer/ScaleXValue,
		"Y": $DetailContent/TransformSection/ScaleContainer/ScaleYValue,
		"Z": $DetailContent/TransformSection/ScaleContainer/ScaleZValue
	}
	
	# Connect field changes to handler
	for field in position_fields.values():
		field.text_changed.connect(_on_transform_changed)
	for field in rotation_fields.values():
		field.text_changed.connect(_on_transform_changed)
	for field in scale_fields.values():
		field.text_changed.connect(_on_transform_changed)

# ============================================================================
# SELECTION HANDLING
# ============================================================================
func _on_object_selected(obj: Node3D):
	"""Populate details panel when object is selected."""
	object_label.text = obj.name
	_update_transform_display(obj)
	_enable_sections(true)

func _on_object_deselected():
	"""Clear details panel when object is deselected."""
	_set_empty_state()
	_enable_sections(false)

func _set_empty_state():
	"""Set panel to empty/no-selection state."""
	object_label.text = "No Selection"

func _enable_sections(enabled: bool):
	"""Show/hide collapsible sections based on selection state."""
	transform_section.visible = enabled
	appearance_section.visible = enabled
	physics_section.visible = enabled
	behavior_section.visible = enabled
	advanced_section.visible = enabled

# ============================================================================
# DISPLAY UPDATES
# ============================================================================
func _update_transform_display(obj: Node3D):
	"""Populate transform fields with object's current values."""
	is_updating_display = true
	
	# Position
	position_fields["X"].text = "%.2f" % obj.position.x
	position_fields["Y"].text = "%.2f" % obj.position.y
	position_fields["Z"].text = "%.2f" % obj.position.z
	
	# Rotation (convert to degrees and format with °)
	var rot_deg = obj.rotation_degrees
	rotation_fields["X"].text = "%.1f°" % rot_deg.x
	rotation_fields["Y"].text = "%.1f°" % rot_deg.y
	rotation_fields["Z"].text = "%.1f°" % rot_deg.z
	
	# Scale
	scale_fields["X"].text = "%.2f" % obj.scale.x
	scale_fields["Y"].text = "%.2f" % obj.scale.y
	scale_fields["Z"].text = "%.2f" % obj.scale.z
	
	is_updating_display = false

# ============================================================================
# TRANSFORM MODIFICATION
# ============================================================================
func _on_transform_changed(_new_text: String):
	"""Handle transform field input changes."""
	# Avoid circular updates
	if is_updating_display:
		return
	
	var obj = EditorState.get_selected_object()
	if not obj:
		return
	
	# Update position
	_parse_and_apply_position(obj)
	
	# Update rotation
	_parse_and_apply_rotation(obj)
	
	# Update scale
	_parse_and_apply_scale(obj)
	
	# Emit transform changed signal
	EditorState.transform_changed.emit()
	EditorState.mark_dirty()

func _parse_and_apply_position(obj: Node3D):
	"""Parse position fields and apply to object."""
	obj.position.x = _parse_float_field(position_fields["X"].text, 0.0)
	obj.position.y = _parse_float_field(position_fields["Y"].text, 0.0)
	obj.position.z = _parse_float_field(position_fields["Z"].text, 0.0)

func _parse_and_apply_rotation(obj: Node3D):
	"""Parse rotation fields and apply to object."""
	var rot = Vector3.ZERO
	# Strip degree symbol for parsing
	rot.x = _parse_float_field(position_fields["X"].text.trim_suffix("°"), 0.0)
	rot.y = _parse_float_field(rotation_fields["Y"].text.trim_suffix("°"), 0.0)
	rot.z = _parse_float_field(rotation_fields["Z"].text.trim_suffix("°"), 0.0)
	obj.rotation_degrees = rot

func _parse_and_apply_scale(obj: Node3D):
	"""Parse scale fields and apply to object."""
	obj.scale.x = _parse_float_field(scale_fields["X"].text, 1.0)
	obj.scale.y = _parse_float_field(scale_fields["Y"].text, 1.0)
	obj.scale.z = _parse_float_field(scale_fields["Z"].text, 1.0)

# ============================================================================
# UTILITY
# ============================================================================
func _parse_float_field(text: String, default: float) -> float:
	"""Safely parse float from text field."""
	if text == "" or text == null:
		return default
	
	# Handle degree symbols
	text = text.trim_suffix("°")
	
	var value = text.to_float()
	return value if value != 0.0 or text == "0" else default
