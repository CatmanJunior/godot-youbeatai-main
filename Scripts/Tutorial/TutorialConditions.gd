class_name TutorialConditions
extends Node

## All condition callables for the tutorial step machine.
## Set [member tutorial] before calling [method get_map].

var tutorial: Tutorial

func _ready() -> void:
	EventBus.countdown_tick.connect(_on_countdown_tick)
	EventBus.countdown_close_requested.connect(_on_countdown_closed)

func get_map() -> Dictionary:
	var C := TutorialStepData.TutorialCondition
	return {
		C.IS_CLAPPING:                    _cond_clapped,
		C.TTS_FINISHED:                   _cond_tts_done,
		C.IS_PLAYING:                     _cond_playing,
		C.IS_PAUSED:                      _cond_not_playing,
		C.TIMER_AT_ZERO:                  _cond_timer_done,
		C.TIMER_IDLE:                     _cond_timer_stopped,
		C.KICK_RING_FULL:                 _cond_ring_filled.bind(Tutorial.INDEX_KICK_TRACK),
		C.KICK_COUNT_SNAPPED_AND_PLAYING: _cond_snap_ring_and_playing.bind(Tutorial.INDEX_KICK_TRACK),
		C.STOMPED_ENOUGH:                 _cond_interaction_count_reached.bind(true),
		C.CLAP_RING_FULL:                 _cond_ring_filled.bind(Tutorial.INDEX_CLAP_TRACK),
		C.BEAT_REMOVED:                   _cond_beat_removed,
		C.CLAP_COUNT_SNAPPED_AND_PLAYING: _cond_snap_ring_and_playing.bind(Tutorial.INDEX_CLAP_TRACK),
		C.CLAPPED_ENOUGH:                 _cond_interaction_count_reached.bind(false),
		C.BASS_TRACK_SELECTED:            _cond_bass_ring_selected,
		C.BASS_RECORDING_OR_TTS_DONE:     _cond_bass_ring_record_or_tts_done,
		C.BASS_RECORDING_ACTIVE:          _cond_bass_ring_recording_active,
		C.COUNTDOWN_TICK:                 _cond_countdown_tick,
		C.COUNTDOWN_CLOSED:               _cond_countdown_closed,
		C.ALWAYS:                         _cond_always,
		C.NEVER:                          _cond_never,
		C.KNOB_AT_MIX_TARGET:               _cond_knob_at_star.bind(tutorial.mix_target),
		C.KNOB_AT_OUTSIDE_TARGET:           _cond_knob_at_star.bind(tutorial.outside_target),
		C.KNOB_AT_TARGET:                   _cond_knob_at_star.bind(tutorial.target),
	}

# ── Playback ─────────────────────────────────────────────────────────────────────────────────────────────

func _cond_playing() -> bool:
	return GameState.playing

func _cond_not_playing() -> bool:
	return not GameState.playing

# ── TTS ──────────────────────────────────────────────────────────────────────────────────────────────────────

func _cond_tts_done() -> bool:
	return not DisplayServer.tts_is_speaking()

# ── Timer ────────────────────────────────────────────────────────────────────────────────────────────────────────

func _cond_timer_done() -> bool:
	return tutorial._timer != null and tutorial._timer.time_left == 0

func _cond_timer_stopped() -> bool:
	return tutorial._timer == null or tutorial._timer.is_stopped()

# ── Clap / stomp interaction ────────────────────────────────────────────────────────────────────────────────────────────

func _cond_clapped() -> bool:
	return tutorial.clapping

## True when the given interaction phase ([param is_stomp]) has reached [constant Tutorial.REQUIRED_ON_BEAT_COUNT].
func _cond_interaction_count_reached(is_stomp: bool) -> bool:
	if is_stomp:
		return tutorial.stomping \
			and tutorial.clap_stomp.stomped_on_beat_amount >= Tutorial.CLAP_STOMP_REQUIRED_ON_BEAT_COUNT
	return tutorial.clapping \
		and tutorial.clap_stomp.clapped_on_beat_amount >= Tutorial.CLAP_STOMP_REQUIRED_ON_BEAT_COUNT

# ── Ring beat counts ────────────────────────────────────────────────────────────────────────────────────────────────────

## True when [param ring] has at least as many active beats as the last snapshot for that ring.
func _cond_ring_filled(ring: int) -> bool:
	var threshold: int = tutorial._beats_active_kick_track \
		if ring == Tutorial.INDEX_KICK_TRACK else tutorial._beats_active_clap_track
	return tutorial._active_beats_per_ring(ring) >= threshold

## Snapshots the active beat count for [param ring], then returns true when playback is running.
func _cond_snap_ring_and_playing(ring: int) -> bool:
	var count: int = tutorial._active_beats_per_ring(ring)
	if ring == Tutorial.INDEX_KICK_TRACK:
		tutorial._beats_active_kick_track = count
	else:
		tutorial._beats_active_clap_track = count
	return GameState.playing

## True when either ring has fewer active beats than the last snapshot (player removed a beat).
func _cond_beat_removed() -> bool:
	return (tutorial._active_beats_per_ring(Tutorial.INDEX_KICK_TRACK) < tutorial._beats_active_kick_track
		or tutorial._active_beats_per_ring(Tutorial.INDEX_CLAP_TRACK) < tutorial._beats_active_clap_track)

# ── Bass ring / recording ────────────────────────────────────────────────────────────────────────────────────────────

func _cond_bass_ring_selected() -> bool:
	return SongState.selected_track_index == 4

## True when bass recording has started early (skipping TTS countdown), or when TTS has finished normally.
func _cond_bass_ring_record_or_tts_done() -> bool:
	return (SongState.selected_track_index == 4 and GameState.is_recording) \
		or not DisplayServer.tts_is_speaking()

func _cond_bass_ring_recording_active() -> bool:
	return SongState.selected_track_index == 4 and GameState.is_recording

# ── Countdown tick ────────────────────────────────────────────────────────────────────────────────────────────────

var _countdown_ticked: bool = false
var _countdown_closed: bool = false

func _on_countdown_tick(seconds: int) -> void:
	_countdown_ticked = true
	var text := str(seconds)
	EventBus.set_klappy_speech_bubble.emit(text, "", false)
	TTSHelper.speak(text)

## True for the one frame in which a beat-synced countdown tick was emitted.
func _cond_countdown_tick() -> bool:
	var fired := _countdown_ticked
	_countdown_ticked = false
	return fired

func _on_countdown_closed() -> void:
	_countdown_closed = true

## True for the one frame in which the countdown panel was closed.
func _cond_countdown_closed() -> bool:
	var fired := _countdown_closed
	_countdown_closed = false
	return fired

# ── Sentinels ─────────────────────────────────────────────────────────────────────────────────────────────────────

func _cond_always() -> bool:
	return true

func _cond_never() -> bool:
	return false

# ── Chaos pad knob zones ──────────────────────────────────────────────────────────────────────────────────────────────

const KNOB_ZONE_RADIUS: float = 50.0

func _cond_knob_at_star(marker : TextureRect) -> bool:
	if marker == null:
		return false
	#distance should be pivot position
	var distance :float = tutorial._last_knob_pos.distance_to(marker.position+marker.size/2)
	print ("Checking knob distance to star: " + str(distance))
	return distance < KNOB_ZONE_RADIUS
