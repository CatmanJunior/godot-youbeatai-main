# YouBeatAI — Architecture & Script Overview

> **Project:** YouBeatAI (Klappy de Ritme Robot) — A rhythm/beat-making game built in Godot 4 with GDScript and C#.
>
> This document provides a detailed overview of every script in the project, how they connect, which systems they belong to, and whether they are written in **C#** or **GDScript**.

---

## Table of Contents

- [High-Level Architecture](#high-level-architecture)
- [Autoloads (Global Singletons)](#autoloads-global-singletons)
- [Script Language Overview](#script-language-overview)
- [Core Systems](#core-systems)
  - [1. Global System](#1-global-system)
  - [2. Manager System](#2-manager-system)
  - [3. Audio System](#3-audio-system)
  - [4. UI System](#4-ui-system)
  - [5. Data Classes](#5-data-classes)
  - [6. Buttons](#6-buttons)
  - [7. Chaos Pad (Mixing)](#7-chaos-pad-mixing)
  - [8. Audio Banks](#8-audio-banks)
  - [9. Klappy (Character)](#9-klappy-character)
  - [10. Achievements & Tutorial](#10-achievements--tutorial)
  - [11. MIDI](#11-midi)
- [Addon Scripts](#addon-scripts)
  - [FFT (Fast Fourier Transform)](#fft-fast-fourier-transform)
  - [CSV Data Importer](#csv-data-importer)
  - [Synth Addon](#synth-addon)
- [Experimental Scripts](#experimental-scripts)
- [Scene Structure](#scene-structure)
- [Signal Flow & Architecture Diagram](#signal-flow--architecture-diagram)
- [Audio Pipeline](#audio-pipeline)
- [Mixing Pipeline](#mixing-pipeline)

---

## High-Level Architecture

The project follows a **signal-driven architecture** where almost all inter-system communication goes through a central **EventBus** singleton. The core loop is:

```
Input (keyboard, touch, mic) → EventBus signals → Managers (game logic) → Audio/UI output
```

**Key architectural patterns:**
- **EventBus** — Central decoupled messaging hub (40+ signals)
- **GameState** — Global read-access to mutable game state
- **Manager pattern** — Dedicated manager nodes for beats, layers, audio, BPM, UI, templates, and mixing
- **Data classes** — Lightweight `RefCounted` data containers (`LayerData`, `RingData`, `SynthData`)
- **Scene composition** — Reusable `.tscn` prefabs instantiated at runtime (beats, layer buttons)

---

## Autoloads (Global Singletons)

Defined in `project.godot` under `[autoload]`:

| Singleton   | Script                           | Language | Purpose                                    |
|-------------|----------------------------------|----------|--------------------------------------------|
| `FFT`       | `fft/Fft.gd`                    | GDScript | Fast Fourier Transform for audio analysis  |
| `EventBus`  | `Scripts/Global/event_bus.gd`    | GDScript | Central signal hub for all systems         |
| `GameState` | `Scripts/Global/game_state.gd`   | GDScript | Global mutable game state                  |

---

## Script Language Overview

### C# Scripts (2 files)

| Script                              | Path                                | Purpose                        |
|-------------------------------------|-------------------------------------|--------------------------------|
| `AudioBank.cs`                      | `Scripts/AudioBanks/AudioBank.cs`   | Audio bank resource definition |
| `EffectProfile.cs`                  | `Scripts/AudioBanks/EffectProfile.cs` | Audio effects configuration  |

### GDScript — Core Scripts (45 files)

| Script                              | Path                                              | System           |
|-------------------------------------|---------------------------------------------------|------------------|
| `event_bus.gd`                      | `Scripts/Global/event_bus.gd`                     | Global           |
| `game_state.gd`                     | `Scripts/Global/game_state.gd`                    | Global           |
| `game_manager.gd`                   | `Scripts/Managers/game_manager.gd`                | Manager          |
| `beat_manager.gd`                   | `Scripts/Managers/beat_manager.gd`                | Manager          |
| `layer_manager.gd`                  | `Scripts/Managers/layer_manager.gd`               | Manager          |
| `template_manager.gd`              | `Scripts/Managers/template_manager.gd`            | Manager          |
| `bpm.gd`                            | `Scripts/Managers/bpm.gd`                         | Manager          |
| `keyboard_input_manager.gd`        | `Scripts/Managers/keyboard_input_manager.gd`      | Manager          |
| `audio_player_manager.gd`          | `Scripts/Audio/audio_player_manager.gd`           | Audio            |
| `mixing_manager.gd`                | `Scripts/Audio/mixing_manager.gd`                 | Audio            |
| `microphone_capture.gd`            | `Scripts/Audio/microphone_capture.gd`             | Audio            |
| `real_time_audio_recording.gd`     | `Scripts/Audio/real_time_audio_recording.gd`      | Audio            |
| `ring_sample_recorder.gd`          | `Scripts/Audio/ring_sample_recorder.gd`           | Audio            |
| `voice_recorder.gd`                | `Scripts/Audio/voice_recorder.gd`                 | Audio            |
| `waveform_visualizer.gd`           | `Scripts/Audio/waveform_visualizer.gd`            | Audio            |
| `layer_voice_over.gd`              | `Scripts/Audio/layer_voice_over.gd`               | Audio            |
| `song_voice_over_manager.gd`       | `Scripts/Audio/song_voice_over_manager.gd`        | Audio            |
| `audio_saving_manager.gd`          | `Scripts/audio_saving_manager.gd`                 | Audio            |
| `ui_manager.gd`                    | `Scripts/UI/ui_manager.gd`                        | UI               |
| `visibility_manager.gd`            | `Scripts/UI/visibility_manager.gd`                | UI               |
| `colors.gd`                        | `Scripts/UI/colors.gd`                            | UI               |
| `play_star_animation.gd`           | `Scripts/UI/play_star_animation.gd`               | UI               |
| `particle_manager.gd`              | `Scripts/UI/particle_manager.gd`                  | UI               |
| `count_down.gd`                    | `Scripts/UI/count_down.gd`                        | UI               |
| `beat_sprite.gd`                   | `Scripts/UI/beat_sprite.gd`                       | UI               |
| `volume_treshold_slider.gd`        | `Scripts/UI/volume_treshold_slider.gd`            | UI               |
| `ConfirmationPrompt.gd`            | `Scripts/UI/ConfirmationPrompt.gd`                | UI               |
| `instrument_button.gd`             | `Scripts/Buttons/instrument_button.gd`            | Buttons          |
| `record_button.gd`                 | `Scripts/Buttons/record_button.gd`                | Buttons          |
| `record_sample_button.gd`          | `Scripts/Buttons/record_sample_button.gd`         | Buttons          |
| `layer_chaos_pad_select_button.gd` | `Scripts/Buttons/layer_chaos_pad_select_button.gd`| Buttons          |
| `layer_data.gd`                    | `Scripts/DataClasses/layer_data.gd`               | Data Classes     |
| `ring_data.gd`                     | `Scripts/DataClasses/ring_data.gd`                | Data Classes     |
| `synth_data.gd`                    | `Scripts/DataClasses/synth_data.gd`               | Data Classes     |
| `ChaosPadKnob.gd`                  | `Scripts/ChaosPad/ChaosPadKnob.gd`               | Chaos Pad        |
| `ChaosPadCalculator.gd`            | `Scripts/ChaosPad/ChaosPadCalculator.gd`          | Chaos Pad        |
| `ApplyBankToMixer.gd`              | `Scripts/AudioBanks/ApplyBankToMixer.gd`          | Audio Banks      |
| `klappy_respons_bubble.gd`         | `Scripts/Klappy/klappy_respons_bubble.gd`         | Klappy           |
| `klappy_reaction.gd`               | `Scripts/Klappy/klappy_reaction.gd`               | Klappy           |
| `Klappy_soundbank_screen.gd`       | `Scripts/Klappy/Klappy_soundbank_screen.gd`       | Klappy           |
| `continue.gd`                      | `Scripts/Klappy/continue.gd`                      | Klappy           |
| `achievements.gd`                  | `Scripts/Achievements/achievements.gd`            | Achievements     |
| `unlock_achievements.gd`           | `Scripts/Achievements/unlock_achievements.gd`     | Achievements     |
| `tutorial.gd`                      | `Scripts/Achievements/tutorial.gd`                | Achievements     |
| `midi_helper.gd`                   | `Scripts/midi_helper.gd`                          | MIDI             |

### GDScript — Addon Scripts (8 files)

| Script                        | Path                                             | Addon              |
|-------------------------------|--------------------------------------------------|--------------------|
| `Fft.gd`                     | `fft/Fft.gd`                                    | FFT                |
| `Complex.gd`                 | `fft/Complex.gd`                                | FFT                |
| `godot-fft.gd`               | `fft/godot-fft.gd`                              | FFT                |
| `csv_data.gd`                | `addons/csv-data-importer/csv_data.gd`           | CSV Data Importer  |
| `plugin.gd` (CSV)            | `addons/csv-data-importer/plugin.gd`             | CSV Data Importer  |
| `import_plugin.gd`           | `addons/csv-data-importer/import_plugin.gd`      | CSV Data Importer  |
| `synth.gd`                   | `addons/synth/synth.gd`                          | Synth              |
| `plugin.gd` (Synth)          | `addons/synth/plugin.gd`                         | Synth              |

### GDScript — Addon Demo Scripts (3 files)

| Script                        | Path                                             | Addon              |
|-------------------------------|--------------------------------------------------|--------------------|
| `gui.gd`                     | `addons/synth/demo/gui.gd`                      | Synth Demo         |
| `waveform_visualizer.gd`     | `addons/synth/demo/ui/waveform_visualizer.gd`   | Synth Demo         |
| `slider.gd`                  | `addons/synth/demo/ui/slider.gd`                | Synth Demo         |

### GDScript — Experimental Scripts (15 files)

| Script                        | Path                                                   | Area               |
|-------------------------------|--------------------------------------------------------|--------------------|
| `chords.gd`                  | `Experimental/chords/chords.gd`                        | Chords             |
| `record_voice.gd`            | `Experimental/VoiceToSynth/record_voice.gd`            | VoiceToSynth       |
| `test.gd`                    | `Experimental/VoiceToSynth/test.gd`                    | VoiceToSynth       |
| `notes.gd`                   | `Experimental/VoiceToSynth/notes.gd`                   | VoiceToSynth       |
| `Note.gd`                    | `Experimental/VoiceToSynth/Note.gd`                    | VoiceToSynth       |
| `envelope.gd`                | `Experimental/VoiceToSynth/envelope.gd`                | VoiceToSynth       |
| `color_rect.gd`              | `Experimental/VoiceToSynth/color_rect.gd`              | VoiceToSynth       |
| `Octave.gd`                  | `Experimental/VoiceToSynth/Octave.gd`                  | VoiceToSynth       |
| `levelLabel.gd`              | `Experimental/VoiceToSynth/levelLabel.gd`              | VoiceToSynth       |
| `Sequence.gd`                | `Experimental/soundfont/Sequence.gd`                   | SoundFont          |
| `SequenceNote.gd`            | `Experimental/soundfont/SequenceNote.gd`               | SoundFont          |
| `notePlayer.gd`              | `Experimental/soundfont/notePlayer.gd`                 | SoundFont          |
| `voice_recorder.gd`          | `Experimental/soundfont/voice_recorder.gd`             | SoundFont          |
| `voice_processor.gd`         | `Experimental/soundfont/voice_processor.gd`            | SoundFont          |
| `klappy_animations.gd`       | `Experimental/Klappy/klappy_animations.gd`             | Klappy Prototype   |

**Total: 2 C# + 71 GDScript = 73 scripts**

---

## Core Systems

### 1. Global System

The global system provides project-wide singletons loaded via Godot's autoload mechanism.

#### `event_bus.gd` — Central Signal Hub
- **Extends:** `Node` (Autoload)
- **Purpose:** Defines 40+ signals for decoupled communication between all systems. No script directly calls another — they all emit and connect through EventBus.
- **Signal categories:**
  - **Playback:** `playback_started`, `playback_stopped`, `bpm_changed`, `playing_changed`, `play_pause_toggled`
  - **Beat:** `beat_triggered`, `beat_sprite_clicked`, `beat_state_changed`, `should_clap`, `should_stomp`
  - **Layers:** `layer_changed`, `layer_added`, `layer_removed`, `layer_cleared`, `layer_copied`, `layer_pasted`
  - **Audio:** `play_ring_requested`, `play_sfx_requested`, `audio_bank_loaded`
  - **Mixing:** `ring_selected`, `synth_selected`, `mixing_weights_changed`, `chaos_pad_dragging`, `chaos_pad_released`
  - **UI:** `ui_mode_changed`, `visibility_changed`, `buttons_disabled_changed`
  - **Recording:** `recording_started`, `recording_stopped`, `request_set_stream`, `master_recording_started`
  - **Achievements:** `achievement_done`, `all_achievements_unlocked`
  - **TTS:** `utterance_ended`, `countdown_show_requested`, `countdown_close_requested`
- **Dependencies:** None (pure event hub)

#### `game_state.gd` — Global State Store
- **Extends:** `Node` (Autoload)
- **Purpose:** Stores mutable game state (layers, playback status, mixing state) for easy access without scene tree queries.
- **Key properties:**
  - `layers: Array[LayerData]` — All layer data
  - `current_layer: LayerData` — Active layer
  - `current_layer_index: int`, `layers_amount: int`
  - `playing: bool`, `bpm: int` (default 120), `current_beat: int`
  - `beats_amount: int` (16), `swing: float` (0.05)
  - `selected_ring: int`, `selected_synth: int`
  - `is_recording: bool`, `microphone_volume: float`
- **Key methods:** `get_layer()`, `get_current_ring_data()`, `get_current_synth_data()`, `get_beat()`, `has_active_beats_on_layer()`, `is_last_layer()`
- **Connects to:** EventBus signals (`layer_changed`, `layer_added`, `layer_removed`, etc.)
- **Syncs with:** LayerManager (reads layer data)

---

### 2. Manager System

Managers are scene-tree nodes (accessed via `%NodeName` unique names) that handle game logic.

#### `game_manager.gd` — Game Lifecycle
- **Extends:** `Node`
- **Purpose:** Top-level game orchestration — initialization, TTS callbacks, countdown triggers.
- **Key methods:** `deferred_setup()`, `utterance_end()`, `show_countdown()`, `text_without_emoticons()`
- **Dependencies:** EventBus, UiManager

#### `bpm.gd` — BPM & Beat Clock
- **Extends:** `Node`
- **Purpose:** Master beat clock. Counts time and emits `beat_triggered` on each beat based on BPM.
- **Key properties:** `bpm` (120), `playing`, `current_beat`, `swing` (0.05), `beats_amount` (16 static)
- **Key methods:** `_process()` — increments beat timer, applies swing to odd beats, emits `EventBus.beat_triggered`
- **Dependencies:** EventBus (emits `beat_triggered`, `bpm_changed`, `playing_changed`)

#### `beat_manager.gd` — Beat State & Detection
- **Extends:** `Node`
- **Purpose:** Manages beat activation state, detects claps/stomps from microphone, triggers audio playback on each beat, and tracks achievement progress.
- **Key properties:** `current_layer: LayerData`, `stomped/clapped` flags, hit counts, `progress_bar_value`
- **Key methods:** `on_beat()` (play audio per active beat), `on_clap()`/`on_stomp()` (detect input, toggle beats), `toggle_beat()`, `set_beat()`, `get_beat()`
- **Dependencies:** EventBus (all connectivity), LayerData

#### `layer_manager.gd` — Layer CRUD
- **Extends:** `Node`
- **Purpose:** Creates, deletes, switches, copies, and pastes layers. Manages layer button UI and syncs audio slices.
- **Constants:** `LAYERS_AMOUNT_MAX = 10`, `LAYERS_AMOUNT_INITIAL = 4`
- **Key methods:** `add_layer()`, `remove_layer()`, `switch_layer()`, `next_layer()`, `_copy_layer()`, `_paste_layer()`, `clear_layer()`
- **Dependencies:** EventBus, UiManager, LayerData, AudioSavingManager, SongVoiceOver, BpmManager, RealTimeAudioRecording

#### `template_manager.gd` — Beat Templates
- **Extends:** `Node`
- **Purpose:** Loads beat patterns from text files in `Resources/Templates/` and applies them to the current layer.
- **Key methods:** `read_templates()`, `_to_actives()`, `_set_template()`, `get_current_actives()`
- **Template format:** 4 rings × N beats stored as text (e.g., `"R0101..."`)
- **Dependencies:** EventBus, BpmManager

#### `keyboard_input_manager.gd` — Keyboard Input
- **Extends:** `Node`
- **Purpose:** Converts keyboard input into EventBus signals.
- **Key mappings:**
  - `UP/DOWN` → BPM ±5
  - `SPACE` → Play/Pause toggle
  - `A/S/D/F` → Ring 0–3 events
  - `F11` → Fullscreen toggle
  - `F6` variants → Debug BPM shortcuts
- **Dependencies:** EventBus (emits signals only)

---

### 3. Audio System

The audio system handles recording, playback, mixing, voice-overs, and audio file export.

#### `audio_player_manager.gd` — Audio Playback Engine
- **Extends:** `Node`
- **Purpose:** Manages all audio playback: 4 ring players (each with 3-stream synchronized: main/alt/recorded), 2 voice synth players, and 1 SFX player.
- **Key properties:** `audio_players[4]`, `sync_streams[4]`, `voice_players[2]`, `sfx_player`
- **Key methods:** `play_ring()`, `play_sfx()`, `play_voice()`, `stop_voice()`, `set_ring_volume()`, `set_voice_stream()`, `set_voice_volume()`, `_mute_all()`
- **Dependencies:** EventBus

#### `mixing_manager.gd` — Chaos Pad Mixing Logic
- **Extends:** `Node`
- **Purpose:** Translates chaos pad knob position into volume weights for rings and synths. Supports 3 modes: `SAMPLE_MIXING`, `SYNTH_MIXING`, `SONG_MIXING`.
- **Key methods:** `samples_mixing_update_volumes()`, `synth_mixing_update_volumes()`, `song_mixing_update_volumes_for_song()`, `on_update_mixing()`, `store_active_knob()`, `retrieve_active_knob()`
- **Dependencies:** EventBus, LayerData, ChaosPadCalculator, AudioPlayerManager

#### `microphone_capture.gd` — Microphone Input & Analysis
- **Class Name:** `MicrophoneRecorder`
- **Extends:** `Node`
- **Purpose:** Captures microphone input, performs spectrum analysis for clap detection (high frequency > 7000Hz) and stomp detection (low frequency < 150Hz), and provides audio recording.
- **Signals:** `recording_started()`, `recording_stopped(recorded_audio)`
- **Key methods:** `start_recording()`, `stop_recording()`, `_get_magnitude()`, `get_microphone_volume()`
- **Dependencies:** AudioServer (bus/effects)

#### `real_time_audio_recording.gd` — Master Recording
- **Extends:** `Node`
- **Purpose:** Records the entire song output via the SubMaster audio bus. Manages a progress bar and coordinates with UI during recording.
- **Key methods:** `start_recording_master()`, `stop_recording_master()`, `on_top()`, `_disable_buttons()`
- **Dependencies:** EventBus, SongVoiceOver, LayerManager, BpmManager, UiManager, GameManager

#### `ring_sample_recorder.gd` — Single Ring Sample Recording
- **Extends:** `Node`
- **Purpose:** Records a single ring sample from the microphone. Auto-stops after 2× beat length and trims leading silence.
- **Key methods:** `_handle_recording()`, `_start_recording()`, `_stop_recording()`, `_trim_audio_stream()`
- **Dependencies:** EventBus, MicrophoneCapture, GameState

#### `voice_recorder.gd` — Voice-Over Recording Helper
- **Class Name:** `VoiceRecorder` (RefCounted)
- **Purpose:** Reusable voice recording utility with configurable delay. Ducks the SubMaster bus during recording.
- **Signals:** `recording_started()`, `recording_stopped(recorded_audio)`
- **Key methods:** `arm()`, `cancel()`, `start()`, `stop()`
- **Dependencies:** MicrophoneCapture, AudioServer

#### `layer_voice_over.gd` — Per-Layer Voice-Over
- **Extends:** `Node`
- **Purpose:** Manages voice-over recording and playback for a single synth slot (green=0, purple=1) within a layer.
- **Key properties:** `synth_index: int`, `recorder: VoiceRecorder`, `waveform: WaveformVisualizer`
- **Key methods:** `_on_record_button_pressed()`, `_on_recording_started()`, `_on_recording_stopped()`, `on_top()`, `on_top_delayed()`
- **Dependencies:** EventBus, VoiceRecorder, WaveformVisualizer, LayerData, SynthData, AudioPlayerManager

#### `song_voice_over_manager.gd` — Song-Level Voice-Over
- **Extends:** `Node`
- **Purpose:** Records and plays back a voice-over for the entire song (vs. individual layers).
- **Signals:** `started_recording()`, `stopped_recording()`
- **Key methods:** `start_recording()`, `stop_recording()`, `on_top()`
- **Dependencies:** AudioServer, managers

#### `waveform_visualizer.gd` — Circular Waveform Drawing
- **Class Name:** `WaveformVisualizer` (RefCounted)
- **Purpose:** Draws circular waveform visualizations on `Line2D` nodes from `AudioStreamWAV` sample data.
- **Key methods:** `update_lines()`, `_set_volume_line()`, `_calculate_volume_offsets()`, `get_volume_at_time()` (static)
- **Dependencies:** None (pure data processing)

#### `audio_saving_manager.gd` — Audio Export & WAV Manipulation
- **Class Name:** `AudioSavingManager` (RefCounted)
- **Purpose:** Utility class for exporting audio and manipulating WAV data. Handles song/beat export, layer insertion/removal, stereo-to-mono conversion, stream mixing, trimming, and silence insertion.
- **Key methods (all static):** `save_realtime_recorded_song_as_file()`, `save_realtime_recorded_beat_as_file()`, `remove_layer_part_of_recordings()`, `insert_silent_layer_part_of_recordings()`, `convert_stereo_to_mono()`, `mix_streams()`, `trim_stream()`, `remove_segment()`, `insert_silence()`, `combine_streams()`
- **Dependencies:** None (pure data processing on raw PCM)

---

### 4. UI System

#### `ui_manager.gd` — Master UI Controller
- **Extends:** `Node` (~650 lines)
- **Purpose:** Central hub for all UI elements. Manages 70+ `@export` references to buttons, sprites, progress bars, panels, and textures. Handles beat sprite visualization, layer button updates, audio export, and user interaction callbacks.
- **Key properties:** `beat_sprites[][]` (2D array by ring/beat), `colors[]`, `chaos_pad_mode`, `interface_set_to_default_state`
- **Key methods:** `update_ui()`, `initialize_sprite_positions()`, `sprite_position()` (radial positioning), `_update_beat_sprites()`, `_update_ring_button_outlines()`, `_export_song_wav()`, `_export_beat_wav()`, `add_layer()`, `_on_switch_layer()`, `_on_play_pause()`, `_on_restart_button()`
- **Dependencies:** EventBus, GameState, LayerManager, BpmManager, VisibilityManager, Colors, and virtually every other UI node

#### `visibility_manager.gd` — UI Visibility Control
- **Extends:** `Node`
- **Purpose:** Toggles visibility of UI groups (rings, buttons, panels, recording controls, synth layers).
- **Key methods:** `set_entire_interface_visibility()`, `set_ring_visibility()`, `set_main_buttons_visibility()`, `set_recording_buttons_visibility()`, `set_green_layer_visibility()`, `set_purple_layer_visibility()`, `hide_all()`, `show_all()`
- **Dependencies:** UiManager

#### `colors.gd` — Color Palette
- **Extends:** `Node`
- **Purpose:** Defines the project's 7-color palette (4 ring colors + 2 synth colors + 1 extra), shared across all UI elements.
- **Key properties:** `colors: Array[Color]` (7 exported colors)
- **Dependencies:** None

#### `beat_sprite.gd` — Clickable Beat
- **Extends:** `Sprite2D`
- **Purpose:** Individual beat dot in the circular grid. Has an `Area2D` for click detection.
- **Key properties:** `ring: int`, `sprite_index: int`
- **Key methods:** `_on_area_input()`, `_on_click()` → emits `EventBus.beat_sprite_clicked`
- **Dependencies:** EventBus

#### `play_star_animation.gd` — Star Animation
- **Extends:** `Node2D`
- **Purpose:** Controls decorative star animation playback.
- **Signals:** `animation_star_play()`, `animation_star_stop()`
- **Dependencies:** None

#### `particle_manager.gd` — Particle Effects
- **Extends:** `Node`
- **Purpose:** Emits particles for beat hits, progress bar milestones, and achievement unlocks.
- **Key methods:** `emit_beat_particles()`, `emit_progress_bar_particles()`, `emit_achievement_particles()`
- **Dependencies:** EventBus

#### `count_down.gd` — Recording Countdown
- **Extends:** `Node`
- **Purpose:** Displays a countdown timer before recording starts, positioned at the mic button location.
- **Key methods:** `show_count_down()`, `close_count_down()`, `calculate_time_until_top()`, `update_count_down_label()`
- **Dependencies:** EventBus, BpmManager, MixingManager

#### `volume_treshold_slider.gd` — Volume Threshold
- **Extends:** `HSlider`
- **Purpose:** Slider for adjusting the recording volume threshold.
- **Dependencies:** EventBus (emits threshold changes)

#### `ConfirmationPrompt.gd` — Modal Dialog
- **Extends:** `Panel`
- **Purpose:** Generic modal confirmation dialog with agree/cancel buttons.
- **Key methods:** `open(agree_action: Callable)`, `close()`
- **Dependencies:** None

---

### 5. Data Classes

Lightweight `RefCounted` data containers — no scene tree dependency.

#### `layer_data.gd` — Layer Data
- **Class Name:** `LayerData`
- **Constants:** `RINGS_PER_LAYER = 4`, `SYNTHS_PER_LAYER = 2`
- **Key properties:**
  - `rings: Array[RingData]` — 4 rings (stomp, clap, instrument 1, instrument 2)
  - `synths: Array[SynthData]` — 2 synths (green, purple)
  - `emoji: String` — Layer button emoji icon
- **Key methods:** `get_beat_actives()`, `set_beat_actives()`, `toggle_beat()`, `set_beat()`, `get_beat()`, `has_active_beats()`, `clear_beats()`, `get/set_knob_positions()`, `duplicate_layer()`
- **Used by:** GameState, BeatManager, LayerManager, MixingManager, and more

#### `ring_data.gd` — Ring Data
- **Class Name:** `RingData`
- **Constants:** `BEATS_AMOUNT_DEFAULT = 16`
- **Key properties:**
  - `beats: Array[bool]` — 16-beat activation pattern
  - `sample_knob_position: Vector2` — Chaos pad position
  - `master_volume: float`
  - `weights: Vector3` — Mixing weights (main, alt, recorded)
- **Key methods:** `has_active_beats()`, `clear_beats()`, `duplicate_ring()`

#### `synth_data.gd` — Synth Data
- **Class Name:** `SynthData`
- **Key properties:**
  - `synth_knob_position: Vector2` — Chaos pad position
  - `voice_over: AudioStream` — Synth voice-over
  - `layer_voice_over: AudioStream` — Layer-specific recording
  - `master_volume: float`, `weights: Vector3`
- **Key methods:** `duplicate_synth()`

---

### 6. Buttons

#### `instrument_button.gd` — Stomp/Clap/Instrument Button
- **Extends:** `Sprite2D`
- **Signals:** `on_pressed(ring: int)`
- **Purpose:** Interactive instrument button (rings 0–3). For ring 0/1 in clap mode, emits stomp/clap signals. Otherwise plays ring audio and optionally adds a beat.
- **Key methods:** `_on_press()`, `_button_sound()`, `_button_behaviour()`, `_start_color_change()`
- **Dependencies:** EventBus, UiManager, BpmManager, MixingManager

#### `record_button.gd` — Generic Record Button
- **Extends:** `Sprite2D`
- **Purpose:** Base record button with color state management (unused/placeholder).
- **Dependencies:** None

#### `record_sample_button.gd` — Sample Record Toggle
- **Extends:** `Button`
- **Purpose:** Toggle button for starting/stopping sample recording. Updates a fill texture progress bar.
- **Dependencies:** EventBus

#### `layer_chaos_pad_select_button.gd` — Synth Selector Button
- **Extends:** `Sprite2D`
- **Purpose:** Selects green (0) or purple (1) synth for chaos pad mixing.
- **Dependencies:** EventBus (emits `synth_selected`)

---

### 7. Chaos Pad (Mixing)

The Chaos Pad is a triangular mixing interface where the knob position determines the mix between main, alternate, and recorded audio.

#### `ChaosPadKnob.gd` — Draggable Knob
- **Extends:** `Sprite2D`
- **Purpose:** Interactive draggable knob within a triangle area. Emits drag/release events with calculated mixing weights.
- **Key methods:** `_input()` — handle mouse drag, clamp to triangle, emit signals
- **Dependencies:** EventBus, ChaosPadCalculator, UiManager, MixingManager

#### `ChaosPadCalculator.gd` — Triangle Math
- **Class Name:** `ChaosPadCalculator` (static utility)
- **Purpose:** Pure math for barycentric weight calculation and triangle clamping.
- **Key methods (static):** `clamp_to_triangle_area()`, `calc_weights()`, `_barycentric_weights()`, `_is_inside()`, `_closest_point_on_triangle()`
- **Dependencies:** None

---

### 8. Audio Banks

Audio banks define sets of drum sounds, synth configurations, and audio effects.

#### `AudioBank.cs` ⚡ C#
- **Class:** `AudioBank : Resource` (`[GlobalClass]`)
- **Purpose:** Resource defining a complete audio bank: 8 drum sounds (kick/snare/clap/closed × main/alt), 2 synth configurations (green/purple with soundfont, instrument ID, and beats), and an `EffectProfile`.
- **Dependencies:** EffectProfile

#### `EffectProfile.cs` ⚡ C#
- **Class:** `EffectProfile : Resource`
- **Purpose:** Configurable audio effects: pitch shift, distortion, phaser, delay, reverb, chorus.
- **Key methods:** `Apply(bus_name)` — applies all effects to a named audio bus via AudioServer
- **Dependencies:** Godot AudioServer

#### `ApplyBankToMixer.gd`
- **Extends:** `Node`
- **Purpose:** Applies an `AudioBank`'s effect profile to the Green, Green_alt, Purple, and Purple_alt audio buses.
- **Key methods:** `on_audio_bank_loaded()`
- **Dependencies:** AudioServer, AudioBank, EffectProfile

---

### 9. Klappy (Character)

Klappy is the robot character that guides the user with speech bubbles and TTS (Text-to-Speech).

#### `klappy_reaction.gd` — Reaction Trigger
- **Extends:** `Node`
- **Purpose:** Triggers Klappy speech and TTS. Shows response bubble, speaks via `DisplayServer.tts_speak()`, hides when done.
- **Dependencies:** DisplayServer (TTS), klappy_respons_bubble

#### `klappy_respons_bubble.gd` — Speech Bubble UI
- **Extends:** `Node2D`
- **Signals:** `continue_pressed()`
- **Purpose:** Display Klappy's response text with animation.
- **Key methods:** `fill_response_label()`, `change_panel_visibility()`

#### `Klappy_soundbank_screen.gd` — Achievement TTS Notification
- **Extends:** `Node`
- **Purpose:** Shows achievement notifications via Klappy with TTS narration.
- **Dependencies:** GameManager, DisplayServer (TTS)

#### `continue.gd` — Continue Button
- **Extends:** `Button`
- **Signals:** `animation_play()`, `animation_stop()`
- **Purpose:** Animated continue button in Klappy's speech bubble.

---

### 10. Achievements & Tutorial

#### `achievements.gd` — Achievement System
- **Extends:** `Node`
- **Purpose:** Blocker-based progressive achievement system. Defines 7 achievements that unlock UI elements as the user progresses (e.g., place beats, clap, record, add layers). Uses TTS tooltips to guide the user.
- **Inner class:** `AchievementDef` — condition callable, tooltip text, worth, result nodes
- **Key methods:** `_get_achievements()`, `on_ready()`, `on_update()`, `open_tooltip()`, `close_tooltip()`, `_speak_tooltip()`, `unlock_all_achievements()`
- **Dependencies:** EventBus, UiManager, BeatManager, VisibilityManager, AudioPlayerManager, LayerVoiceOver, DisplayServer

#### `unlock_achievements.gd` — Debug Unlock
- **Extends:** `Button`
- **Purpose:** Test utility button to unlock all achievements (code mostly commented out).

#### `tutorial.gd` — Interactive Tutorial
- **Extends:** `Node`
- **Purpose:** Step-by-step interactive tutorial with TTS narration. Loads steps from a JSON file and uses condition/outcome callables to progress.
- **Key methods:** `_build_tutorial_steps()`, `try_activate_tutorial()`, `update_tutorial()`, `_speak_tutorial_instruction()`, `_load_tutorial_steps_from_json()`, `_resolve_step_callable()`
- **Condition examples:** `_cond_clapped()`, `_cond_playing()`, `_cond_red_ring_filled()`
- **Dependencies:** DisplayServer, managers, EventBus

---

### 11. MIDI

#### `midi_helper.gd` — MIDI Input Handler
- **Extends:** `Node`
- **Purpose:** Minimal MIDI input handler. Enables MIDI inputs and responds to MIDI events (play on 250, pause on 252).
- **Dependencies:** OS MIDI input

---

## Addon Scripts

### FFT (Fast Fourier Transform)

Used for audio spectrum analysis (clap/stomp detection).

| Script         | Purpose                                              |
|----------------|------------------------------------------------------|
| `Fft.gd`       | Forward/inverse FFT implementation (static methods) |
| `Complex.gd`   | Complex number arithmetic (`re`, `im`, `add`, `sub`, `mul`, `cexp`) |
| `godot-fft.gd` | EditorPlugin that registers FFT as an autoload      |

### CSV Data Importer

Editor plugin for importing CSV/TSV files as Godot resources.

| Script             | Purpose                                                   |
|--------------------|-----------------------------------------------------------|
| `csv_data.gd`      | Resource container for parsed CSV rows                   |
| `plugin.gd`        | EditorPlugin registration                                |
| `import_plugin.gd` | EditorImportPlugin that parses CSV/TSV with configurable delimiters, headers, and number detection |

### Synth Addon

A threaded audio synthesis engine supporting multiple waveforms.

| Script                       | Purpose                                                   |
|------------------------------|-----------------------------------------------------------|
| `synth.gd`                   | Main synth engine (Sine/Saw/Pulse/Triangle waveforms, biquad lowpass filter, threaded audio generation) |
| `plugin.gd`                  | EditorPlugin registration                                |
| `gui.gd` (demo)             | Demo GUI with parameter sliders                          |
| `waveform_visualizer.gd` (demo) | Demo waveform visualization                          |
| `slider.gd` (demo)          | Demo slider control                                      |

---

## Experimental Scripts

These are prototype/R&D scripts **not used in production**:

### VoiceToSynth (`Experimental/VoiceToSynth/`)
Prototype for converting voice input to synthesizer output:
- `record_voice.gd` — Voice capture test
- `test.gd` — Generic test script
- `notes.gd` — Musical note definitions (Resource)
- `Note.gd` — Single note data class
- `envelope.gd` — ADSR envelope generator
- `color_rect.gd` — Visual beat indicator
- `Octave.gd` — Octave container (Resource)
- `levelLabel.gd` — Level display label

### SoundFont (`Experimental/soundfont/`)
Prototype for SoundFont-based playback:
- `Sequence.gd` — Note sequence container
- `SequenceNote.gd` — Single sequence note data
- `notePlayer.gd` — SoundFont note playback
- `voice_recorder.gd` — Voice capture for sequence
- `voice_processor.gd` — Voice-to-sequence conversion

### Other Experimental
- `chords.gd` (`Experimental/chords/`) — Chord sequencer prototype
- `klappy_animations.gd` (`Experimental/Klappy/`) — Klappy character animation prototype

---

## Scene Structure

### Main Scenes

| Scene                      | Purpose                                                    |
|----------------------------|------------------------------------------------------------|
| `main_menu_web.tscn`      | Main menu with Play/Tutorial/Pro buttons and Klappy robot  |
| `main_web.tscn`           | **Primary gameplay scene** (104KB) — all managers, UI, audio |
| `chaos_pad.tscn`          | Chaos pad mixing interface                                  |
| `soundbank.tscn`          | Sound bank/instrument selector UI                          |

### Prefab Scenes

| Scene                      | Purpose                                                   |
|----------------------------|-----------------------------------------------------------|
| `beat.tscn`               | Single clickable beat sprite (instantiated per beat)      |
| `layerButtonPrefab.tscn`  | Layer button (dynamically created per layer)              |
| `addLayerButtonPrefab.tscn`| "Add layer" button                                       |
| `blocker.tscn`            | Tutorial blocker overlay                                  |

### UI Scenes

| Scene                      | Purpose                                              |
|----------------------------|------------------------------------------------------|
| `achievements_panel.tscn` | Achievement display panel                            |
| `confirmation_prompt.tscn`| Generic confirmation dialog                          |
| `loading.tscn`            | Loading screen                                       |

### Klappy Scenes

| Scene                          | Purpose                                          |
|--------------------------------|--------------------------------------------------|
| `klappy_reaction.tscn`        | Klappy reaction trigger                          |
| `klappy_respons_bubble.tscn`  | Klappy speech bubble                             |
| `robot.tscn`                  | Klappy 3D robot model (SubViewport)              |

### Other

| Scene               | Purpose                         |
|----------------------|---------------------------------|
| `chaos_icon.tscn`   | Small chaos pad icon/button     |

### Main Scene Node Hierarchy (`main_web.tscn`)

```
Main Scene (CanvasLayer)
├── Managers
│   ├── BpmManager          → bpm.gd
│   ├── LayerManager        → layer_manager.gd
│   ├── BeatManager         → beat_manager.gd
│   ├── TemplateManager     → template_manager.gd
│   ├── GameManager         → game_manager.gd
│   ├── KeyboardInputManager → keyboard_input_manager.gd
│   ├── MixingManager       → mixing_manager.gd
│   └── AudioPlayerManager  → audio_player_manager.gd
├── UI Layer
│   ├── UIManager           → ui_manager.gd
│   ├── VisibilityManager   → visibility_manager.gd
│   ├── Colors              → colors.gd
│   ├── Layer Buttons       (dynamically spawned)
│   ├── Beat Sprites[][]    (4 rings × 16 beats)
│   ├── Template Sprites[][]
│   ├── Instrument Buttons  (×4) → instrument_button.gd
│   ├── Record Sample Buttons (×4) → record_sample_button.gd
│   ├── Settings Panel
│   ├── Progress Bar
│   └── Metronome Visualization
├── Audio
│   ├── RealTimeAudioRecording → real_time_audio_recording.gd
│   ├── SongVoiceOver       → song_voice_over_manager.gd
│   ├── LayerVoiceOver (×2) → layer_voice_over.gd (green + purple)
│   ├── RingSampleRecorder  → ring_sample_recorder.gd
│   └── MicrophoneCapture   → microphone_capture.gd
├── Visual Effects
│   ├── ParticleManager     → particle_manager.gd
│   ├── CountDown           → count_down.gd
│   └── Star Animations     → play_star_animation.gd
├── Klappy
│   ├── KlappyReaction      → klappy_reaction.gd
│   ├── KlappySoundbankScreen → Klappy_soundbank_screen.gd
│   └── ResponseBubble      → klappy_respons_bubble.gd
├── Achievements
│   ├── Achievements        → achievements.gd
│   └── Tutorial            → tutorial.gd
└── Chaos Pad
    ├── ChaosPadKnob        → ChaosPadKnob.gd
    └── SelectButtons       → layer_chaos_pad_select_button.gd
```

---

## Signal Flow & Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                         INPUT LAYER                                  │
│  KeyboardInputManager  │  BeatSprite  │  ChaosPadKnob  │  Buttons   │
│  (keyboard/touch)      │  (click)     │  (drag)        │  (press)   │
└────────────┬───────────┴──────┬───────┴───────┬────────┴─────┬──────┘
             │                  │               │              │
             ▼                  ▼               ▼              ▼
┌──────────────────────────────────────────────────────────────────────┐
│                        ★ EVENT BUS ★                                 │
│          (40+ signals — central decoupled message hub)               │
│                                                                      │
│  Playback signals    Beat signals      Layer signals                 │
│  Audio signals       Mixing signals    Recording signals             │
│  UI signals          Achievement signals  TTS signals                │
└──┬───────────┬───────────┬───────────┬───────────┬───────────┬──────┘
   │           │           │           │           │           │
   ▼           ▼           ▼           ▼           ▼           ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌──────────┐
│  BPM   │ │  Beat  │ │ Layer  │ │Template│ │ Mixing │ │  Audio   │
│Manager │ │Manager │ │Manager │ │Manager │ │Manager │ │  Player  │
│        │ │        │ │        │ │        │ │        │ │  Manager │
└───┬────┘ └───┬────┘ └───┬────┘ └───┬────┘ └───┬────┘ └────┬─────┘
    │          │          │          │          │           │
    │          │          │          │          │           │
    ▼          ▼          ▼          ▼          ▼           ▼
┌──────────────────────────────────────────────────────────────────────┐
│                        DATA LAYER                                    │
│                                                                      │
│  GameState (singleton)     LayerData ←→ RingData (×4)               │
│  - layers[]                            ├→ SynthData (×2)            │
│  - current_layer                       └→ beats[], knob_positions   │
│  - playing, bpm, beat                                                │
│  - selected_ring/synth                                               │
└──────────────────────────────────────────────────────────────────────┘
    │          │          │          │          │           │
    ▼          ▼          ▼          ▼          ▼           ▼
┌──────────────────────────────────────────────────────────────────────┐
│                       OUTPUT LAYER                                   │
│                                                                      │
│  UI Manager        │ Visibility  │ Particle   │ Audio    │ Klappy   │
│  (beat sprites,    │ Manager     │ Manager    │ Players  │ (TTS,    │
│   layer buttons,   │ (show/hide) │ (effects)  │ (sound)  │  speech  │
│   progress bar)    │             │            │          │  bubble) │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Audio Pipeline

```
Microphone Input
     │
     ▼
MicrophoneCapture ──────────────────┐
  │ (spectrum analysis)              │
  │                                  │
  ├─→ Clap detection (>7kHz)        ├─→ RingSampleRecorder
  ├─→ Stomp detection (<150Hz)      │     (record single ring sample,
  │                                  │      trim silence, auto-stop)
  │                                  │
  │                                  ├─→ VoiceRecorder
  │                                  │     (voice-over with delay,
  │                                  │      SubMaster ducking)
  │                                  │
  │                                  └─→ RealTimeAudioRecording
  │                                        (record full song output)
  │
  ▼
BeatManager                    AudioSavingManager
  │ (on_clap/on_stomp            (WAV manipulation:
  │  toggle beats)                export, trim, mix,
  │                               insert silence)
  ▼
AudioPlayerManager
  │
  ├─→ Ring Players (×4)
  │     └─ AudioStreamSynchronized (main + alt + recorded)
  │
  ├─→ Voice Players (×2) — green + purple synths
  │
  └─→ SFX Player (metronome, achievements)
```

---

## Mixing Pipeline

```
ChaosPadKnob (user drag)
     │
     ▼
ChaosPadCalculator
  │ (barycentric weights from triangle position)
  │
  ▼
MixingManager
  │
  ├─ SAMPLE_MIXING mode:
  │    weights → ring volume (main/alt/rec per ring)
  │    → AudioPlayerManager.set_ring_volume()
  │
  ├─ SYNTH_MIXING mode:
  │    weights → synth voice volume
  │    → AudioPlayerManager.set_voice_volume()
  │
  └─ SONG_MIXING mode:
       weights → overall song mix levels
       → AudioPlayerManager (combined volumes)
```

---

## C# ↔ GDScript Interop

The two C# scripts (`AudioBank.cs` and `EffectProfile.cs`) are Godot `Resource` classes decorated with `[GlobalClass]`. They are:

1. **Created** in the Godot editor as `.tres` resource files
2. **Referenced** by GDScript via `@export` properties (e.g., in `audio_player_manager.gd`)
3. **Applied** by `ApplyBankToMixer.gd` which reads the C# `EffectProfile` and calls its `Apply()` method to configure audio bus effects

This is the only bridge between C# and GDScript in the project. All game logic is in GDScript; C# is used solely for audio bank data definitions and effect application.
