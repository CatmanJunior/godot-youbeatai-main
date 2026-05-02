class_name TutorialConditions
extends Node

## All condition callables for the tutorial step machine.
## Set [member tutorial] before calling [method get_map].

var tutorial: Tutorial

func get_map() -> Dictionary:
	var C := TutorialStepData.TutorialCondition
	return {
		C.IS_CLAPPING:                    _cond_clapped,
		C.TTS_FINISHED:                   _cond_tts_done,
		C.TTS_DONE_AFTER_KNOB:            _cond_tts_done,  # same as TTS_FINISHED
		C.IS_PLAYING:                     _cond_playing,
		C.IS_PAUSED:                      _cond_not_playing,
		C.TIMER_AT_ZERO:                  _cond_timer_done,
		C.TIMER_IDLE:                     _cond_timer_stopped,
		C.KICK_RING_FULL:                 _cond_kick_ring_filled,
		C.KICK_COUNT_SNAPPED_AND_PLAYING: _cond_snap_kick_and_playing,
		C.STOMPED_ENOUGH:                 _cond_stomped_enough,
		C.CLAP_RING_FULL:                 _cond_clap_ring_filled,
		C.BEAT_REMOVED:                   _cond_beat_removed,
		C.CLAP_COUNT_SNAPPED_AND_PLAYING: _cond_snap_clap_and_playing,
		C.CLAPPED_ENOUGH:                 _cond_clapped_enough,
		C.BASS_TRACK_SELECTED:            _cond_bass_ring_selected,
		C.BASS_RECORDING_OR_TTS_DONE:     _cond_bass_ring_record_or_tts_done,
		C.BASS_RECORDING_ACTIVE:          _cond_bass_ring_recording_active,
		C.ALWAYS:                         _cond_always,
		C.NEVER:                          _cond_never,
	}

# ── Playback ─────────────────────────────────────────────────────────────────

func _cond_playing() -> bool:
	return GameState.playing

func _cond_not_playing() -> bool:
	return not GameState.playing

# ── TTS ──────────────────────────────────────────────────────────────────────

func _cond_tts_done() -> bool:
	return not DisplayServer.tts_is_speaking()

# ── Timer ────────────────────────────────────────────────────────────────────

func _cond_timer_done() -> bool:
	return tutorial._timer != null and tutorial._timer.time_left == 0

func _cond_timer_stopped() -> bool:
	return tutorial._timer == null or tutorial._timer.is_stopped()

# ── Clap / stomp interaction ─────────────────────────────────────────────────

func _cond_clapped() -> bool:
	return tutorial.clap_stomp.is_clapping

func _cond_stomped_enough() -> bool:
	return tutorial.clap_stomp.is_stamping \
		and tutorial.clap_stomp.stomped_on_beat_amount >= Tutorial.REQUIRED_ON_BEAT_COUNT

func _cond_clapped_enough() -> bool:
	return tutorial.clap_stomp.is_clapping \
		and tutorial.clap_stomp.clapped_on_beat_amount >= Tutorial.REQUIRED_ON_BEAT_COUNT

# ── Ring beat counts ──────────────────────────────────────────────────────────

## Shared helper: returns true when [param ring] has at least [param min_count] active beats.
func _ring_has_beats(ring: int, min_count: int) -> bool:
	return tutorial._active_beats_per_ring(ring) >= min_count

func _cond_kick_ring_filled() -> bool:
	return _ring_has_beats(Tutorial.INDEX_RED_RING, tutorial._beats_active_red_ring)

func _cond_clap_ring_filled() -> bool:
	return _ring_has_beats(Tutorial.INDEX_ORANGE_RING, tutorial._beats_active_orange_ring)

## Snapshots the kick ring beat count, then checks if playback is running.
func _cond_snap_kick_and_playing() -> bool:
	tutorial._beats_active_red_ring = tutorial._active_beats_per_ring(Tutorial.INDEX_RED_RING)
	return GameState.playing

## Snapshots the clap ring beat count, then checks if playback is running.
func _cond_snap_clap_and_playing() -> bool:
	tutorial._beats_active_orange_ring = tutorial._active_beats_per_ring(Tutorial.INDEX_ORANGE_RING)
	return GameState.playing

## True when either ring has fewer active beats than the last snapshot (player removed a beat).
func _cond_beat_removed() -> bool:
	return (tutorial._active_beats_per_ring(Tutorial.INDEX_RED_RING) < tutorial._beats_active_red_ring
		or tutorial._active_beats_per_ring(Tutorial.INDEX_ORANGE_RING) < tutorial._beats_active_orange_ring)

# ── Bass ring / recording ─────────────────────────────────────────────────────

func _cond_bass_ring_selected() -> bool:
	return SongState.selected_track_index == 5

func _cond_bass_ring_record_or_tts_done() -> bool:
	if SongState.selected_track_index == 5 and GameState.is_recording:
		tutorial.play_achievement_sfx()
		tutorial.tutorial_level += 4  # skip 4 steps; _next_line adds 1 more = 5 total
		DisplayServer.tts_stop()
		return true
	return not DisplayServer.tts_is_speaking()

func _cond_bass_ring_recording_active() -> bool:
	return SongState.selected_track_index == 5 and GameState.is_recording

# ── Sentinels ─────────────────────────────────────────────────────────────────

func _cond_always() -> bool:
	return true

func _cond_never() -> bool:
	return false
