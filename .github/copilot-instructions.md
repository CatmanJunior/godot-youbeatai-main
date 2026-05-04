---
name: YouBeatAI Workspace
description: "Godot 4.6 music-creation game for children. Event-driven architecture with EventBus, static typing, and serializable data classes. Refer to STYLE_GUIDE.md and Ritme Robot Architecture.md for expanded conventions."
---

# YouBeatAI Workspace Instructions

**Project:** YouBeatAI / Ritme Robot — A Godot 4.6 music-creation app for Dutch children (~10 years old). Drum loops with a beat-ring UI and an AI robot companion (Klappy).

**Full Conventions:** [STYLE_GUIDE.md](../STYLE_GUIDE.md) | [Ritme Robot Architecture.md](../Ritme%20Robot%20Architecture.md)

---

## Quick Facts

| Aspect | Detail |
|--------|--------|
| **Engine** | Godot 4.6 with GDScript (not C#) |
| **Architecture** | Pure event-driven via `EventBus` autoload |
| **Typing** | Static typing mandatory (`func foo(x: int) -> String`) |
| **Indentation** | Tabs (Godot default) |
| **Main Scene** | `Scenes/main_menu.tscn` |
| **Save Path** | `user://songs/last_save.tres` |

---

## Architecture

### Autoloads (Singletons)

| Name | Path | Purpose |
|------|------|---------|
| `EventBus` | `Scripts/Global/event_bus.gd` | Central signal hub (60+ signals) |
| `GameState` | `Scripts/Global/game_state.gd` | Runtime state (`playing`, `current_beat`, `is_recording`) |
| `SongState` | `Scripts/Global/song_state.gd` | Persistent song model (wraps `SongData` resource) |
| `FFT` | `addons/fft/Fft.gd` | Spectrum analysis |

### GameState vs SongState

- **`GameState`** — Ephemeral runtime: `playing`, `current_beat`, `beat_progress`, `is_recording`, `microphone_volume`, user settings
- **`SongState`** — On-disk model: wraps `SongData` resource; delegates `sections`, `bpm`, `total_beats`, `swing`, `song_track`

### Event-Driven Communication

All inter-system communication flows through `EventBus`. **No direct manager references.** Full signal list: [Scripts/Global/event_bus.gd](../Scripts/Global/event_bus.gd)

```gdscript
# ✅ DO: Signal-based
EventBus.section_switched.emit(new_section)

# ❌ DON'T: Direct coupling
section_manager.switch_to(new_section)
```

### Data Classes

All persistent data in `Scripts/DataClasses/` extends `Resource` with `@export` properties. Hierarchy: `SongData` → `SectionData[]` → `TrackData` → `SampleTrackData` / `SynthTrackData`

---

## Naming & File Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Regular scripts | `snake_case.gd` | `beat_manager.gd` |
| Class files | `PascalCase.gd` + `class_name` | `SampleTrackPlayer.gd` |
| Scene instances | `snake_case.tscn` | `main_menu.tscn` |
| Prefab scenes | `PascalCase.tscn` in `Scenes/Prefab/` | `BeatButton.tscn` |
| Resources | `snake_case.tres` | `runtime_bus_layout.tres` |

---

## Key Directories

| Path | Purpose |
|------|---------|
| `Scripts/Global/` | Autoload singletons + `tts_helper.gd` |
| `Scripts/Managers/` | Core game logic (beat, sections, save/load, soundbank) |
| `Scripts/Audio/` | Playback, recording, buses, waveform visualization |
| `Scripts/DataClasses/` | Serializable resource models |
| `Scripts/UI/` | Visual controllers and buttons |
| `Scripts/Klappy/` | AI robot companion logic |
| `Scripts/Tutorial/` | Tutorial and achievement system |
| `Scenes/Prefab/` | Reusable scene prefabs |

**Avoid:** `Scenes/Work_in_progress_scenes/`, `Experimental/`, `Scenes/OLD/`

---

## Adding a New Feature

1. **Data** → Create class in `Scripts/DataClasses/` extending `Resource` with `@export` vars
2. **Signals** → Add to `Scripts/Global/event_bus.gd` (`_requested` for actions, `_changed` for state updates)
3. **Logic** → New/extended manager in `Scripts/Managers/`
4. **UI** → Controller in `Scripts/UI/` that emits `_requested` and listens to `_changed`
5. **Wire** → Connect only via `EventBus` signals in `_ready()`

---

## Common Tasks

- **New track type setting:** `Scripts/TrackSettingsRes/` → register in `Scripts/Managers/track_settings_registry.gd` → emit `EventBus.track_settings_changed`
- **Beat ring behavior:** `Scripts/Managers/beat_manager.gd` → `EventBus.beat_triggered`
- **Audio effect:** `Scripts/Audio/AudioBanks/` → `SoundBankMatrix` resource → `EffectProfile`
- **Scene transition:** Use `Scripts/Managers/scene_changer.gd`
- **Save/Load song:** `Scripts/Managers/song_save_load_manager.gd` via `EventBus.save_song_requested` / `EventBus.load_song_requested`

---

## Key Insights

1. **No direct coupling** — All systems talk via EventBus signals
2. **Static typing everywhere** — Catch errors at edit-time, not runtime
3. **Managers are encapsulated** — Each has one job, one EventBus connection point
4. **Data is serializable** — Everything extends `Resource` for save/load
5. **Runtime vs persistent** — `GameState` ephemeral, `SongState` on-disk
6. **Signal naming** — Listeners follow `_on_<signal_name>` pattern; use `_requested`/`_changed` suffixes
7. **Tab indentation** — Godot default; don't mix spaces
