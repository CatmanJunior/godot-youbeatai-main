extends Node

@warning_ignore_start("unused_signal")

## Emitted when a full application restart is requested.
signal restart_requested()
## Emitted when a soundbank has been selected, carrying its associated themes and emotions.
signal soundbank_selected(themes: Array[String], emotions: Array[String])
## Emitted when note player settings have changed, carrying the new settings for each synth track.
signal note_player_settings_changed(new_settings: NotePlayerSettings, track_index: int)
## Emitted when a soundbank has been fully loaded and applied.
signal soundbank_loaded(bank_name: String)

# ── Playback ──
## Emitted when the playback state has changed (playing or stopped).
signal playing_changed(playing: bool)
## Emitted to request a change in the playback state.
signal playing_change_requested(playing: bool)
## Emitted to request toggling between play and pause.
signal play_pause_toggle_requested()

# ── BPM & Swing ──
## Emitted when the BPM value has changed.
signal bpm_changed(new_bpm: float)
## Emitted to request increasing the BPM by the given value.
signal bpm_up_requested(value: int)
## Emitted to request decreasing the BPM by the given value.
signal bpm_down_requested(value: int)
## Emitted to request setting the BPM to an exact value.
signal bpm_set_requested(value: int)
## Emitted to request setting the swing value (0.0 – 1.0).
signal swing_set_requested(value: float)


# ── Beat Clock ──
## Emitted on every beat tick with the current beat index.
signal beat_triggered(beat: int)
## Emitted to request seeking the beat clock to a specific beat.
signal beat_seek_requested(beat: int)

# ── Beat State ──
## Emitted when a beat sprite is clicked, identifying the track and beat.
signal beat_sprite_clicked(track: int, beat: int)
## Emitted when a beat's active state has changed on a given track.
signal beat_state_changed(track: int, beat: int, active: bool)
## Emitted to request setting a beat's active state on a given track.
signal beat_set_requested(track: int, beat: int, active: bool)
## Emitted when a beat template has been applied, carrying the active beat states.
signal template_set(actives: Array)
## Emitted to request applying a beat template by its index.
signal template_set_requested(template_index: int)

# ── Beat Interaction ──
## Emitted when a clap interaction is triggered.
signal clap_triggered()
## Emitted when a stomp interaction is triggered.
signal stomp_triggered()

# ── Sections ──
## Emitted to request adding a new section with the given emoji label.
signal add_section_requested(emoji: String)
## Emitted to request switching to a section by its index.
signal section_switch_requested(section_index: int)
## Emitted when a section switch has completed, carrying the old and new section data.
signal section_switched(old_section_data: SectionData, section_data: SectionData)
## Emitted when a new section has been added at the given index with an emoji label.
signal section_added(new_section_index: int, emoji: String)
## Emitted when a section has been removed at the given index.
signal section_removed(section_index: int)
## Emitted when the current section has been cleared of all beats.
signal section_cleared()
## Emitted to request copying the current section data.
signal copy_requested()
## Emitted to request pasting previously copied section data.
signal paste_requested()
## Emitted to request clearing all beats in the current section.
signal section_clear_requested()

# ── Audio Playback ──
## Emitted to request playing audio for the given track.
signal play_track_requested(track: int)
## Emitted to request playing a one-shot sound effect.
signal play_sfx_requested(stream: AudioStream)
## Emitted to request stopping all audio players immediately.
signal all_players_stop_requested()

# ── Mixing ──
## Emitted when a track has been selected for mixing, carrying its index.
signal track_selected(new_track_index: int)
## Emitted when the mixing weights have changed (master volume and per-layer weights).
signal mixing_weights_changed(master_volume: float, weights: Vector3)
## Emitted to request setting the volume for a specific track with master volume and layer weights.
signal set_track_volume_requested(track: int, master_volume: float, weights: Vector3)

# ── Chaos Pad ──
## Emitted while the chaos pad knob is being dragged, carrying the knob position, master volume, and layer weights.
signal chaos_pad_dragging(knob_position: Vector2, master_volume: float, weights: Vector3)
## Emitted when the chaos pad knob is released, carrying the final master volume and layer weights.
signal chaos_pad_released(master_volume: float, weights: Vector3)

# ── Particles ──
## Emitted to request spawning particles at a given position with a given color.
signal particles_requested(position: Vector2, color: Color)
## Emitted to request spawning particles on the progress bar.
signal progress_bar_particles_requested()
## Emitted to request spawning particles for an achievement celebration.
signal achievement_particles_requested()

# ── UI ──
## Emitted to request toggling the settings menu open or closed.
signal toggle_settings_menu_requested()

# ── Buttons ──
## Emitted when the recording sample button is toggled on or off.
signal recording_sample_button_toggled(toggled: bool)
## Emitted when the song select button is toggled on or off.
signal song_select_button_toggled(toggled: bool)

# ── Recording ──
## Emitted to request starting audio recording.
signal start_recording_requested()
## Emitted to request stopping audio recording.
signal stop_recording_requested()
## Emitted when audio recording has started.
signal recording_started()
## Emitted when audio recording has stopped, carrying the recorded audio stream.
signal recording_stopped(audio: AudioStream)
## Emitted when voice recording processing has completed, carrying the resulting sequence data.
signal voice_recording_processing_done(sequence: Sequence)
## Emitted to announce processing a recorded audio stream into a note sequence.
signal synth_sequence_ready(track_index: int)

# ── Set Audio Streams ──
## Emitted to request setting an audio stream on a specific track and audio layer.
signal set_stream_requested(track: int, audio_layer: int, audio: AudioStream)
## Emitted to request setting a recorded audio stream on a specific track.
signal set_recorded_stream_requested(track_index: int, audio: AudioStream)
## Emitted to request muting or unmuting all audio tracks.
signal mute_all_requested(mute: bool)

# ── Saving / Exporting ──
## Emitted when saving has completed successfully, carrying the output file path.
signal saving_completed(path: String)
## Emitted to request saving the current project as an MP3 file.
signal save_to_mp3_requested()
## Emitted to request exporting the project. [code]mode_export_song[/code]: false for beat, true for song.
signal export_requested(mail: bool, mode_export_song: bool)
## Emitted to request opening the export dialog. [code]mode_export_song[/code]: false for beat, true for song.
signal open_export_dialog_requested(mode_export_song: bool)

# ── Achievements ──
## Emitted when an achievement has been completed, carrying its ID.
signal achievement_done(achievement_id: int)
## Emitted when all achievements have been unlocked.
signal all_achievements_unlocked()
## Emitted to request skipping the tutorial.
signal skip_tutorial_requested()

# ── TTS ──
## Emitted when a text-to-speech utterance has finished, carrying its utterance ID.
signal utterance_ended(utterance_id: int)

# ── Countdown ──
## Emitted to request showing the countdown overlay.
signal countdown_show_requested()
## Emitted to request closing the countdown overlay.
signal countdown_close_requested()

# ── Keyboard ──
## Emitted when the Enter key is pressed.
signal enter_pressed()
## Emitted to request toggling fullscreen mode.
signal fullscreen_toggle_requested()
## Emitted when a ring key is pressed (A=0, S=1, D=2, F=3).
signal ring_key_pressed(ring: int)

# ── Recording UI ──
## Emitted to request disabling or enabling UI buttons during recording workflows.
signal buttons_disabled_requested(disabled: bool)

## Emitted when the export button is pressed. [code]mode_export_song[/code]: false for beat, true for song.
signal export_button_pressed(mode_export_song: bool)
