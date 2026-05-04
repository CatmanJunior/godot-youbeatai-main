class_name TutorialOutcomes
extends Node

## All outcome callables for the tutorial step machine.
## Set [member tutorial] before calling [method get_map].

var tutorial: Tutorial

func get_map() -> Dictionary:
	var O := TutorialStepData.TutorialOutcome
	return {
		O.NOOP:                    _outcome_noop,
		O.SHOW_INTRO:              _outcome_intro,
		O.PLACE_KICK_BEATS:        _outcome_kick_place,
		O.START_TIMER_AND_UNLOCK:  _outcome_start_timer_allowed,
		O.ON_PAUSED:               _outcome_pause_beat,
		O.ON_KICK_RING_FILLED:     _outcome_kick_ring_filled,
		O.START_SHORT_TIMER:       _start_timer.bind(2.0),
		O.BEGIN_STOMP_PHASE:       _outcome_stomp_setup,
		O.END_STOMP_PHASE:         _outcome_stomp_done,
		O.SHOW_CLAP_RING:          EventBus.track_sprites_visibility_requested.emit.bind(Tutorial.INDEX_CLAP_TRACK, true),
		O.PLACE_CLAP_BEATS:        _outcome_clap_ring_setup,
		O.START_CLAP_LISTEN_TIMER: _outcome_clap_listen,
		O.STOP_PLAYBACK:           EventBus.playing_change_requested.emit.bind(false),
		O.ON_CLAP_RING_FILLED:     _outcome_clap_ring_filled,
		O.ON_BEAT_REMOVED:         _outcome_beat_removed,
		O.START_LISTEN_AGAIN_TIMER: _outcome_listen_again,
		O.BEGIN_CLAP_COUNT:        _outcome_clap_count_setup,
		O.END_CLAP_PHASE:          _outcome_clap_done,
		O.SHOW_BASS_LAYER:         _outcome_show_bass_layer,
		O.SETUP_BASS_RECORDER:     _outcome_setup_bass_recorder,
		O.ON_BASS_RECORDING_STARTED: _outcome_on_bass_recording_started,
		O.END_FAST_TTS_AND_WAIT:   _outcome_voice_over_done,
		O.SHOW_CHAOS_TRIANGLE:     EventBus.ui_visibility_requested.emit.bind(UIVisibilityListener.UIElement.CHAOS_PAD_TRIANGLE, true),
		O.SHOW_CHAOSPAD_STAR:      _outcome_show_chaospad_star.bind(2), # start with star 1
		O.ON_CHAOSPAD_STAR_REACHED: _outcome_chaospad_star_reached,
		O.ON_CHAOSPAD_LISTENED:    _outcome_chaospad_listened,
		O.SHOW_MIX_STAR:           _outcome_show_chaospad_star.bind(0),
		O.ON_MIX_STAR_REACHED:     _reach_knob_target.bind(tutorial.chaos_pad_ui.mix_star_marker),
		O.SHOW_OUTSIDE_STAR:       _outcome_show_chaospad_star.bind(1),
		O.ON_OUTSIDE_STAR_REACHED: _reach_knob_target.bind(tutorial.chaos_pad_ui.outside_star_marker),
		O.FINISH_TUTORIAL:         _outcome_end_tutorial,
	}

# ── No-op ────────────────────────────────────────────────────────────────────────────────────────────────

func _outcome_noop() -> void:
	pass

# ── Intro ────────────────────────────────────────────────────────────────────────────────────────────────

func _outcome_intro() -> void:
	EventBus.track_sprites_visibility_requested.emit(0, true)
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.KLAPPY_CONTINUE, true)
	tutorial.play_achievement_sfx()

# ── Kick ring ────────────────────────────────────────────────────────────────────────────────────────────────

## Unlocks the preset kick-ring beat positions and shows the play-button + stomp UI.
func _outcome_kick_place() -> void:
	for beat_idx: int in Tutorial.KICK_PRESET_BEAT_INDICES:
		EventBus.beat_set_requested.emit(Tutorial.INDEX_KICK_TRACK, beat_idx, true)
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.BEAT_POINTER, true)
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.PLAY_PAUSE_BUTTON, true)
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.STOMP_UI, true)

func _outcome_start_timer_allowed() -> void:
	tutorial._timer.start(tutorial._timer.wait_time)


func _outcome_pause_beat() -> void:
	tutorial.play_achievement_sfx()
	tutorial._skip_play()

func _outcome_kick_ring_filled() -> void:
	tutorial._text_allowed = true
	tutorial.play_achievement_sfx()

# ── Shared timer helper ────────────────────────────────────────────────────────────────────────────────────────────────────

## Starts the tutorial timer with [param seconds] duration.
## Use with [method Callable.bind] to create zero-argument outcome callables.
func _start_timer(seconds: float) -> void:
	tutorial._timer.start(seconds)

# ── Stomp phase ──────────────────────────────────────────────────────────────────────────────────────────────────────────

func _outcome_stomp_setup() -> void:
	tutorial._in_stomp_phase = true
	tutorial.play_achievement_sfx()

# ── Clap ring ────────────────────────────────────────────────────────────────────────────────────────────────

## Unlocks the preset clap-ring beat positions and shows the clap UI.
func _outcome_clap_ring_setup() -> void:
	for beat_idx: int in Tutorial.CLAP_PRESET_BEAT_INDICES:
		EventBus.beat_set_requested.emit(Tutorial.INDEX_CLAP_TRACK, beat_idx, true)
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.CLAP_UI, true)
	tutorial._skip_play()

func _outcome_clap_listen() -> void:
	tutorial._timer.start(tutorial._timer.wait_time)
	tutorial.play_achievement_sfx()

func _outcome_clap_ring_filled() -> void:
	tutorial._beats_active_clap_track = tutorial._active_beats_per_ring(Tutorial.INDEX_CLAP_TRACK)
	tutorial._beats_active_kick_track = tutorial._active_beats_per_ring(Tutorial.INDEX_KICK_TRACK)
	tutorial.play_achievement_sfx()

func _outcome_beat_removed() -> void:
	tutorial.play_achievement_sfx()
	tutorial._skip_play()

func _outcome_listen_again() -> void:
	tutorial._text_allowed = true
	tutorial.play_achievement_sfx()
	tutorial._timer.start(2)

func _outcome_clap_count_setup() -> void:
	tutorial._in_clap_phase = true

# ── Shared helper: end an interaction phase (stomp or clap) ─────────────────────────────────────────────────────────────────────────────────────────────

func _end_interaction_phase(is_stomp: bool) -> void:
	if is_stomp:
		tutorial._in_stomp_phase = false
	else:
		tutorial._in_clap_phase = false
	EventBus.playing_change_requested.emit(false)
	tutorial.play_achievement_sfx()

func _outcome_stomp_done() -> void:
	_end_interaction_phase(true)

func _outcome_clap_done() -> void:
	_end_interaction_phase(false)

# ── Bass ring / recording ────────────────────────────────────────────────────────────────────────────────────────────

func _outcome_show_bass_layer() -> void:
	EventBus.synth_progress_bar_visible_requested.emit(0, true)
	EventBus.track_select_button_visibility_requested.emit(4, true)
	tutorial.play_achievement_sfx()

func _outcome_setup_bass_recorder() -> void:
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.CHAOS_PAD, true)
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.CHAOS_PAD_TRIANGLE, false)
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.MIC_RECORDER, true)
	if tutorial.chaos_pad_knob_top_position:
		EventBus.chaos_pad_knob_position_set_requested.emit(
				tutorial.chaos_pad_knob_top_position.global_position)
	tutorial.play_achievement_sfx()
	EventBus.chaos_pad_button_animation_stop_requested.emit()

func _outcome_on_bass_recording_started() -> void:
	tutorial.play_achievement_sfx()
	tutorial._increased_speed = true
	DisplayServer.tts_stop()
	EventBus.record_button_animation_stop_requested.emit()

func _outcome_voice_over_done() -> void:
	tutorial._increased_speed = false
	tutorial._timer.start(3)

# ── Chaos pad ────────────────────────────────────────────────────────────────────────────────────────────────

func _outcome_show_chaospad_star(starID:int) -> void:
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.STAR1, false)
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.STAR2, false)
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.STAR3, false)
	if starID == 0:
		EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.STAR1, true)
	elif starID == 1:
		EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.STAR2, true)
	elif starID == 2:
		EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.STAR3, true)
	

func _outcome_chaospad_star_reached() -> void:
	tutorial.play_achievement_sfx()
	tutorial._skip_play()

func _outcome_chaospad_listened() -> void:
	tutorial._text_allowed = true
	tutorial.play_achievement_sfx()
	tutorial._active = true

# ── Shared helper: show/reach a knob target Marker2D ─────────────────────────────────────────────────────────────────────────────

func _show_knob_target(marker: Node2D) -> void:
	tutorial._active = false
	marker.visible = true

func _reach_knob_target(marker: TextureRect) -> void:
	tutorial._active = true
	marker.visible = false
	tutorial.play_achievement_sfx()

# ── End tutorial ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────

func _outcome_end_tutorial() -> void:
	tutorial.tutorial_level = -1
	GameState.use_tutorial = false
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.ENTIRE_INTERFACE, true)
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.ACHIEVEMENTS_PANEL, false)
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.STAR1, false)
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.STAR2, false)
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.STAR3, false)
	tutorial.play_achievement_sfx()
	EventBus.continue_button_pressed.disconnect(tutorial._tutorial_continue)
	DisplayServer.tts_stop()
