extends PanelContainer

# ============================================================================
# LUCIDITY TOP BAR
# Branding, mode navigation, stats, profile
# ============================================================================

@onready var branding_label = $TopBarContent/BrandingSection/VBoxContainer/BrandLabel
@onready var project_label = $TopBarContent/BrandingSection/VBoxContainer/ProjectLabel
@onready var autosave_label = $TopBarContent/BrandingSection/VBoxContainer/AutosaveLabel
@onready var stats_fps = $TopBarContent/RightControls/StatsSection/FPSValue
@onready var stats_draw = $TopBarContent/RightControls/StatsSection/DrawValue
@onready var stats_memory = $TopBarContent/RightControls/StatsSection/MemoryValue

var mode_buttons = {}

# ============================================================================
# LIFECYCLE
# ============================================================================
func _ready():
	# Cache mode buttons
	mode_buttons = {
		"CREATE": $TopBarContent/ModeNavigation/CreateButton,
		"EDIT": $TopBarContent/ModeNavigation/EditButton,
		"PLAY": $TopBarContent/ModeNavigation/PlayButton,
		"HOME": $TopBarContent/ModeNavigation/HomeButton
	}
	
	# Set branding
	branding_label.text = "LUCIDITY"
	project_label.text = EditorState.project_name
	
	# Connect signals
	EditorState.mode_changed.connect(_on_mode_changed)
	
	# Connect mode buttons
	for mode in mode_buttons:
		mode_buttons[mode].pressed.connect(_on_mode_pressed.bindv([mode]))
	
	# Set initial state
	_on_mode_changed(EditorState.get_mode())

# ============================================================================
# PROCESS UPDATE
# ============================================================================
func _process(_delta):
	# Update autosave indicator
	autosave_label.text = "Autosaved %s" % EditorState.get_autosave_time()
	
	# Update stats (real FPS, placeholder for draw calls and memory)
	stats_fps.text = str(Engine.get_frames_per_second())
	stats_draw.text = "1,234"  # Placeholder - real implementation would use RenderingServer
	stats_memory.text = "1.2 GB"  # Placeholder - real implementation would use OS.get_static_memory_usage()

# ============================================================================
# MODE HANDLING
# ============================================================================
func _on_mode_pressed(mode: String):
	"""Handle mode button press."""
	EditorState.set_mode(mode)

func _on_mode_changed(new_mode: String):
	"""Update button states when mode changes."""
	for mode in mode_buttons:
		mode_buttons[mode].set_pressed_no_signal(mode == new_mode)
