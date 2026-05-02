---
description: "Use when writing or editing GDScript (.gd) files in YouBeatAI. Enforces static typing, EventBus-only coupling, naming conventions, and code organization rules."
applyTo: "**/*.gd"
---

# GDScript Conventions — YouBeatAI

Full reference: [STYLE_GUIDE.md](../../STYLE_GUIDE.md)

## Static Typing (Mandatory)

```gdscript
# ✅ Explicit types on ALL functions and variables
func get_section(index: int) -> SectionData:
    var count: int = sections.size()
    return sections[index]

# Use := only when the type is obvious from the right-hand side
var player := SampleTrackPlayer.new()
var bus_idx := AudioServer.get_bus_index("Master")

# ❌ Never use implicit types
func get_section(index):
    var count = sections.size()
```

## Function Naming

| Pattern | Example |
|---------|---------|
| Public | `func play_beat() -> void:` |
| Private | `func _calculate_swing() -> float:` |
| Signal callback | `func _on_beat_triggered(beat: int) -> void:` |

## EventBus — No Direct Coupling

```gdscript
# ✅ Always emit/connect via EventBus
EventBus.section_switched.emit(new_section)

func _ready() -> void:
    EventBus.beat_triggered.connect(_on_beat_triggered)

# ❌ Never reference another manager/node directly
section_manager.switch_to(new_section)
```

Signal naming: `_requested` for actions the system should perform, `_changed` for state updates.

## Data Classes

Persistent data always extends `Resource` with `@export` properties:

```gdscript
extends Resource
class_name MyData

@export var value: int = 0
@export var label: String = ""
```

Place in `Scripts/DataClasses/`. Use `PascalCase.gd` with a `class_name` declaration.

## Properties

Use Godot getters/setters for computed or delegated values:

```gdscript
var bpm: int:
    get: return _data.bpm
    set(value): _data.bpm = value
```

## File Organization (large files)

Group related functions under section headers:

```gdscript
# ── Playback ──────────────────────────────────────────────────────────

func play() -> void:
    pass

# ── Recording ─────────────────────────────────────────────────────────

func start_recording() -> void:
    pass
```

## File Naming

| Type | Convention |
|------|-----------|
| Regular scripts | `snake_case.gd` |
| Scripts with `class_name` | `PascalCase.gd` |
