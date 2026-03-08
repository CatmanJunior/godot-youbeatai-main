extends Node


@warning_ignore_start("unused_signal")

# ── Shared State ──
var microphone_volume: float = 0.0

# ── Playback / BPM ──
signal playback_started()
signal playback_stopped()
signal bpm_changed(new_bpm: float)
signal playing_changed(playing: bool)
signal bpm_up_requested(value: int)
signal bpm_down_requested(value: int)
signal bpm_set_requested(value: int)
signal playing_change_requested(playing: bool)
signal play_pause_toggled()

# ── Beat Clock ──
signal beat_triggered(beat: int)

# ── Beat State ──
signal beat_sprite_clicked(ring: int, beat: int)
signal beat_state_changed(ring: int, beat: int, active: bool)
signal beat_set_requested(ring: int, beat: int, active: bool)
signal all_beats_cleared()
signal template_set(actives: Array)

# ── Beat Interaction ──
signal should_clap()
signal should_stomp()
signal clap_triggered()
signal stomp_triggered()

# ── Layers ──
signal layer_changed(layer_index: int, beat_actives: Array)
signal layer_added(layer_index: int, emoji: String)
signal layer_removed(layer_index: int)
signal layer_cleared()
signal layer_copied()
signal layer_pasted()

# ── Audio Playback ──
signal play_ring_requested(ring: int)
signal play_sfx_requested(stream: AudioStream)
signal audio_bank_loaded(bank: Resource)
signal green_synth_set(font: Resource, instrument: int)
signal purple_synth_set(font: Resource, instrument: int)

# ── Mixing ──
signal ring_selected(ring: int)
signal synth_selected(synth: int)
signal mixing_weights_changed(master_volume: float, weights: Vector3)
signal volume_changed(ring: int, volume_db: float)
signal set_ring_volume_requested(ring: int, volume: Vector3)

# ── Chaos Pad ──
signal chaos_pad_dragging(knob_position: Vector2, master_volume: float, weights: Vector3)
signal chaos_pad_released(master_volume: float, weights: Vector3)

# ── Particles ──
signal particles_requested(position: Vector2, color: Color)
signal progress_bar_particles_requested()
signal achievement_particles_requested()

# ── UI ──
signal ui_mode_changed(mode: String)
signal visibility_changed(element_name: String, visible: bool)
signal emoji_prompt_requested()
signal settings_toggled()
signal interface_visibility_changed(visible: bool)
signal buttons_disabled_changed(disabled: bool)
signal copy_requested()
signal paste_requested()
signal layer_clear_requested()

# ── Recording ──
signal recording_started()
signal recording_stopped(audio: AudioStream)
signal request_set_stream(ring: int, track: int, audio: AudioStream) #track is 0 for main, 1 for alt, 2 for recording
signal master_recording_started()
signal master_recording_stopped()
signal microphone_data_updated(volume: float, frequency: float)
signal request_mute_all(mute: bool)
signal recording_volume_threshold_changed(threshold: float)
signal recording_sample_button_toggled(toggled: bool)

# ── Saving / Loading ──
signal save_requested()
signal load_completed(data: Dictionary)

# ── Templates ──
signal template_applied(template_name: String)

# ── Voice Over ──
signal voice_over_started()
signal voice_over_stopped()

# ── Achievements ──
signal achievement_done(achievement_id: int)
signal all_achievements_unlocked()

# ── TTS ──
signal utterance_ended(utterance_id: int)

# ── Countdown ──
signal countdown_show_requested()
signal countdown_close_requested()