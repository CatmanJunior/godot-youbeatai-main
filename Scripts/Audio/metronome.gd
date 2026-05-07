class_name Metronome
extends AudioStreamPlayer


func _ready():
    EventBus.beat_triggered.connect(on_beat)

func on_beat(_beat:int):
    if not GameState.metronome_enabled:
        return

    if _beat % (SongState.beats_per_section / 4) == 0:
        play()