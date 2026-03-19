extends Node
class_name ListenToLastExport

@export var player: AudioStreamPlayer
@export var play_song_button: Button
@export var play_beat_button: Button

var last_song_export: AudioStreamWAV
var last_beat_export: AudioStreamWAV

func _ready():
    player.finished.connect(reset_labels)

func reset_labels():
    play_song_button.text = "▶️"
    play_beat_button.text = "▶️"

func play_song():
    if !last_song_export:
        return

    if player.stream == last_song_export and player.playing:
        player.stop()
        reset_labels()
        return

    play_song_button.text = "⏹️"
    play_beat_button.text = "▶️"
    play_stream(last_song_export)


func play_beat():
    if !last_beat_export:
        return

    if player.stream == last_beat_export and player.playing:
        player.stop()
        reset_labels()
        return

    play_beat_button.text = "⏹️"
    play_song_button.text = "▶️"
    play_stream(last_beat_export)

func play_stream(audio: AudioStreamWAV):
    player.stop()
    player.stream = audio
    player.play()

func on_export_song(audio: AudioStreamWAV):
    last_song_export = audio

func on_export_beat(audio: AudioStreamWAV):
    last_beat_export = audio

func on_player_state_changed(value):
    if value:
        player.stop()
        reset_labels()
