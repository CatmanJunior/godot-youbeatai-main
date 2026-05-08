extends Button
class_name TrackSelectButton



@export_category("Components")
@export var outline_rect: TextureRect
@export var glow_rect: TextureRect
@export var icon_rect: TextureRect

@export_category("Synth Only")
@export var background: TextureRect
@export var is_synth_track: bool = false
@export var scale_factor_on_select: float = 1.1
@export var scale_tween_duration: float = 0.3


@export_category("Track Info")
@export var track_index: int = 0

var track_ui_settings: TrackUISettingsBase


var color_is_changing: bool = false


signal track_button_pressed(track_index: int)

func _ready():
	self.pressed.connect(_on_press)
	EventBus.beat_triggered.connect(_on_beat)
	EventBus.playing_changed.connect(_play_state)

func init(p_track_index: int, p_track_ui_settings: TrackUISettingsBase):
	self.track_index = p_track_index
	self.track_ui_settings = p_track_ui_settings
	self.icon_rect.texture = track_ui_settings.button_icon_texture
	self.outline_rect.texture = track_ui_settings.button_outline_texture
	self.icon_rect.modulate = track_ui_settings.track_color
	self.glow_rect.self_modulate = p_track_ui_settings.track_color.lightened(.4)
	self.glow_rect.self_modulate.a = 0.5

func update_outline(progression:float) -> void:
	if is_synth_track:
		outline_rect.rotation_degrees = progression * 360.0 + 30.0

func set_button_selected(active: bool) -> void:
	if active:
		icon_rect.modulate = Color.WHITE
		outline_rect.texture = track_ui_settings.button_filled_texture
	else:
		icon_rect.modulate = track_ui_settings.track_color
		outline_rect.texture = track_ui_settings.button_outline_texture

	if is_synth_track:
		background.visible = active
		#scale up the button a bit when selected, do a pulse, but only for synth tracks, to give more visual feedback. Use tween
		var target_scale = Vector2.ONE * scale_factor_on_select if active else Vector2.ONE
		var tween = create_tween()
		#also tween it back
		tween.tween_property(self, "scale", target_scale, scale_tween_duration)
		tween.tween_property(self, "scale", Vector2.ONE, scale_tween_duration)

func _play_state(playing: bool):
	if not playing:
		glow_rect.visible = false

func _on_beat(beat: int):
	var track = SongState.get_track(SongState.current_section_index, track_index)
	glow_rect.self_modulate.a = 0.6 * track.master_volume
	if track is SampleTrackData:
		glow_rect.visible = track.get_beat_active(beat)
	elif track is SynthTrackData:
		if len(track.sequence_notes) <= beat:
			return
		var note: SequenceNote = track.sequence.get_note_at_beat(beat)
		glow_rect.visible = note.velocity > 0.03

func _on_press():
	emit_signal("track_button_pressed", track_index)
