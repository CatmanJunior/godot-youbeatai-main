---
description: "Use when adding a new feature to YouBeatAI. Guides through creating a data class, EventBus signals, manager, and UI controller following the event-driven architecture."
---

# Add New Feature — YouBeatAI

Use this workflow to add **$FEATURE_NAME** to the project.

---

## Checklist

### 1. Define Data (if the feature has persistent state)

Create `Scripts/DataClasses/$FeatureName.gd`:

```gdscript
extends Resource
class_name FeatureName

@export var value: int = 0
```

Add to the relevant parent resource (e.g., `SectionData`, `SongData`) with `@export`.

### 2. Add EventBus Signals (if cross-system communication is needed)

In `Scripts/Global/event_bus.gd`, add:

```gdscript
# User action → system should do something
signal feature_action_requested(param: Type)

# System state updated → listeners should react
signal feature_state_changed(new_state: Type)
```

Convention: `_requested` for actions, `_changed` for state updates.

### 3. Implement Manager Logic

Create `Scripts/Managers/feature_manager.gd` (or extend an existing manager):

```gdscript
extends Node

func _ready() -> void:
    EventBus.feature_action_requested.connect(_on_feature_action_requested)

func _on_feature_action_requested(param: Type) -> void:
    # ... logic ...
    EventBus.feature_state_changed.emit(new_state)
```

- One responsibility per manager
- No direct references to other managers — EventBus only
- All functions and variables must have explicit types

### 4. Connect UI

Create or update a controller in `Scripts/UI/`:

```gdscript
extends Control

func _ready() -> void:
    EventBus.feature_state_changed.connect(_on_feature_state_changed)

func _on_button_pressed() -> void:
    EventBus.feature_action_requested.emit(value)

func _on_feature_state_changed(new_state: Type) -> void:
    # update visuals
```

### 5. Verify

- [ ] No direct manager-to-manager references (EventBus only)
- [ ] All functions and variables have explicit static types
- [ ] New data class extends `Resource` with `@export` properties
- [ ] Signal names follow `_requested` / `_changed` convention
- [ ] Script file named `snake_case.gd`; class files use `PascalCase.gd` + `class_name`
