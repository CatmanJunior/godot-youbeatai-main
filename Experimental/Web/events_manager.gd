extends Node

# Event/Signal manager for centralized event handling
# This centralizes all the signals that were defined in the C# Events.cs partial class

# Layer events
signal layer_switched(layer: int)
signal layer_cleared
signal layer_copied(layer: int)
signal layer_pasted(layer: int)
signal layer_removed(layer: int)
signal layer_added(layer: int)

# Beat events
signal should_clap
signal should_stomp

# Audio bank events
signal audio_bank_loaded(bank)

# Synth events
signal green_synth_set(font: Resource, instrument: int)
signal purple_synth_set(font: Resource, instrument: int)

# Achievement events
signal achievement_done(achievement_id: int)
signal all_achievements_unlocked

# TTS events
signal utterance_end(utterance_id: int)

# Recording events
signal recording_started
signal recording_stopped
signal recording_saved(path: String)

# Playback events
signal playback_started
signal playback_stopped
signal beat_triggered(beat: int)

# UI events
signal ui_element_clicked(element_name: String)
signal settings_opened
signal settings_closed
signal tutorial_started
signal tutorial_completed

# Mixing events
signal chaos_pad_mode_changed(mode: int)
signal ring_changed(ring: int)
signal synth_changed(synth: int)

# Helper functions to emit events with parameters
func emit_layer_switched(layer: int):
	layer_switched.emit(layer)

func emit_layer_cleared():
	layer_cleared.emit()

func emit_layer_copied(layer: int):
	layer_copied.emit(layer)

func emit_layer_pasted(layer: int):
	layer_pasted.emit(layer)

func emit_layer_removed(layer: int):
	layer_removed.emit(layer)

func emit_layer_added(layer: int):
	layer_added.emit(layer)

func emit_should_clap():
	should_clap.emit()

func emit_should_stomp():
	should_stomp.emit()

func emit_audio_bank_loaded(bank):
	audio_bank_loaded.emit(bank)

func emit_green_synth_set(font: Resource, instrument: int):
	green_synth_set.emit(font, instrument)

func emit_purple_synth_set(font: Resource, instrument: int):
	purple_synth_set.emit(font, instrument)

func emit_achievement_done(achievement_id: int):
	achievement_done.emit(achievement_id)

func emit_all_achievements_unlocked():
	all_achievements_unlocked.emit()

func emit_utterance_end(utterance_id: int):
	utterance_end.emit(utterance_id)

func emit_recording_started():
	recording_started.emit()

func emit_recording_stopped():
	recording_stopped.emit()

func emit_recording_saved(path: String):
	recording_saved.emit(path)

func emit_playback_started():
	playback_started.emit()

func emit_playback_stopped():
	playback_stopped.emit()

func emit_beat_triggered(beat: int):
	beat_triggered.emit(beat)

func emit_chaos_pad_mode_changed(mode: int):
	chaos_pad_mode_changed.emit(mode)

func emit_ring_changed(ring: int):
	ring_changed.emit(ring)

func emit_synth_changed(synth: int):
	synth_changed.emit(synth)
