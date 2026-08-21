# PHASE 2 - SELECTION, TRANSFORM, & DETAILS PANEL ENHANCEMENT
# Complete implementation roadmap for advanced editor features

## ============================================================================
## PHASE 2 OVERVIEW
## ============================================================================

Phase 2 extends Phase 1's core editor with:
1. **Advanced Selection** - Multi-select, selection groups, selection memory
2. **Transform Tools** - Move/Rotate/Scale gizmos with viewport interaction
3. **Details Panel Enhancement** - Material editing, physics controls, behavior assignment
4. **Undo/Redo System** - Full operation history with rollback

---

## ============================================================================
## 1. ADVANCED SELECTION SYSTEM
## ============================================================================

### New File: scripts/systems/selection_system.gd

```gdscript
# scripts/systems/selection_system.gd
extends Node

class_name SelectionSystem

# ============================================================================
# MULTI-SELECTION STATE
# ============================================================================
var selected_objects: Array[Node3D] = []
var primary_selection: Node3D = null  # Last selected / active object
var selection_groups: Dictionary = {}  # Named groups of selections

signal selection_changed(objects: Array)
signal primary_selection_changed(obj: Node3D)
signal selection_group_created(group_name: String)

# ============================================================================
# SINGLE SELECTION
# ============================================================================
func select_object(obj: Node3D, add_to_selection: bool = false) -> void:
	"""Select object, optionally adding to current selection."""
	if not add_to_selection:
		_clear_selection()
	
	if obj and obj not in selected_objects:
		selected_objects.append(obj)
		primary_selection = obj
		selection_changed.emit(selected_objects)
		primary_selection_changed.emit(obj)

func deselect_object(obj: Node3D) -> void:
	"""Remove object from selection."""
	if obj in selected_objects:
		selected_objects.erase(obj)
		
		if primary_selection == obj:
			primary_selection = selected_objects[0] if selected_objects.size() > 0 else null
		
		selection_changed.emit(selected_objects)
		if primary_selection:
			primary_selection_changed.emit(primary_selection)

func clear_selection() -> void:
	"""Clear all selections."""
	_clear_selection()

func _clear_selection() -> void:
	"""Internal: clear without emitting."""
	selected_objects.clear()
	primary_selection = null
	selection_changed.emit([])

# ============================================================================
# MULTI-SELECT QUERIES
# ============================================================================
func get_selected_objects() -> Array[Node3D]:
	"""Get all selected objects."""
	return selected_objects

func get_primary_selection() -> Node3D:
	"""Get primary (active) selection."""
	return primary_selection

func is_selected(obj: Node3D) -> bool:
	"""Check if object is selected."""
	return obj in selected_objects

func get_selection_count() -> int:
	"""Get number of selected objects."""
	return selected_objects.size()

# ============================================================================
# BOX/DRAG SELECTION
# ============================================================================
func select_in_rect(rect: Rect2, viewport_camera: Camera3D, objects: Array[Node3D], add_to_selection: bool = false) -> void:
	"""Select all objects within screen-space rectangle."""
	if not add_to_selection:
		_clear_selection()
	
	for obj in objects:
		if _is_object_in_screen_rect(obj, rect, viewport_camera):
			selected_objects.append(obj)
			primary_selection = obj
	
	selection_changed.emit(selected_objects)
	if primary_selection:
		primary_selection_changed.emit(primary_selection)

func _is_object_in_screen_rect(obj: Node3D, rect: Rect2, camera: Camera3D) -> bool:
	"""Check if object center is within screen rectangle."""
	var screen_pos = camera.get_viewport().get_camera_3d().unproject_position(obj.global_position)
	return rect.has_point(screen_pos)

# ============================================================================
# SELECTION GROUPS
# ============================================================================
func save_selection_group(group_name: String) -> void:
	"""Save current selection as a named group."""
	selection_groups[group_name] = selected_objects.duplicate()
	selection_group_created.emit(group_name)

func load_selection_group(group_name: String) -> void:
	"""Load a saved selection group."""
	if group_name in selection_groups:
		selected_objects = selection_groups[group_name].duplicate()
		primary_selection = selected_objects[0] if selected_objects.size() > 0 else null
		selection_changed.emit(selected_objects)
		if primary_selection:
			primary_selection_changed.emit(primary_selection)

func delete_selection_group(group_name: String) -> void:
	"""Delete a saved selection group."""
	selection_groups.erase(group_name)

func get_selection_groups() -> Array[String]:
	"""Get list of all saved groups."""
	return selection_groups.keys()

# ============================================================================
# SELECTION FILTERING
# ============================================================================
func select_by_type(object_type: String, scene_root: Node3D) -> void:
	"""Select all objects of a given type."""
	_clear_selection()
	_collect_objects_by_type(scene_root, object_type)
	selection_changed.emit(selected_objects)

func _collect_objects_by_type(node: Node, type_name: String) -> void:
	"""Recursively collect objects of type."""
	if node is Node3D and node.get_class() == type_name:
		selected_objects.append(node)
	
	for child in node.get_children():
		_collect_objects_by_type(child, type_name)

func select_by_name_pattern(pattern: String, scene_root: Node3D) -> void:
	"""Select objects matching name pattern (regex)."""
	_clear_selection()
	var regex = RegEx.new()
	regex.compile(pattern)
	
	_collect_objects_by_pattern(scene_root, regex)
	selection_changed.emit(selected_objects)

func _collect_objects_by_pattern(node: Node, regex: RegEx) -> void:
	"""Recursively collect objects matching pattern."""
	if node is Node3D and regex.search(node.name):
		selected_objects.append(node)
	
	for child in node.get_children():
		_collect_objects_by_pattern(child, regex)
```

### Update: scripts/ui/editor_main.gd (Add Selection System)

```gdscript
# In _ready():
var selection_system: SelectionSystem

func _ready():
	# ... existing code ...
	
	# Initialize selection system
	selection_system = SelectionSystem.new()
	add_child(selection_system)
	
	# Connect selection signals
	selection_system.selection_changed.connect(_on_selection_changed)
	selection_system.primary_selection_changed.connect(_on_primary_selection_changed)

func _handle_viewport_click(click_pos: Vector2):
	"""Convert screen click to viewport raycast."""
	var viewport_rect_node = $MainContainer/CenterContent/CenterSplit/ViewportContainer/ViewportContent/ViewportRect
	var viewport_area = viewport_rect_node.get_global_rect()
	
	if not viewport_area.has_point(click_pos):
		return
	
	var local_pos = click_pos - viewport_area.position
	var normalized_pos = local_pos / viewport_area.size
	normalized_pos = normalized_pos.clamp(Vector2.ZERO, Vector2.ONE)
	
	var camera = viewport.get_camera_3d()
	if camera:
		var ray_from = camera.project_ray_origin(normalized_pos * viewport.size)
		var ray_normal = camera.project_ray_normal(normalized_pos * viewport.size)
		_raycast_scene(ray_from, ray_normal)

func _raycast_scene(from: Vector3, normal: Vector3):
	"""Perform raycast to select objects in scene."""
	var space_state = scene_root.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, from + normal * 1000)
	
	var result = space_state.intersect_ray(query)
	
	var add_to_selection = Input.is_key_pressed(KEY_CTRL)
	
	if result:
		var collider = result.get("collider")
		if collider and collider is CollisionShape3D:
			var obj = collider.get_parent()
			if obj and obj is Node3D and obj != scene_root:
				selection_system.select_object(obj, add_to_selection)
		elif collider and collider is Node3D:
			selection_system.select_object(collider, add_to_selection)
	else:
		if not add_to_selection:
			selection_system.clear_selection()

func _on_selection_changed(objects: Array):
	"""Handle multi-selection change."""
	# Update all UI panels
	pass

func _on_primary_selection_changed(obj: Node3D):
	"""Handle primary selection change."""
	EditorState.select_object(obj)
```

---

## ============================================================================
## 2. TRANSFORM TOOLS & GIZMOS
## ============================================================================

### New File: scripts/viewport/gizmo_controller.gd

```gdscript
# scripts/viewport/gizmo_controller.gd
extends Node3D

class_name GizmoController

# ============================================================================
# GIZMO STATE
# ============================================================================
enum GizmoMode { MOVE, ROTATE, SCALE, NONE }

var current_mode: GizmoMode = GizmoMode.NONE
var active_axis: String = ""  # "X", "Y", "Z", "XY", "XZ", "YZ"
var gizmo_origin: Vector3 = Vector3.ZERO
var gizmo_scale: float = 1.0

var move_gizmo: MeshInstance3D
var rotate_gizmo: MeshInstance3D
var scale_gizmo: MeshInstance3D

signal gizmo_started
signal gizmo_updated(delta: Vector3)
signal gizmo_finished

# ============================================================================
# LIFECYCLE
# ============================================================================
func _ready():
	"""Initialize gizmos."""
	_setup_move_gizmo()
	_setup_rotate_gizmo()
	_setup_scale_gizmo()
	
	# Initially hidden
	visible = false

# ============================================================================
# MOVE GIZMO
# ============================================================================
func _setup_move_gizmo():
	"""Create move gizmo (3 arrow axes)."""
	move_gizmo = MeshInstance3D.new()
	add_child(move_gizmo)
	
	# Create axis meshes
	var x_arrow = _create_arrow(Color.RED)
	var y_arrow = _create_arrow(Color.GREEN)
	var y_arrow.rotation.z = PI / 2
	var z_arrow = _create_arrow(Color.BLUE)
	var z_arrow.rotation.y = -PI / 2
	
	move_gizmo.add_child(x_arrow)
	move_gizmo.add_child(y_arrow)
	move_gizmo.add_child(z_arrow)

func _create_arrow(color: Color) -> MeshInstance3D:
	"""Create a single arrow for gizmo."""
	var arrow = MeshInstance3D.new()
	
	# Cylinder for shaft
	var shaft = MeshInstance3D.new()
	shaft.mesh = CylinderMesh.new()
	shaft.mesh.radius = 0.05
	shaft.mesh.height = 1.0
	shaft.position.y = 0.5
	var shaft_material = StandardMaterial3D.new()
	shaft_material.albedo_color = color
	shaft.set_surface_override_material(0, shaft_material)
	
	# Cone for head
	var head = MeshInstance3D.new()
	head.mesh = CylinderMesh.new()
	head.position.y = 1.0
	head.scale = Vector3(0.2, 0.3, 0.2)
	var head_material = StandardMaterial3D.new()
	head_material.albedo_color = color
	head.set_surface_override_material(0, head_material)
	
	arrow.add_child(shaft)
	arrow.add_child(head)
	return arrow

# ============================================================================
# ROTATE GIZMO
# ============================================================================
func _setup_rotate_gizmo():
	"""Create rotation gizmo (3 circular arcs)."""
	rotate_gizmo = MeshInstance3D.new()
	add_child(rotate_gizmo)
	
	# Create circular arcs for each axis
	var x_circle = _create_arc(Color.RED, Vector3.RIGHT)
	var y_circle = _create_arc(Color.GREEN, Vector3.UP)
	var z_circle = _create_arc(Color.BLUE, Vector3.FORWARD)
	
	rotate_gizmo.add_child(x_circle)
	rotate_gizmo.add_child(y_circle)
	rotate_gizmo.add_child(z_circle)

func _create_arc(color: Color, axis: Vector3) -> MeshInstance3D:
	"""Create circular arc for rotation axis."""
	var arc = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.8
	torus.outer_radius = 0.9
	arc.mesh = torus
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	arc.set_surface_override_material(0, material)
	return arc

# ============================================================================
# SCALE GIZMO
# ============================================================================
func _setup_scale_gizmo():
	"""Create scale gizmo (3 cubes on axes)."""
	scale_gizmo = MeshInstance3D.new()
	add_child(scale_gizmo)
	
	var x_cube = _create_axis_cube(Color.RED, Vector3(1, 0, 0))
	var y_cube = _create_axis_cube(Color.GREEN, Vector3(0, 1, 0))
	var z_cube = _create_axis_cube(Color.BLUE, Vector3(0, 0, 1))
	
	scale_gizmo.add_child(x_cube)
	scale_gizmo.add_child(y_cube)
	scale_gizmo.add_child(z_cube)

func _create_axis_cube(color: Color, axis: Vector3) -> MeshInstance3D:
	"""Create cube handle on axis."""
	var cube = MeshInstance3D.new()
	cube.mesh = BoxMesh.new()
	cube.mesh.size = Vector3(0.2, 0.2, 0.2)
	cube.position = axis * 1.2
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	cube.set_surface_override_material(0, material)
	return cube

# ============================================================================
# GIZMO VISIBILITY
# ============================================================================
func show_gizmo_for_object(obj: Node3D, mode: GizmoMode):
	"""Display gizmo for selected object in specified mode."""
	if obj == null:
		visible = false
		return
	
	global_position = obj.global_position
	current_mode = mode
	
	# Show appropriate gizmo
	move_gizmo.visible = (mode == GizmoMode.MOVE)
	rotate_gizmo.visible = (mode == GizmoMode.ROTATE)
	scale_gizmo.visible = (mode == GizmoMode.SCALE)
	
	visible = true

func hide_gizmo():
	"""Hide all gizmos."""
	visible = false
	current_mode = GizmoMode.NONE

# ============================================================================
# GIZMO INTERACTION
# ============================================================================
func hit_test(screen_pos: Vector2, camera: Camera3D) -> String:
	"""Check if gizmo was clicked, return axis name."""
	# Simple placeholder - real implementation would raycast against gizmo meshes
	return ""

func apply_transform(delta: Vector3):
	"""Apply transform delta based on active axis."""
	gizmo_updated.emit(delta)
```

### New File: scripts/systems/transform_system.gd

```gdscript
# scripts/systems/transform_system.gd
extends Node

class_name TransformSystem

# ============================================================================
# TRANSFORM OPERATION STATE
# ============================================================================
enum OperationType { MOVE, ROTATE, SCALE }

var current_operation: OperationType = OperationType.MOVE
var operation_target: Node3D = null
var original_transform: Transform3D
var operation_start_pos: Vector2 = Vector2.ZERO
var is_operating: bool = false
var grid_snap: bool = false
var snap_size: float = 0.5
var transform_space: String = "world"  # "world" or "local"

signal operation_started(obj: Node3D, op_type: OperationType)
signal operation_updated(obj: Node3D, transform: Transform3D)
signal operation_finished(obj: Node3D, old_transform: Transform3D, new_transform: Transform3D)

# ============================================================================
# OPERATION LIFECYCLE
# ============================================================================
func start_operation(obj: Node3D, op_type: OperationType, start_pos: Vector2):
	"""Begin a transform operation."""
	operation_target = obj
	current_operation = op_type
	original_transform = obj.transform
	operation_start_pos = start_pos
	is_operating = true
	operation_started.emit(obj, op_type)

func finish_operation():
	"""Complete current operation and emit signal."""
	if operation_target and is_operating:
		var final_transform = operation_target.transform
		operation_finished.emit(operation_target, original_transform, final_transform)
	
	operation_target = null
	is_operating = false

func cancel_operation():
	"""Cancel operation and restore original transform."""
	if operation_target:
		operation_target.transform = original_transform
	
	operation_target = null
	is_operating = false

# ============================================================================
# TRANSFORM APPLICATION
# ============================================================================
func apply_move(delta: Vector3):
	"""Apply move operation."""
	if not operation_target or current_operation != OperationType.MOVE:
		return
	
	if grid_snap:
		delta = _snap_vector(delta, snap_size)
	
	if transform_space == "local":
		operation_target.position += operation_target.transform.basis * delta
	else:
		operation_target.position += delta
	
	operation_updated.emit(operation_target, operation_target.transform)

func apply_rotate(delta: Vector3):
	"""Apply rotation operation."""
	if not operation_target or current_operation != OperationType.ROTATE:
		return
	
	if grid_snap:
		delta = _snap_vector(delta, snap_size * 5)  # Larger snap for rotation
	
	if transform_space == "local":
		operation_target.rotate_object_local(delta.normalized(), delta.length())
	else:
		operation_target.rotate_y(delta.y)
		operation_target.rotate_x(delta.x)
	
	operation_updated.emit(operation_target, operation_target.transform)

func apply_scale(delta: Vector3):
	"""Apply scale operation."""
	if not operation_target or current_operation != OperationType.SCALE:
		return
	
	var scale_delta = 1.0 + (delta.y * 0.01)  # Map mouse movement to scale
	operation_target.scale *= scale_delta
	
	operation_updated.emit(operation_target, operation_target.transform)

# ============================================================================
# UTILITY
# ============================================================================
func _snap_vector(vec: Vector3, snap_size: float) -> Vector3:
	"""Snap vector to grid."""
	return Vector3(
		snappedf(vec.x, snap_size),
		snappedf(vec.y, snap_size),
		snappedf(vec.z, snap_size)
	)

func set_grid_snap(enabled: bool, size: float = 0.5):
	"""Configure grid snapping."""
	grid_snap = enabled
	snap_size = size

func set_transform_space(space: String):
	"""Set transform space (world or local)."""
	if space in ["world", "local"]:
		transform_space = space

func get_operation_name() -> String:
	"""Get human-readable operation name."""
	match current_operation:
		OperationType.MOVE: return "Move"
		OperationType.ROTATE: return "Rotate"
		OperationType.SCALE: return "Scale"
	return "Unknown"
```

---

## ============================================================================
## 3. DETAILS PANEL ENHANCEMENT
## ============================================================================

### New File: scripts/ui/color_picker_panel.gd

```gdscript
# scripts/ui/color_picker_panel.gd
extends PanelContainer

class_name ColorPickerPanel

var current_color: Color = Color.WHITE
var target_object: Node3D = null

signal color_changed(color: Color)

@onready var color_picker = $VBoxContainer/ColorPicker

func _ready():
	color_picker.color_changed.connect(_on_color_changed)

func set_color(color: Color):
	"""Set color picker to value."""
	current_color = color
	color_picker.set_pick_color(color)

func set_target_object(obj: Node3D):
	"""Set which object to modify."""
	target_object = obj
	if obj and obj is MeshInstance3D:
		# Get current material color
		var material = obj.get_active_material(0)
		if material and material is StandardMaterial3D:
			set_color(material.albedo_color)

func _on_color_changed(color: Color):
	"""Handle color picker change."""
	current_color = color
	
	# Apply to object
	if target_object and target_object is MeshInstance3D:
		var material = target_object.get_active_material(0)
		if material == null:
			material = StandardMaterial3D.new()
			target_object.set_surface_override_material(0, material)
		
		if material is StandardMaterial3D:
			material.albedo_color = color
	
	color_changed.emit(color)

func get_color() -> Color:
	"""Get current color."""
	return current_color
```

### Update: scripts/ui/details_panel.gd (Add Material & Physics Sections)

```gdscript
# Add to details_panel.gd _ready():
func _ready():
	# ... existing code ...
	
	# Connect collapsible section toggles
	appearance_section.gui_input.connect(_on_appearance_section_toggle)
	physics_section.gui_input.connect(_on_physics_section_toggle)

# Add methods for expanded sections:
func _on_appearance_section_toggle(event: InputEvent):
	"""Toggle appearance section expansion."""
	if event is InputEventMouseButton and event.pressed:
		var is_visible = appearance_section.get_node("AppearanceContent").visible
		appearance_section.get_node("AppearanceContent").visible = !is_visible

func _populate_appearance_section(obj: Node3D):
	"""Populate appearance controls for selected object."""
	if not obj or obj is not MeshInstance3D:
		return
	
	var material = obj.get_active_material(0)
	if material and material is StandardMaterial3D:
		# Update color field
		appearance_section.get_node("ColorPreview").color = material.albedo_color
		# Update roughness slider
		appearance_section.get_node("RoughnessSlider").value = material.roughness
		# Update metallic slider
		appearance_section.get_node("MetallicSlider").value = material.metallic

func _populate_physics_section(obj: Node3D):
	"""Populate physics controls for selected object."""
	if not obj:
		return
	
	var physics_enabled = obj.is_in_group("physics")
	physics_section.get_node("PhysicsToggle").set_pressed_no_signal(physics_enabled)
	
	# If has RigidBody3D parent
	var parent = obj.get_parent()
	if parent and parent is RigidBody3D:
		physics_section.get_node("MassSlider").value = parent.mass
		physics_section.get_node("FrictionSlider").value = parent.friction
		physics_section.get_node("BounceSlider").value = parent.bounce
```

### New File: scripts/ui/physics_properties_panel.gd

```gdscript
# scripts/ui/physics_properties_panel.gd
extends VBoxContainer

class_name PhysicsPropertiesPanel

var target_object: Node3D = null
var target_body: PhysicsBody3D = null

signal physics_changed

func _ready():
	# Connect all physics control signals
	$PhysicsEnabledToggle.toggled.connect(_on_physics_enabled)
	$BodyTypeOption.item_selected.connect(_on_body_type_changed)
	$MassSlider.value_changed.connect(_on_mass_changed)
	$FrictionSlider.value_changed.connect(_on_friction_changed)
	$BounceSlider.value_changed.connect(_on_bounce_changed)
	$GravityToggle.toggled.connect(_on_gravity_changed)

func set_target_object(obj: Node3D):
	"""Set object to edit physics for."""
	target_object = obj
	_refresh_ui()

func _refresh_ui():
	"""Refresh all UI elements from object state."""
	if not target_object:
		return
	
	# Check if has physics body
	target_body = null
	var parent = target_object.get_parent()
	if parent and parent is PhysicsBody3D:
		target_body = parent
	
	$PhysicsEnabledToggle.set_pressed_no_signal(target_body != null)
	
	if target_body:
		if target_body is RigidBody3D:
			$BodyTypeOption.select(0)
			$MassSlider.value = target_body.mass
			$FrictionSlider.value = target_body.friction
			$BounceSlider.value = target_body.bounce
			$GravityToggle.set_pressed_no_signal(target_body.gravity_scale > 0)

func _on_physics_enabled(enabled: bool):
	"""Toggle physics on/off."""
	if enabled and not target_body:
		_add_physics_body()
	elif not enabled and target_body:
		_remove_physics_body()

func _add_physics_body():
	"""Add RigidBody3D wrapper to object."""
	var body = RigidBody3D.new()
	body.name = target_object.name + "_Body"
	
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = BoxShape3D.new()
	body.add_child(collision_shape)
	
	target_object.get_parent().add_child(body)
	target_object.reparent(body)
	
	target_body = body
	_refresh_ui()
	physics_changed.emit()

func _remove_physics_body():
	"""Remove physics body and move object back to parent."""
	if target_body:
		var original_parent = target_body.get_parent()
		target_object.reparent(original_parent)
		target_body.queue_free()
		target_body = null
		physics_changed.emit()

func _on_body_type_changed(index: int):
	"""Handle body type selection."""
	# Would require converting between body types
	pass

func _on_mass_changed(value: float):
	"""Handle mass slider change."""
	if target_body and target_body is RigidBody3D:
		target_body.mass = value
		physics_changed.emit()

func _on_friction_changed(value: float):
	"""Handle friction slider change."""
	if target_body and target_body is RigidBody3D:
		target_body.friction = value
		physics_changed.emit()

func _on_bounce_changed(value: float):
	"""Handle bounce/restitution slider change."""
	if target_body and target_body is RigidBody3D:
		target_body.bounce = value
		physics_changed.emit()

func _on_gravity_changed(enabled: bool):
	"""Handle gravity toggle."""
	if target_body and target_body is RigidBody3D:
		target_body.gravity_scale = 1.0 if enabled else 0.0
		physics_changed.emit()
```

---

## ============================================================================
## 4. UNDO/REDO SYSTEM
## ============================================================================

### New File: scripts/systems/undo_redo_system.gd

```gdscript
# scripts/systems/undo_redo_system.gd
extends Node

class_name UndoRedoSystem

# ============================================================================
# UNDO/REDO STACK
# ============================================================================
var undo_redo: EditorUndoRedo
var max_history_size: int = 100

signal operation_undone(description: String)
signal operation_redone(description: String)
signal history_changed

func _ready():
	"""Initialize undo/redo system."""
	undo_redo = EditorUndoRedo.new()
	add_child(undo_redo)

# ============================================================================
# TRANSFORM OPERATIONS
# ============================================================================
func record_transform_change(obj: Node3D, old_transform: Transform3D, new_transform: Transform3D, op_name: String = "Transform"):
	"""Record object transform change."""
	undo_redo.create_action(op_name)
	undo_redo.add_do_method(obj, "set_transform", new_transform)
	undo_redo.add_undo_method(obj, "set_transform", old_transform)
	undo_redo.commit_action()
	history_changed.emit()

func record_position_change(obj: Node3D, old_pos: Vector3, new_pos: Vector3, op_name: String = "Move"):
	"""Record position change."""
	undo_redo.create_action(op_name)
	undo_redo.add_do_property(obj, "position", new_pos)
	undo_redo.add_undo_property(obj, "position", old_pos)
	undo_redo.commit_action()
	history_changed.emit()

func record_rotation_change(obj: Node3D, old_rot: Vector3, new_rot: Vector3, op_name: String = "Rotate"):
	"""Record rotation change."""
	undo_redo.create_action(op_name)
	undo_redo.add_do_property(obj, "rotation", old_rot.length() != 0 and new_rot)
	undo_redo.add_undo_property(obj, "rotation", old_rot)
	undo_redo.commit_action()
	history_changed.emit()

func record_scale_change(obj: Node3D, old_scale: Vector3, new_scale: Vector3, op_name: String = "Scale"):
	"""Record scale change."""
	undo_redo.create_action(op_name)
	undo_redo.add_do_property(obj, "scale", new_scale)
	undo_redo.add_undo_property(obj, "scale", old_scale)
	undo_redo.commit_action()
	history_changed.emit()

# ============================================================================
# MATERIAL OPERATIONS
# ============================================================================
func record_color_change(obj: Node3D, old_color: Color, new_color: Color, op_name: String = "Change Color"):
	"""Record material color change."""
	undo_redo.create_action(op_name)
	undo_redo.add_do_method(self, "_set_object_color", obj, new_color)
	undo_redo.add_undo_method(self, "_set_object_color", obj, old_color)
	undo_redo.commit_action()
	history_changed.emit()

func _set_object_color(obj: Node3D, color: Color):
	"""Helper to set object color."""
	if obj is MeshInstance3D:
		var material = obj.get_active_material(0)
		if material and material is StandardMaterial3D:
			material.albedo_color = color

# ============================================================================
# OBJECT LIFECYCLE OPERATIONS
# ============================================================================
func record_object_creation(obj: Node3D, parent: Node3D, op_name: String = "Create Object"):
	"""Record object creation."""
	undo_redo.create_action(op_name)
	undo_redo.add_do_method(parent, "add_child", obj)
	undo_redo.add_undo_method(parent, "remove_child", obj)
	undo_redo.commit_action()
	history_changed.emit()

func record_object_deletion(obj: Node3D, op_name: String = "Delete Object"):
	"""Record object deletion."""
	undo_redo.create_action(op_name)
	var parent = obj.get_parent()
	undo_redo.add_do_method(parent, "remove_child", obj)
	undo_redo.add_undo_method(parent, "add_child", obj)
	undo_redo.commit_action()
	history_changed.emit()

# ============================================================================
# HISTORY MANAGEMENT
# ============================================================================
func undo():
	"""Undo last operation."""
	if undo_redo.get_version() > 0:
		undo_redo.undo()
		operation_undone.emit("Undo")

func redo():
	"""Redo last undone operation."""
	undo_redo.redo()
	operation_redone.emit("Redo")

func can_undo() -> bool:
	"""Check if undo is available."""
	return undo_redo.get_version() > 0

func can_redo() -> bool:
	"""Check if redo is available."""
	return undo_redo.get_version() < undo_redo.get_max_version()

func clear_history():
	"""Clear all undo/redo history."""
	# Note: EditorUndoRedo doesn't have clear, would need custom implementation
	history_changed.emit()
```

---

## ============================================================================
## 5. INTEGRATION ARCHITECTURE
## ============================================================================

### Update: scripts/ui/editor_main.gd (Full Phase 2 Integration)

```gdscript
extends Control

# Phase 1 references
@onready var viewport = $MainContainer/CenterContent/CenterSplit/ViewportContainer/ViewportContent/Viewport
@onready var viewport_rect = $MainContainer/CenterContent/CenterSplit/ViewportContainer/ViewportContent/ViewportRect

# Phase 2 managers
var selection_system: SelectionSystem
var transform_system: TransformSystem
var undo_redo_system: UndoRedoSystem
var gizmo_controller: GizmoController

var camera_3d: Camera3D
var scene_root: Node3D

func _ready():
	_setup_3d_scene()
	_setup_managers()
	_connect_signals()
	_ensure_responsive_layout()

func _setup_managers():
	"""Initialize Phase 2 manager systems."""
	# Selection system
	selection_system = SelectionSystem.new()
	add_child(selection_system)
	
	# Transform system
	transform_system = TransformSystem.new()
	add_child(transform_system)
	
	# Undo/redo
	undo_redo_system = UndoRedoSystem.new()
	add_child(undo_redo_system)
	
	# Gizmo controller (visual in viewport)
	gizmo_controller = GizmoController.new()
	gizmo_controller.name = "GizmoController"
	viewport.get_child(0).add_child(gizmo_controller)

func _connect_signals():
	"""Connect all system signals."""
	# Selection changes
	selection_system.selection_changed.connect(_on_selection_changed)
	selection_system.primary_selection_changed.connect(_on_primary_selection_changed)
	
	# Transform operations
	transform_system.operation_started.connect(_on_transform_started)
	transform_system.operation_updated.connect(_on_transform_updated)
	transform_system.operation_finished.connect(_on_transform_finished)
	
	# Tool changes
	EditorState.tool_changed.connect(_on_tool_changed)

func _on_selection_changed(objects: Array):
	"""Handle multi-selection update."""
	# Update UI panels for multiple selection
	# Show combined properties or "Multiple objects selected"
	pass

func _on_primary_selection_changed(obj: Node3D):
	"""Handle primary selection change."""
	EditorState.select_object(obj)
	
	# Update gizmo for current tool
	var tool = EditorState.get_tool()
	if tool == "Move":
		var mode = GizmoController.GizmoMode.MOVE
		gizmo_controller.show_gizmo_for_object(obj, mode)
	elif tool == "Rotate":
		var mode = GizmoController.GizmoMode.ROTATE
		gizmo_controller.show_gizmo_for_object(obj, mode)
	elif tool == "Scale":
		var mode = GizmoController.GizmoMode.SCALE
		gizmo_controller.show_gizmo_for_object(obj, mode)

func _on_transform_started(obj: Node3D, op_type):
	"""Record transform start for undo."""
	pass

func _on_transform_updated(obj: Node3D, transform: Transform3D):
	"""Handle ongoing transform."""
	pass

func _on_transform_finished(obj: Node3D, old_transform: Transform3D, new_transform: Transform3D):
	"""Record transform completion for undo/redo."""
	var op_name = transform_system.get_operation_name()
	undo_redo_system.record_transform_change(obj, old_transform, new_transform, op_name)

func _on_tool_changed(tool: String):
	"""Handle tool change."""
	if selection_system.get_primary_selection():
		var obj = selection_system.get_primary_selection()
		
		match tool:
			"Move":
				gizmo_controller.show_gizmo_for_object(obj, GizmoController.GizmoMode.MOVE)
			"Rotate":
				gizmo_controller.show_gizmo_for_object(obj, GizmoController.GizmoMode.ROTATE)
			"Scale":
				gizmo_controller.show_gizmo_for_object(obj, GizmoController.GizmoMode.SCALE)
			_:
				gizmo_controller.hide_gizmo()

# Keyboard shortcuts
func _input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_Z:
				if Input.is_key_pressed(KEY_CTRL):
					if Input.is_key_pressed(KEY_SHIFT):
						undo_redo_system.redo()
					else:
						undo_redo_system.undo()
			KEY_DELETE:
				# Delete selected objects
				for obj in selection_system.get_selected_objects():
					undo_redo_system.record_object_deletion(obj)
```

---

## ============================================================================
## PHASE 2 IMPLEMENTATION CHECKLIST
## ============================================================================

- [ ] Implement SelectionSystem with multi-select support
- [ ] Create GizmoController for visual transform handles
- [ ] Implement TransformSystem for move/rotate/scale operations
- [ ] Create ColorPickerPanel for material editing
- [ ] Create PhysicsPropertiesPanel with physics controls
- [ ] Implement UndoRedoSystem with action recording
- [ ] Add gizmo rendering in viewport
- [ ] Add keyboard shortcuts (Ctrl+Z, Delete, etc)
- [ ] Test multi-select with Ctrl+click
- [ ] Test transform gizmos in each mode
- [ ] Test material color picker updates
- [ ] Test physics body creation/deletion
- [ ] Test undo/redo for all operations
- [ ] Test undo/redo with multi-select
- [ ] Verify transform space toggle (world/local)
- [ ] Test grid snap functionality

---

**Phase 2 Complete When:** All systems integrated, tested, and working seamlessly with Phase 1.
