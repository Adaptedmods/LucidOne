extends Control

# ============================================================================
# LUCIDITY MAIN EDITOR CONTROLLER
# Manages overall editor layout, 3D viewport, and input handling
# ============================================================================

@onready var viewport = $MainContainer/CenterContent/CenterSplit/ViewportContainer/ViewportContent/Viewport
@onready var viewport_rect = $MainContainer/CenterContent/CenterSplit/ViewportContainer/ViewportContent/ViewportRect
@onready var main_container = $MainContainer
@onready var center_split = $MainContainer/CenterContent/CenterSplit
@onready var bottom_split = $MainContainer/BottomContent

var camera_3d: Camera3D
var scene_root: Node3D
var selected_object_visual: Node3D = null

# ============================================================================
# LIFECYCLE
# ============================================================================
func _ready():
	# Initialize 3D scene
	_setup_3d_scene()
	
	# Connect to viewport updates
	viewport.size_changed.connect(_on_viewport_resized)
	
	# Initialize viewport texture
	viewport_rect.texture = viewport.get_texture()
	
	# Register with editor state
	EditorState.set_viewport_camera(camera_3d)
	EditorState.set_viewport_scene_root(scene_root)
	
	# Connect editor state signals
	EditorState.object_selected.connect(_on_object_selected)
	EditorState.object_deselected.connect(_on_object_deselected)
	
	# Ensure responsive layout
	_ensure_responsive_layout()

# ============================================================================
# 3D SCENE SETUP
# ============================================================================
func _setup_3d_scene():
	"""Initialize 3D viewport with basic lighting and test geometry."""
	# Create scene root
	scene_root = Node3D.new()
	scene_root.name = "SceneRoot"
	viewport.add_child(scene_root)
	
	# Create camera
	camera_3d = Camera3D.new()
	camera_3d.position = Vector3(5, 5, 5)
	camera_3d.look_at(Vector3.ZERO, Vector3.UP)
	camera_3d.name = "EditorCamera"
	scene_root.add_child(camera_3d)
	viewport.get_camera_3d = func(): return camera_3d
	
	# Create directional light
	var light = DirectionalLight3D.new()
	light.position = Vector3(5, 10, 5)
	light.rotation_degrees = Vector3(-45, 45, 0)
	light.name = "DirectionalLight"
	scene_root.add_child(light)
	
	# Create ground plane
	var ground = MeshInstance3D.new()
	ground.mesh = PlaneMesh.new()
	ground.mesh.size = Vector2(20, 20)
	ground.position.y = -1
	ground.name = "Ground"
	
	# Add material to ground
	var ground_material = StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.3, 0.3, 0.35)
	ground.set_surface_override_material(0, ground_material)
	
	# Add collision shape for raycast
	var ground_shape = CollisionShape3D.new()
	ground_shape.shape = PlaneShape3D.new()
	ground.add_child(ground_shape)
	
	scene_root.add_child(ground)
	
	# Create test cube
	var cube = MeshInstance3D.new()
	cube.mesh = BoxMesh.new()
	cube.position = Vector3(0, 0.5, 0)
	cube.name = "Golden SDF Cube"
	
	# Add material
	var cube_material = StandardMaterial3D.new()
	cube_material.albedo_color = Color(1.0, 0.8, 0.3)
	cube.set_surface_override_material(0, cube_material)
	
	# Add collision shape
	var cube_shape = CollisionShape3D.new()
	cube_shape.shape = BoxShape3D.new()
	cube.add_child(cube_shape)
	
	scene_root.add_child(cube)
	
	# Create test sphere
	var sphere = MeshInstance3D.new()
	sphere.mesh = SphereMesh.new()
	sphere.position = Vector3(2, 0.5, 0)
	sphere.name = "Test Sphere"
	
	var sphere_material = StandardMaterial3D.new()
	sphere_material.albedo_color = Color(0.8, 0.8, 0.8)
	sphere.set_surface_override_material(0, sphere_material)
	
	var sphere_shape = CollisionShape3D.new()
	sphere_shape.shape = SphereShape3D.new()
	sphere.add_child(sphere_shape)
	
	scene_root.add_child(sphere)
	
	# Create test cylinder
	var cylinder = MeshInstance3D.new()
	cylinder.mesh = CylinderMesh.new()
	cylinder.position = Vector3(-2, 0.5, 0)
	cylinder.name = "Test Cylinder"
	
	var cylinder_material = StandardMaterial3D.new()
	cylinder_material.albedo_color = Color(0.6, 0.4, 0.2)
	cylinder.set_surface_override_material(0, cylinder_material)
	
	var cylinder_shape = CollisionShape3D.new()
	cylinder_shape.shape = CylinderShape3D.new()
	cylinder.add_child(cylinder_shape)
	
	scene_root.add_child(cylinder)

# ============================================================================
# RESPONSIVE LAYOUT
# ============================================================================
func _ensure_responsive_layout():
	"""Ensure UI responds correctly to window resize."""
	# Set minimum sizes for panels
	center_split.set_split_offset(0)
	
	# Connect to viewport size changes
	get_tree().root.size_changed.connect(_on_window_resized)

func _on_window_resized():
	"""Handle window resize events."""
	pass

# ============================================================================
# VIEWPORT INTERACTION
# ============================================================================
func _on_viewport_resized():
	"""Handle viewport size changes."""
	EditorState.set_viewport_size(viewport.size)

func _input(event: InputEvent):
	"""Handle input events (selection, transform, etc)."""
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_viewport_click(event.position)

func _handle_viewport_click(click_pos: Vector2):
	"""Convert screen click to viewport raycast."""
	var viewport_rect_node = $MainContainer/CenterContent/CenterSplit/ViewportContainer/ViewportContent/ViewportRect
	var viewport_area = viewport_rect_node.get_global_rect()
	
	# Check if click is within viewport
	if not viewport_area.has_point(click_pos):
		return
	
	var local_pos = click_pos - viewport_area.position
	var normalized_pos = local_pos / viewport_area.size
	
	# Clamp to valid range
	normalized_pos = normalized_pos.clamp(Vector2.ZERO, Vector2.ONE)
	
	# Perform raycast
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
	
	if result:
		var collider = result.get("collider")
		if collider and collider is CollisionShape3D:
			# Get the parent of the collision shape (the actual object)
			var obj = collider.get_parent()
			if obj and obj is Node3D and obj != scene_root:
				EditorState.select_object(obj)
		elif collider and collider is Node3D:
			EditorState.select_object(collider)
	else:
		EditorState.deselect_object()

# ============================================================================
# SELECTION VISUALIZATION
# ============================================================================
func _on_object_selected(obj: Node3D):
	"""Highlight selected object in viewport."""
	_clear_selection_visual()
	selected_object_visual = obj
	
	# Visual feedback: change color slightly or add outline
	if obj and obj.has_meta("original_material"):
		pass  # Could restore or modify material

func _on_object_deselected():
	"""Clear selection visualization."""
	_clear_selection_visual()

func _clear_selection_visual():
	"""Remove visual selection feedback."""
	if selected_object_visual:
		selected_object_visual = null
