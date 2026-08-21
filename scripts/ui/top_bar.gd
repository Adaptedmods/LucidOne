extends HBoxContainer

@onready var branding_label = $BrandingSection/VBoxContainer/BrandLabel
@onready var project_label = $BrandingSection/VBoxContainer/ProjectLabel
@onready var autosave_label = $BrandingSection/VBoxContainer/AutosaveLabel
@onready var stats_fps = $StatsSection/FPSValue
@onready var stats_draw = $StatsSection/DrawValue
@onready var stats_memory = $StatsSection/MemoryValue
@onready var mode_buttons = {
	"CREATE": $ModeNavigation/CreateButton,
	"EDIT": $ModeNavigation/EditButton,
	"PLAY": $ModeNavigation/PlayButton,
	"HOME": $ModeNavigation/HomeButton
}

func _ready():
	# Set branding
	branding_label.text = "LUCIDITY"
	project_label.text = EditorState.project_name
	
	# Connect signals
	EditorState.mode_changed.connect(_on_mode_changed)
	
	# Connect mode buttons
	for mode in mode_buttons:
		mode_buttons[mode].pressed.connect(_on_mode_pressed.bindv([mode]))

func _process(_delta):
	# Update autosave indicator
	autosave_label.text = "Autosaved %s" % EditorState.get_autosave_time()
	
	# Update stats
	stats_fps.text = str(Engine.get_frames_per_second())
	stats_draw.text = "1,234"  # Placeholder
	stats_memory.text = "1.2 GB"  # Placeholder

func _on_mode_pressed(mode: String):
	EditorState.set_mode(mode)

func _on_mode_changed(new_mode: String):
	# Update button states
	for mode in mode_buttons:
		mode_buttons[mode].set_pressed_no_signal(mode == new_mode)
