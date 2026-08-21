extends Control

@onready var viewport = $MainContainer/CenterContent/CenterSplit/ViewportContainer/ViewportContent/Viewport
@onready var viewport_rect = $MainContainer/CenterContent/CenterSplit/ViewportContainer/ViewportContent/ViewportRect

var camera_3d: Camera3D
var scene_root: Node3D

func _ready():
	# Initialize 3D scene
	_setup_3d_scene()
	
	# Connect to viewport updates
	viewport.size_changed.connect(_on_viewport_resized)
	
	# Initialize viewport texture
	viewport_rect.texture = viewport.get_texture()

func _setup_3d_scene():
	# Create scene root
	scene_root = Node3D.new()
	viewport.add_child(scene_root)
	
	# Create camera
	camera_3d = Camera3D.new()
	camera_3d.position = Vector3(5, 5, 5)
	camera_3d.look_at(Vector3.ZERO, Vector3.UP)
	scene_root.add_child(camera_3d)
	viewport.get_camera_3d = func(): return camera_3d
	
	# Create simple light
	var light = DirectionalLight3D.new()
	light.position = Vector3(5, 10, 5)
	light.rotation_degrees = Vector3(-45, 45, 0)
	scene_root.add_child(light)
	
	# Create ground plane
	var ground = MeshInstance3D.new()
	ground.mesh = PlaneMesh.new()
	ground.mesh.size = Vector2(20, 20)
	ground.position.y = -1
	ground.name = "Ground"
	scene_root.add_child(ground)
	
	# Create test cube
	var cube = MeshInstance3D.new()
	cube.mesh = BoxMesh.new()
	cube.position = Vector3(0, 0.5, 0)
	cube.name = "Golden SDF Cube"
	scene_root.add_child(cube)
	
	# Create test sphere
	var sphere = MeshInstance3D.new()
	sphere.mesh = SphereMesh.new()
	sphere.position = Vector3(2, 0.5, 0)
	sphere.name = "Test Sphere"
	scene_root.add_child(sphere)
	
	# Create test cylinder
	var cylinder = MeshInstance3D.new()
	cylinder.mesh = CylinderMesh.new()
	cylinder.position = Vector3(-2, 0.5, 0)
	cylinder.name = "Test Cylinder"
	scene_root.add_child(cylinder)

func _on_viewport_resized():
	pass

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_viewport_click(event.position)

func _handle_viewport_click(click_pos: Vector2):
	# Convert screen position to viewport-relative position
	var viewport_rect_node = $MainContainer/CenterContent/CenterSplit/ViewportContainer/ViewportContent/ViewportRect
	var viewport_area = viewport_rect_node.get_global_rect()
	
	if viewport_area.has_point(click_pos):
		var local_pos = click_pos - viewport_area.position
		var normalized_pos = local_pos / viewport_area.size
		
		# Perform raycast in 3D scene
		var camera = viewport.get_camera_3d()
		if camera:
			var ray_from = camera.project_ray_origin(normalized_pos * viewport.size)
			var ray_normal = camera.project_ray_normal(normalized_pos * viewport.size)
			
			_raycast_scene(ray_from, ray_normal)

func _raycast_scene(from: Vector3, normal: Vector3):
	# Simple raycast for object selection
	var space_state = scene_root.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, from + normal * 1000)
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.get("collider")
		if collider and collider is Node3D:
			EditorState.select_object(collider)
	else:
		EditorState.deselect_object()
