# Ritme Robot / YouBeatAI

Godot 4.6 Standard project using GDScript. This is a music-creation game for Dutch children, with beat-ring sequencing and the Klappy robot companion. Keep new user-facing text consistent with the existing Dutch UI.

## Start with the relevant system

- `project.godot` defines autoloads, inputs, plugins, and the main scene. The current main scene is `Scenes/main_menu.tscn`.
- `Scripts/Global/event_bus.gd` is the central signal hub. Reuse existing signals before adding new ones.
- `Scripts/Global/game_state.gd` holds runtime state; `Scripts/Global/song_state.gd` adapts the serializable `SongData` model and some current-selection state.
- `Scripts/Managers/` owns sequencing, scene transitions, saving/loading, and other core behavior.
- `Scripts/Audio/`, `Scripts/soundfont/`, and `Scripts/DataClasses/` contain playback behavior and persistent Resource models.
- `Scripts/UI/`, `Scenes/Prefab/`, and `Scenes/UI_Components/` contain UI controllers and reusable scenes.
- `Scripts/Klappy/`, `Scripts/Global/klappy_voice.gd`, `Scripts/Global/tts_helper.gd`, and `Data/klappy_lines.csv` cover the companion and speech/dialogue flow.
- Native integrations live in `addons/fft`, `addons/godot_rtmidi`, and `addons/soundfont`. The CSV importer is `addons/csv-data-importer`.

Read the files relevant to the change. Existing code and `project.godot` are the source of truth; do not assume there is a separate style guide or architecture document.

## Conventions and constraints

- Use Godot 4.6 GDScript APIs. Use the standard engine; C#/.NET and Godot 3 examples do not apply.
- Use tabs, typed parameters/returns, and explicit variable types for new or changed code. Typed inference is fine when the type is clear. Follow surrounding file naming; this repository has mixed legacy naming.
- Use existing EventBus patterns for communication between systems. References to a controller's own child nodes/components are normal; avoid adding tight coupling between unrelated managers.
- Keep persistent song data as exported Resource properties in `Scripts/DataClasses/`. Preserve saved-resource compatibility when changing properties or types.
- Preserve scene node names, NodePaths, signal connections, resource paths, and `.gd.uid` files unless the requested change requires updating their references.
- Preserve user edits. Keep changes focused; do not reformat or rename unrelated legacy code.
- Generated `.godot/` contents and exported builds are not source. Avoid editing generated dialogue registries without checking the CSV importer/source first.
- Use `Experimental/` or old scenes only when relevant to the task. Changes to native addons, export presets, or project-wide settings should follow from the requested behavior.

## Documentation and engine tools

Two project MCP servers are configured: `godot` and `context7`.

- Use Godot MCP for `get_godot_version`, `get_project_info`, `run_project`, `get_debug_output`, and `stop_project` when useful. Pass this repository root as `projectPath`. Start, inspect, and stop a test run through the same assistant/server instance.
- For unfamiliar/version-sensitive engine APIs, use Context7. Resolve the library first and prefer `/websites/godotengine_en/4.6`, then request GDScript examples for the relevant API. Prefer links to `https://docs.godotengine.org/en/4.6/`. The unversioned `stable` docs can describe a newer engine.
- Documentation queries should contain the API question, not credentials or private project contents. If Context7 is unavailable, consult the official 4.6 docs directly.
- The installed Godot MCP server does not inspect unsaved editor state or provide screenshots. Do not report those capabilities as available.

## Verification

For changes to scripts/scenes/resources, use the existing VS Code **Godot: Import Project** task, or from this repository root on this computer:

```powershell
& 'D:\Godot 4.6\godot.exe' --headless --editor --path . --quit
```

Inspect both exit status and output for script/import errors. A zero exit code alone does not establish a clean project. Then run the affected scene/project when behavior needs checking and inspect captured errors. Stop your test run afterward.

There is no installed unit-test framework or automated test suite here; `tests/animationBlending/klappy_animation_blend.tscn` is a manual test scene. Add targeted automated tests only when suitable infrastructure is introduced as part of the task. Audio timing, microphone/MIDI input, TTS, and exported-web behavior need appropriate manual checks; a headless import does not verify them.

Report changed behavior, verification performed, and anything still requiring a manual check. Reusable feature/debug/review/docs recipes are in `.github/prompts/`; read only the relevant recipe when useful. Let one assistant own a set of edits or a play session at a time.
