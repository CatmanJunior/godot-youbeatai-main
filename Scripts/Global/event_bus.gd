extends Node


@warning_ignore_start("unused_signal")

signal restart_requested()

# ── Playback ──
signal playing_changed(playing: bool)
signal playing_change_requested(playing: bool)
signal play_pause_toggle_requested()

#-- BPM --
signal bpm_changed(new_bpm: float)
signal bpm_up_requested(value: int)
signal bpm_down_requested(value: int)
signal bpm_set_requested(value: int)

# ── Beat Clock ──
signal beat_triggered(beat: int)
signal beat_seek_requested(beat: int)

# ── Beat State ──
signal beat_sprite_clicked(track: int, beat: int)
signal beat_state_changed(track: int, beat: int, active: bool)
signal beat_set_requested(track: int, beat: int, active: bool)
signal template_set(actives: Array)

# ── Beat Interaction ──
signal clap_triggered()
signal stomp_triggered()

# ── Sections ──
signal add_section_requested(emoji: String)
signal section_switched(old_section_data: SectionData, section_data: SectionData)
signal section_added(new_section_index: int, emoji: String)
signal section_removed(section_index: int)
signal section_cleared()
signal copy_requested()
signal paste_requested()
signal section_clear_requested()
signal section_switch_requested(section_index: int)

# ── Audio Playback ──
signal play_sample_track_requested(track: int)
signal play_track_requested(track: int)
signal play_sfx_requested(stream: AudioStream)
signal all_players_stop_requested()

# ── Mixing ──
signal track_selected(track: int)
signal mixing_weights_changed(master_volume: float, weights: Vector3)
signal set_track_volume_requested(track: int, master_volume: float, weights: Vector3)

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

# -- Buttons --
signal track_select_button_pressed(track: int)
signal recording_sample_button_toggled(toggled: bool)

# ── Recording ──
signal start_recording_requested()
signal stop_recording_requested()
signal recording_started()
signal recording_stopped(audio: AudioStream)

# -- Set Audio Streams --
signal set_stream_requested(track: int, audio_layer: int, audio: AudioStream)
signal set_recorded_stream_requested(track_index: int, audio: AudioStream)

signal mute_all_requested(mute: bool)

# ── Saving / Loading ──
signal save_requested()
signal load_completed(data: Dictionary)
signal save_to_wav_requested()
signal save_to_mp3_requested()
signal saving_completed(path: String)

# ── Voice Over ──
signal voice_over_started()
signal voice_over_stopped()

# ── Achievements ──
signal achievement_done(achievement_id: int)
signal all_achievements_unlocked()
signal skip_tutorial_requested()

# ── TTS ──
signal utterance_ended(utterance_id: int)

# ── Countdown ──
signal countdown_show_requested()
signal countdown_close_requested()