extends Node


var time: float = 0.0

var first_tts_done: bool = false

func _exit_tree():
	# $Achievements.reset()
	pass

func _ready():
	# Setup
	read_json_from_previous_scene_and_set_values()


	call_deferred("deferred_setup")
	
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, utterance_end)
	print(ProjectSettings.globalize_path("user://"))

func deferred_setup():
	%MixingManager.samples_mixing_re_apply_remembered_volumes()
	%MixingManager.synth_mixing_re_apply_remembered_volumes()
	# %Achievements.on_ready()
	%UiManager.update_layer_buttons_delayed()

func utterance_end(utterance_id: int):
	EventBus.utterance_ended.emit(utterance_id)


func text_without_emoticons(text: String) -> String:
	var emoticon_pattern = r"(:\)|:\(|:D|:P|;\)|<3|:\*|:\|)"
	var regex = RegEx.new()
	regex.compile(emoticon_pattern)
	return regex.sub(text, "")

func show_countdown():
	EventBus.countdown_show_requested.emit()

func _process(delta: float):
	time += delta
	# %VisualEffects.update_effects(delta)
	# %AudioPlayerManager.update_audio(delta)
	# %MixingManager.on_update_mixing(delta)
	# %LayerManager.update_layers(delta)
	# $Tutorial.update_tutorial()
	# $Achievements.on_update()

# Beat events now flow through EventBus — no need for game_manager to forward them
# func on_beat(_beat: int):
# 	%LayerManager.on_beat()

func tutorialActivated() -> bool:
	# return $Tutorial.tutorial_activated
	return false

func read_json_from_previous_scene_and_set_values():
	# Implementation here
	pass
