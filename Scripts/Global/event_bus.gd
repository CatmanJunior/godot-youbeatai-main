extends Node

@warning_ignore_start("unused_signal")

## Emitted when a full application restart is requested.
signal restart_requested()


## Emitted when a soundbank has been selected, carrying its associated themes and emotions.
signal soundbank_selected(themes: Array[String], emotions: Array[String])
## Emitted when note player settings have changed, carrying the new settings for each synth track.
signal note_player_settings_changed(new_settings: NotePlayerSettings, track_index: int)
## Emitted when a soundbank has been fully loaded and applied.
signal soundbank_loaded(bank: SoundBank)

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
## Emitted when the swing value has changed.
signal swing_changed(new_swing: float)

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
signal clap_stomp_detected(interaction_type: int)
## Emitted when a clap is detected on (or near) a beat.
signal clap_on_beat_detected()
## Emitted when a stomp is detected on (or near) a beat.
signal stomp_on_beat_detected()

# ── Sections ──
## Emitted to request adding a new section with the given emoji label.
signal add_section_requested(emoji: String)
## Emitted to request switching to a section by its index.
signal section_switch_requested(section_index: int)
## Emitted on loop
signal section_next_requested()
## Emitted on loop
signal section_loop(section_index: int, loop_cursor: int)
## Emitted to request copying the current section data.
signal section_copy_requested()
## Emitted to request pasting previously copied section data.
signal section_paste_requested()
## Emitted to request removing a section by its index.
signal section_remove_requested(section_index: int)
## Emitted when a section switch has completed, carrying the new section data.
signal section_switched(section_data: SectionData)
## Emitted when a new section has been added at the given index with an emoji label.
signal section_added(new_section_index: int, emoji: String)
## Emitted when a section has been removed at the given index.
signal section_removed(section_index: int)
## Emitted when the current section has been cleared of all beats.
signal section_cleared()
## Emitted to request clearing all beats in the current section.
signal section_clear_requested()

## Emitted when loop count is assigned a new value
signal on_set_loop_count(section_index: int, loop_count: int)
## Emitted when loop count change is requested through the UI
signal set_loop_count_requested(section_index: int, loop_count: int)


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
signal mixing_weights_changed(track_index: int, weights: Vector3)
## Emitted to request setting the volume for a specific track with master volume and layer weights.
signal set_track_volume_requested(track_index: int, master_volume: float)

# ── Chaos Pad ──
## Emitted while the chaos pad knob is being dragged, carrying the knob position.
signal chaos_pad_dragging(knob_position: Vector2)


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
signal record_button_toggled(toggled: bool)
## Emitted when the song select button is toggled on or off.
signal song_select_button_toggled(toggled: bool)

# ── Recording ──
## Emitted to request stopping audio recording.
signal stop_recording_requested(recording_data: RecordingData)
## Emitted when audio recording has started.
signal recording_started(recording_data: RecordingData)
## Emitted when audio recording has stopped, carrying the recorded audio stream.
signal recording_stopped(recording_data: RecordingData)
## Emitted to request setting a recorded audio stream on a specific track.
signal set_recorded_stream_requested(recording_data: RecordingData)
## Emitted when voice processing is complete and a sequence is ready for playback.
signal sequence_ready(sequence: Sequence, track_data: TrackData)

# ── Set Audio Streams ──
## Emitted to request setting an audio stream on a specific track and audio layer.
signal set_stream_requested(track: int, audio_layer: int, audio: AudioStream)
## Emitted to request muting or unmuting all audio tracks.
signal mute_all_requested(mute: bool)

# ── Saving / Exporting ──
## Emitted to request starting audio recording.
signal export_recording_requested(recording_data: ExportRecordingData)
## Emitted when saving has completed successfully, carrying the output file path.
signal saving_completed(path: String)
## Emitted to request saving the current song data to disk.
signal save_song_requested()
## Emitted to request loading the last saved song data from disk.
signal load_song_requested()
## Emitted after a song has been fully loaded into SongState.
## Handlers should rebuild any runtime objects (section buttons, waveform visualizers)
## before the section_switch_requested signal fires the full UI cascade.
signal song_loaded()
## Emitted to request saving the current project as an MP3 file.
signal save_to_mp3_requested()
## Emitted to request exporting the project. [code]mode_export_song[/code]: false for beat, true for song.
signal export_requested(mail: bool, mode_export_song: bool)
## Emitted to request opening the export dialog. [code]mode_export_song[/code]: false for beat, true for song.
signal open_export_dialog_requested(mode_export_song: bool)
## Emitted when the export button is pressed. [code]mode_export_song[/code]: false for beat, true for song.
signal export_button_pressed(mode_export_song: bool)

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
## Emitted to request toggling fullscreen mode.
signal fullscreen_toggle_requested()

# ── Recording UI ──
## Emitted to request disabling or enabling UI buttons during recording workflows.
signal buttons_disabled_requested(disabled: bool)

# -- Visibility --
## Emitted to request setting the visibility of a UI element by VisibilityManager.UIElement enum.
## See VisibilityManager.UIElement for all available targets.
signal ui_visibility_requested(element: int, visible: bool)
## Emitted to request setting the visibility of a specific track's sprites.
signal track_sprites_visibility_requested(track: int, visible: bool)


## Emitted to request setting the visibility of the clap/stomp interaction UI.
signal continue_button_pressed()

# ── Tutorial Beat Control ──
## Emitted to request forcing a specific beat slot to be active/free, used by tutorial.
signal beat_set_free_requested(track: int, beat: int, free: bool)

# ── Tutorial Chaos Pad ──
## Emitted to request snapping the chaos pad knob to the given world position.
signal chaos_pad_knob_position_set_requested(position: Vector2)
## Emitted to request stopping the chaos pad activation button's animation player.
signal chaos_pad_button_animation_stop_requested()
## Emitted to request stopping the record button's animation player.
signal record_button_animation_stop_requested()


