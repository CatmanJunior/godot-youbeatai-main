extends TextureButton
class_name BeatButton

var beat_index: int = 0
var track_index: int = 0

func init(beat, track, tex_normal, tex_pressed) -> void:
	beat_index = beat
	track_index = track
	self.texture_normal = tex_normal
	self.texture_pressed = tex_pressed


func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	EventBus.beat_sprite_clicked.emit(track_index, beat_index)
