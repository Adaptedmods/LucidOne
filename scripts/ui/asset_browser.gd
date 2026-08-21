extends PanelContainer

# ============================================================================
# LUCIDITY ASSET BROWSER
# Visual asset library with search, filtering, and categorization
# ============================================================================

@onready var asset_grid = $AssetContent/AssetGrid
@onready var search_field = $AssetContent/SearchBar/SearchField
@onready var filter_button = $AssetContent/SearchBar/FilterButton

var assets = []
var filtered_assets = []
var selected_asset: String = ""
var current_filter: String = "All Types"

# Asset categories
var categories = [
	"All Assets",
	"Favorites",
	"Recent",
	"Primitives",
	"Materials",
	"Models",
	"UI Elements",
	"Systems"
]

# ============================================================================
# LIFECYCLE
# ============================================================================
func _ready():
	# Create test assets
	_create_test_assets()
	
	# Connect signals
	search_field.text_changed.connect(_on_search_changed)
	filter_button.pressed.connect(_on_filter_pressed)
	
	# Populate grid
	_populate_grid()

# ============================================================================
# ASSET CREATION
# ============================================================================
func _create_test_assets():
	"""Create placeholder asset data for testing."""
	var test_assets = [
		{"name": "SDF Cube", "type": "primitive", "color": Color(1.0, 0.8, 0.3), "category": "Primitives"},
		{"name": "SDF Sphere", "type": "primitive", "color": Color(0.8, 0.8, 0.8), "category": "Primitives"},
		{"name": "Cylinder", "type": "primitive", "color": Color(0.7, 0.7, 0.7), "category": "Primitives"},
		{"name": "Cone", "type": "primitive", "color": Color(0.9, 0.6, 0.3), "category": "Primitives"},
		{"name": "Capsule", "type": "primitive", "color": Color(0.8, 0.9, 0.9), "category": "Primitives"},
		{"name": "Torus", "type": "primitive", "color": Color(0.5, 0.5, 0.8), "category": "Primitives"},
		{"name": "Gold Material", "type": "material", "color": Color(1.0, 0.8, 0.2), "category": "Materials"},
		{"name": "Wood Material", "type": "material", "color": Color(0.6, 0.4, 0.2), "category": "Materials"},
	]
	
	assets = test_assets
	filtered_assets = assets.duplicate()

# ============================================================================
# GRID POPULATION
# ============================================================================
func _populate_grid():
	"""Rebuild asset grid with current filtered assets."""
	# Clear existing cards
	for child in asset_grid.get_children():
		child.queue_free()
	
	# Wait for deletion to complete
	await get_tree().process_frame
	
	# Create asset cards
	for asset in filtered_assets:
		var card = _create_asset_card(asset)
		asset_grid.add_child(card)

func _create_asset_card(asset: Dictionary) -> PanelContainer:
	"""Create a single asset card UI element."""
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(100, 120)
	
	# Card style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.15, 0.35, 0.8)
	style.border_color = Color(0.3, 0.2, 0.5, 0.5)
	style.set_border_enabled_all(true)
	style.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", style)
	
	# Card content
	var vbox = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(vbox)
	
	# Thumbnail preview
	var thumbnail = ColorRect.new()
	thumbnail.color = asset["color"]
	thumbnail.custom_minimum_size = Vector2(100, 80)
	thumbnail.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_child(thumbnail)
	
	# Asset name label
	var label = Label.new()
	label.text = asset["name"]
	label.custom_minimum_size = Vector2(100, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	vbox.add_child(label)
	
	# Store asset name in card for selection
	card.set_meta("asset_name", asset["name"])
	
	return card

# ============================================================================
# SEARCH AND FILTERING
# ============================================================================
func _on_search_changed(text: String):
	"""Filter assets by search text."""
	_apply_filters()

func _on_filter_pressed():
	"""Handle filter button press (placeholder)."""
	print("Filter pressed - implement filter menu")

func _apply_filters():
	"""Apply search and category filters to asset list."""
	var search_text = search_field.text.to_lower()
	
	# Filter by search text
	filtered_assets = []
	for asset in assets:
		if search_text == "" or asset["name"].to_lower().contains(search_text):
			filtered_assets.append(asset)
	
	# Rebuild grid
	_populate_grid()

# ============================================================================
# ASSET SELECTION
# ============================================================================
func get_selected_asset() -> String:
	"""Get currently selected asset name."""
	return selected_asset

func set_selected_asset(asset_name: String):
	"""Set selected asset and update visual state."""
	selected_asset = asset_name
	_update_selection_visuals()

func _update_selection_visuals():
	"""Update visual state of asset cards."""
	for card in asset_grid.get_children():
		if card.get_meta("asset_name") == selected_asset:
			# Highlight selected card
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.7, 0.4, 1.0, 0.9)
			style.border_color = Color(0.9, 0.5, 1.0, 1.0)
			style.set_border_enabled_all(true)
			style.set_corner_radius_all(8)
			card.add_theme_stylebox_override("panel", style)
		else:
			# Reset to default
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.2, 0.15, 0.35, 0.8)
			style.border_color = Color(0.3, 0.2, 0.5, 0.5)
			style.set_border_enabled_all(true)
			style.set_corner_radius_all(8)
			card.add_theme_stylebox_override("panel", style)
