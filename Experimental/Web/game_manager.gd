extends Node


var time: float = 0.0

signal on_utterance_end(utterance_id: int)

func _exit_tree():
	# $Achievements.reset()
	pass

func _ready():
	# Setup
	%"LayerManager".spawn_initial_layer_buttons()
	%BpmManager.on_beat_event.connect(on_beat)
	# $Tutorial.check_if_tutorial_was_chosen()
	# $Achievements.check_if_achievements_mode_should_be_active()
	read_json_from_previous_scene_and_set_values()
	%AudioPlayerManager.init_all_audio_players()
	%UiManager.init_button_actions()
	%UiManager.sprite_placement()
	# $Tutorial.setup_tutorial()
	
	call_deferred("deferred_setup")
	
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, utterance_end)
	print(ProjectSettings.globalize_path("user://"))

func deferred_setup():
	%MixingManager.samples_mixing_re_apply_remembered_volumes()
	%MixingManager.synth_mixing_re_apply_remembered_volumes()
	# %Achievements.on_ready()
	%MixingManager.on_ready_mixing()
	%UiManager.update_layer_buttons_delayed()

func utterance_end(utterance_id: int):
	on_utterance_end.emit(utterance_id)

func _process(delta: float):
	time += delta
	# %VisualEffects.update_effects(delta)
	# %AudioPlayerManager.update_audio(delta)
	# %MixingManager.on_update_mixing(delta)
	# %LayerManager.update_layers(delta)
	# $Tutorial.update_tutorial()
	# $Achievements.on_update()

func on_beat(_beat: int):
	# %VisualEffects.on_beat()
	%LayerManager.on_beat()

func tutorialActivated() -> bool:
	# return $Tutorial.tutorial_activated
	return false

func read_json_from_previous_scene_and_set_values():
	# Implementation here
	pass
