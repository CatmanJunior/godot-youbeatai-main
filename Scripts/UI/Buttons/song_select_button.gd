extends TrackSelectButton
class_name SongSelectButton

@export var song_track_line_texture: TextureRect
@export var song_section_progress_bar: ProgressBar

func _ready():
	super._ready()
	EventBus.on_song_mode_changed.connect(update_ui)

func update_ui():
	set_button_selected(GameState.song_mode_active)
	
func set_button_selected(_active: bool) -> void:
	super.set_button_selected(GameState.song_mode_active)

	song_track_line_texture.visible = GameState.song_mode_active
	if song_section_progress_bar != null:
		song_section_progress_bar.visible = GameState.song_mode_active

func _on_press():
	print("pressed")
	GameState.song_mode_active = !GameState.song_mode_active
	set_button_selected(GameState.song_mode_active)
	super._on_press()
