# 📏 YouBeatAI Style Guide

Code conventions and best practices for the YouBeatAI (Ritme Robot) Godot 4.6 project.

---

## Table of Contents

- [GDScript Conventions](#gdscript-conventions)
- [Naming Conventions](#naming-conventions)
- [File & Directory Layout](#file--directory-layout)
- [Signals & EventBus](#signals--eventbus)
- [State Management](#state-management)
- [Data Classes](#data-classes)
- [Scene & Node Guidelines](#scene--node-guidelines)
- [Audio System](#audio-system)
- [Comments & Documentation](#comments--documentation)
- [Error Handling](#error-handling)
- [Testing](#testing)

---

## GDScript Conventions

### General

- **Godot version:** 4.6 with GDScript (not C#)
- Use **static typing** wherever possible — annotate function parameters, return types, and variables:
  ```gdscript
  func get_section(index: int) -> SectionData:
  var sections: Array[SectionData] = []
  var bpm: int = 120
  ```
- Use **`:=`** for type-inferred declarations when the type is obvious from the right-hand side:
  ```gdscript
  var copy := SynthTrackData.new(index, knob_position)
  var bus_idx := AudioServer.get_bus_index(bus_name)
  ```
- Use `const` for values that never change:
  ```gdscript
  const BEATS_AMOUNT_DEFAULT: int = 16
  const SILENT_DB: float = -80.0
  ```

### Indentation & Formatting

- Use **tabs** for indentation (Godot default)
- One blank line between functions
- Use section comment headers to organize large files:
  ```gdscript
  # ── Playback ──────────────────────────────────────────────────────────
  # ── Recording ─────────────────────────────────────────────────────────
  ```

### Functions

- Prefer short, focused functions with a single responsibility
- Private/internal functions are prefixed with `_`:
  ```gdscript
  func _get_swing_offset() -> float:
  func _on_beat_triggered(beat: int) -> void:
  ```
- Signal callback methods use the `_on_<signal_name>` pattern:
  ```gdscript
  func _on_section_switched(section: SectionData) -> void:
  func _on_recording_stopped(audio: AudioStream) -> void:
  ```

### Properties

- Use Godot's `get`/`set` syntax for computed or delegated properties:
  ```gdscript
  var bpm: int:
      get: return data.bpm
      set(value): data.bpm = value
  ```

---

## Naming Conventions

### Files

| Type | Convention | Example |
|------|-----------|---------|
| Regular scripts | `snake_case.gd` | `beat_manager.gd`, `section_data.gd` |
| Class scripts (with `class_name`) | `PascalCase.gd` | `SampleTrackPlayer.gd`, `ChaosPadCalculator.gd` |
| Scenes | `snake_case.tscn` | `main.tscn`, `beat_ring_pivot_point.tscn` |
| Prefab scenes | `PascalCase.tscn` | `BeatButton.tscn`, `Klappy.tscn` |
| Resources | `snake_case.tres` | `runtime_bus_layout.tres` |
| UID files | `<matching_script>.gd.uid` | `beat_manager.gd.uid` |

### Variables & Properties

| Type | Convention | Example |
|------|-----------|---------|
| Local variables | `snake_case` | `beat_elapsed`, `current_beat` |
| Private variables | `_snake_case` | `_weights`, `_has_recording`, `_sequence` |
| Constants | `UPPER_SNAKE_CASE` | `TRACK_COUNT`, `SILENT_DB`, `MAX_FFT_SIZE` |
| Exported vars | `snake_case` | `@export var bus_name: String` |
| Enums | `PascalCase` name, `UPPER_SNAKE_CASE` values | `enum State { NOT_STARTED, RECORDING }` |
| Booleans | Prefix with `is_`, `has_`, or verb form | `is_recording`, `has_active_beats`, `playing` |

### Functions

| Type | Convention | Example |
|------|-----------|---------|
| Public methods | `snake_case` | `switch_section()`, `play_note()` |
| Private methods | `_snake_case` | `_get_swing_offset()`, `_compute_magnitudes()` |
| Signal handlers | `_on_<signal_name>` | `_on_beat_triggered()`, `_on_section_switched()` |
| Static utility methods | `snake_case` | `ChaosPadCalculator.calc_weights()` |

### Signals (in EventBus)

Signals follow a consistent verb-based pattern:

| Pattern | When to use | Example |
|---------|------------|---------|
| `<noun>_<verb>ed` | Past tense — something happened | `beat_triggered`, `section_switched`, `recording_stopped` |
| `<noun>_<verb>_requested` | Request — asking a manager to do something | `section_switch_requested`, `bpm_set_requested`, `start_recording_requested` |
| `<noun>_changed` | State change notification | `playing_changed`, `bpm_changed` |
| `<noun>_toggled` | Toggle events | `recording_sample_button_toggled` |

### Class Names

- Use `PascalCase` for `class_name` declarations
- Data classes end with `Data`: `SectionData`, `TrackData`, `SongData`
- Player classes end with `Player`: `SampleTrackPlayer`, `NotePlayer`
- Manager classes don't need a suffix — just describe their domain: `SectionManager`, `BeatManager`
- Helper/utility classes end with `Helper` or describe their function: `BusHelper`, `AudioHelpers`, `TTSHelper`, `ChaosPadCalculator`

---

## File & Directory Layout

### Where to put new files

| What you're adding | Where it goes |
|-------------------|---------------|
| New autoload singleton | `Scripts/Global/` — also register in `project.godot` |
| New manager (game logic) | `Scripts/Managers/` |
| New UI controller | `Scripts/UI/` |
| New button script | `Scripts/UI/Buttons/` |
| New data class (Resource) | `Scripts/DataClasses/` |
| New audio utility | `Scripts/Audio/` |
| New track player type | `Scripts/Audio/AudioPlayerClasses/` |
| New scene component | `Scenes/UI_Components/` or `Scenes/Prefab/` |
| New Klappy behavior | `Scripts/Klappy/` |

### Deprecated directories

- **`Scenes/Work_in_progress_scenes/`** — Will be deleted. Do not add new scenes here.
- **`Experimental/`** — Contains prototype code that will mostly be removed. Do not build on top of these.
- **`Scenes/OLD/`** — Legacy scenes scheduled for cleanup.

---

## Signals & EventBus

### Rules

1. **All signals must be defined in `Scripts/Global/event_bus.gd`** — never define signals on individual managers or scripts for cross-system communication.
2. **Every signal must have a `##` doc comment** explaining when it is emitted:
   ```gdscript
   ## Emitted when the BPM value has changed.
   signal bpm_changed(new_bpm: float)
   ```
3. **Use typed parameters** in signal declarations:
   ```gdscript
   signal section_switched(section_data: SectionData)
   signal mixing_weights_changed(track_index: int, weights: Vector3)
   ```
4. **Organize signals by category** using section comments:
   ```gdscript
   # ── Playback ──
   # ── Beat State ──
   # ── Sections ──
   # ── Recording ──
   ```
5. **Use the `_requested` suffix** for signals that ask a manager to perform an action.
   Use past-tense for signals that announce something has already happened.

### Connection pattern

Connect to EventBus signals in `_ready()`:
```gdscript
func _ready() -> void:
    EventBus.section_switch_requested.connect(switch_section)
    EventBus.copy_requested.connect(_copy_section)
```

For simple one-liner handlers, inline lambdas are acceptable:
```gdscript
EventBus.bpm_up_requested.connect(func(value): bpm += value)
EventBus.track_selected.connect(func(track: int): selected_track_index = track)
```

---

## State Management

### Where state belongs

| State type | Where | Examples |
|-----------|-------|---------|
| Song structure (persisted) | `SongState.data` (a `SongData` resource) | sections, bpm, swing, total_beats |
| Runtime playback | `GameState` | playing, current_beat, beat_progress, is_recording |
| User settings | `GameState` | microphone_volume, metronome_enabled, mute_speech |
| Current section pointer | `SongState` (runtime-only) | current_section, selected_track_index |
| Per-section track data | `SectionData.tracks[]` | beats, knob_position, recorded audio |
| Song-level track | `SongState.song_track` (`SongTrackData`) | voice-over, master recording |

### Rules

- **Never store state in UI nodes.** UI reads state from `GameState`/`SongState` and emits signals to request changes.
- **Managers update state through signals**, not by directly modifying other managers' properties.
- **Runtime-only state** (not saved to disk) lives on `SongState` or `GameState`, not on `SongData`.

---

## Data Classes

### Rules

1. **Extend `Resource`** so Godot can serialize the data:
   ```gdscript
   class_name SectionData
   extends Resource
   ```
2. **Use `@export`** for all fields that should be saved:
   ```gdscript
   @export var beats: Array[bool] = []
   @export var main_audio_stream: AudioStream = null
   ```
3. **Runtime-only fields** are plain `var` (not exported):
   ```gdscript
   var _sequence: Sequence = null
   var recording_data: RecordingData = null
   ```
4. Provide a **`duplicate_track()` / `duplicate_section()`** method for deep copies.
5. Provide a **`rebuild_runtime()`** method for restoring runtime state after loading from disk.
6. **No scene tree dependencies** — data classes must not call `get_node()`, `get_tree()`, or reference autoloads in their constructor.

---

## Scene & Node Guidelines

- Use **`%UniqueNode`** names sparingly — prefer `@export` for explicit scene-tree references:
  ```gdscript
  @export var waveform_visualizer: TrackWaveformVisualizer
  ```
- Keep scenes shallow — extract reusable parts into prefab scenes under `Scenes/Prefab/` or `Scenes/UI_Components/`.
- Scene scripts should live alongside their script dependencies in the appropriate `Scripts/` subdirectory, not next to the `.tscn` file (unless it's a very simple inline script).

---

## Audio System

### Track types

| Type | Count | Sub-players | Notes |
|------|-------|-------------|-------|
| `SampleTrackPlayer` | 4 | Main, Alt, Rec | Beat-triggered drum/percussion |
| `SynthTrackPlayer` | 2 | Alt, NotePlayer, Recording | Voice-to-synth (threaded voice processing) |
| `SongTrackPlayer` | 1 | — | Full-song voice-over + master bus recording |

### Bus naming

Buses are created dynamically with deterministic names:
- Track bus: `<Prefix><Index>` → `Sample0`, `Synth4`
- Sub-buses: `<Prefix><Index>_<Suffix>` → `Sample0_Main`, `Synth4_NotePlayer`

### Volume & mixing

- Use `BusHelper` static methods for all bus operations: `create_bus()`, `set_volume()`, `crossfade3()`
- Never call `AudioServer` directly from managers or UI — go through `BusHelper`.

---

## Comments & Documentation

### Doc comments

- Use `##` for class and member documentation (Godot doc comments):
  ```gdscript
  ## Data class representing a single section.
  ## Contains sample tracks, synth tracks, and the button emoji.
  class_name SectionData
  extends Resource
  ```
- Document all exported properties and public functions:
  ```gdscript
  ## Duration of one beat subdivision in seconds.
  var beat_duration: float = 0.5
  ```

### Inline comments

- Use `#` for inline comments, but prefer self-documenting code
- Use `# ── Section Header ──` dividers to organize large files into logical sections
- Avoid commenting obvious code; comment *why*, not *what*

### Warnings

- Use `@warning_ignore("unused_signal")` or similar annotations when suppression is intentional
- Prefer fixing warnings over suppressing them

---

## Error Handling

- Use `push_error()` for unrecoverable problems (missing resources, invalid state):
  ```gdscript
  push_error("Bus '%s' not found for applying effect profile." % bus_name)
  ```
- Use `push_warning()` for recoverable or expected edge cases:
  ```gdscript
  push_warning("MicrophoneRecorder: no AudioEffectRecord found on %s bus" % bus_name)
  ```
- Use `printerr()` for input validation errors in utility functions:
  ```gdscript
  printerr("crossfade3 requires exactly 3 bus names")
  ```
- Use `assert()` for debug-only invariant checks:
  ```gdscript
  assert(analyzer != null, "Could not find analyzer on bus: " + bus_name)
  ```
- **Never silently swallow errors.** Always log something when an unexpected state is encountered.

---

## Testing

- Place test scenes in `tests/` directory
- Tests can use `EventBus` signals to trigger actions and verify state through `GameState`/`SongState`
- Keep tests independent — each test should set up its own state via `GameState.reset()` / `SongState.reset()`
- Name test files with a `test_` prefix: `test_section_shuffle.gd`
