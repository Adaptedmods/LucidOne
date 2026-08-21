extends PanelContainer

@onready var asset_grid = $AssetContent/AssetGrid
@onready var search_field = $AssetContent/SearchBar/SearchField
@onready var filter_button = $AssetContent/SearchBar/FilterButton

var assets = []

func _ready():
	_create_test_assets()
	search_field.text_changed.connect(_on_search_changed)
	filter_button.pressed.connect(_on_filter_pressed)

func _create_test_assets():
	# Create placeholder asset data
	var test_assets = [
		{"name": "SDF Cube", "type": "primitive", "color": Color(1.0, 0.8, 0.3)},
		{"name": "SDF Sphere", "type": "primitive", "color": Color(0.8, 0.8, 0.8)},
		{"name": "Carved Form", "type": "primitive", "color": Color(0.6, 0.4, 0.2)},
		{"name": "Cylinder", "type": "primitive", "color": Color(0.7, 0.7, 0.7)},
		{"name": "Cone", "type": "primitive", "color": Color(0.9, 0.6, 0.3)},
		{"name": "Plane", "type": "primitive", "color": Color(0.6, 0.6, 0.6)},
		{"name": "Capsule", "type": "primitive", "color": Color(0.8, 0.9, 0.9)},
		{"name": "Torus", "type": "primitive", "color": Color(0.5, 0.5, 0.8)},
	]
	
	assets = test_assets
	_populate_grid()

func _populate_grid():
	# Clear existing cards
	for child in asset_grid.get_children():
		child.queue_free()
	
	# Create asset cards
	for asset in assets:
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(100, 120)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.15, 0.35, 0.8)
		style.border_color = Color(0.3, 0.2, 0.5, 0.5)
		style.set_border_enabled_all(true)
		style.set_corner_radius_all(8)
		card.add_theme_stylebox_override("panel", style)
		
		var vbox = VBoxContainer.new()
		card.add_child(vbox)
		
		# Color preview
		var preview = ColorRect.new()
		preview.color = asset["color"]
		preview.custom_minimum_size = Vector2(100, 80)
		vbox.add_child(preview)
		
		# Asset name
		var label = Label.new()
		label.text = asset["name"]
		label.custom_minimum_size = Vector2(100, 40)
		label.set_anchors_preset(Control.PRESET_CENTER)
		vbox.add_child(label)
		
		asset_grid.add_child(card)

func _on_search_changed(_text: String):
	_populate_grid()

func _on_filter_pressed():
	print("Filter button pressed")
