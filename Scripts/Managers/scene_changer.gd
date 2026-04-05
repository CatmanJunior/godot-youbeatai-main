extends Node
## Centralised scene-transition helper.
##
## Add this as an autoload (Project → Project Settings → Globals)
## or place it in the Managers node of main.tscn.
##
## Usage (from anywhere):
##   SceneChanger.go_to("res://Scenes/main_menu.tscn")
##   SceneChanger.go_to("res://Scenes/main.tscn", { "fade": true })
##   SceneChanger.go_to_loading()   # convenience wrapper

class_name SceneChanger

# ── Scenes ──────────────────────────────────────────────────────────────────
const SCENE_MAIN_MENU  := "res://Scenes/main_menu.tscn"
const SCENE_MAIN       := "res://Scenes/main.tscn"
const SCENE_SOUNDBANK  := "res://Scenes/soundbank.tscn"
const SCENE_LOADING    := "res://Scenes/loading.tscn"


# ── Public API ───────────────────────────────────────────────────────────────

## Change to any scene by path.
## Pass `{ "fade": true }` in [param options] to trigger a fade-out first.
static func go_to(scene_path: String) -> void:
	GameState.get_tree().change_scene_to_file(scene_path)



## Convenience: go to the main menu.
static func go_to_main_menu() -> void:
	go_to(SCENE_MAIN_MENU)


## Convenience: go to the loading screen (used after soundbank selection).
static func go_to_loading() -> void:
	go_to(SCENE_LOADING)


## Convenience: go to the main game scene.
static func go_to_main() -> void:
	go_to(SCENE_MAIN)


## Convenience: go to the soundbank selection scene.
static func go_to_soundbank() -> void:
	go_to(SCENE_SOUNDBANK)

static func _on_restart_requested():
	go_to_main_menu()

	# var user_path = ProjectSettings.globalize_path("user://")
	# var files_to_reset = [
	# 	user_path + "/chosen_emoticons.json",
	# 	user_path + "/chosen_soundbank.json",
	# 	user_path + "/beats_amount.txt",
	# 	user_path + "/use_tutorial.txt",
	# 	user_path + "/use_achievements.txt"
	# ]

	# for file_path in files_to_reset:
	# 	if FileAccess.file_exists(file_path):
	# 		DirAccess.remove_absolute(file_path)

	GameState.reset()
	