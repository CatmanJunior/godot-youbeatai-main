extends Node

# Audio saving and manipulation manager
# Note: This is a simplified GDScript version. Some functionality requires
# additional audio processing libraries or Godot plugins

# File paths
var user_path: String

func _ready():
	user_path = ProjectSettings.globalize_path("user://")

func save_realtime_recorded_song_as_file_and_send_to_email(email: String = "") -> String:
	"""Save the real-time recorded song and optionally send to email"""
	var path = save_realtime_recorded_song_as_file()
	if path and email != "":
		send_to_email(path, email)
	return path

func save_realtime_recorded_beat_as_file_and_send_to_email(email: String = "") -> String:
	"""Save the current beat/layer recording and optionally send to email"""
	var path = save_realtime_recorded_beat_as_file()
	if path and email != "":
		send_to_email(path, email)
	return path

func save_realtime_recorded_song_as_file() -> String:
	"""Save the full song recording to a WAV file"""
	# Get references to recording instances
	var realtime_recording = get_node_or_null("/root/RealTimeAudioRecording")
	var song_voiceover = get_node_or_null("/root/SongVoiceOver")
	
	if not realtime_recording or not realtime_recording.has("recording_result"):
		return ""
	
	var sanitized_time = Time.get_time_string_from_system().replace(":", "_")
	var bpm = get_bpm()
	var final_name = user_path + "/export_" + str(bpm) + "bpm_" + sanitized_time
	
	# Note: In GDScript, we would need to:
	# 1. Export the AudioStreamWAV to a file
	# 2. Mix multiple audio streams together
	# This requires either custom audio processing or a plugin
	
	print("Audio saving functionality requires additional implementation")
	print("Would save to: " + final_name + ".wav")
	
	# Placeholder for actual implementation
	# save_audio_stream_to_wav(realtime_recording.recording_result, final_name + "_a.wav")
	# save_audio_stream_to_wav(song_voiceover.voice_over, final_name + "_b.wav")
	# mix_audio_files(final_name + "_a.wav", final_name + "_b.wav", final_name + ".wav")
	
	return final_name + ".wav"

func save_realtime_recorded_beat_as_file() -> String:
	"""Save the current layer/beat to a WAV file"""
	var realtime_recording = get_node_or_null("/root/RealTimeAudioRecording")
	var song_voiceover = get_node_or_null("/root/SongVoiceOver")
	
	if not realtime_recording or not realtime_recording.has("recording_result"):
		return ""
	
	var sanitized_time = Time.get_time_string_from_system().replace(":", "_")
	var bpm = get_bpm()
	var final_name = user_path + "/export_" + str(bpm) + "bpm_" + sanitized_time
	
	# Calculate time per layer
	var beats_amount = get_beats_amount()
	var base_time_per_beat = get_base_time_per_beat()
	var time_per_layer = beats_amount * base_time_per_beat
	
	var current_layer_index = get_current_layer_index()
	var start_time = current_layer_index * time_per_layer
	var end_time = start_time + time_per_layer
	
	print("Would trim audio from " + str(start_time) + " to " + str(end_time))
	
	return final_name + ".wav"

func remove_layer_part_of_recordings(layer: int):
	"""Remove a layer's audio from the recording"""
	var sanitized_time = Time.get_time_string_from_system().replace(":", "_")
	
	var beats_amount = get_beats_amount()
	var base_time_per_beat = get_base_time_per_beat()
	var time_per_layer = beats_amount * base_time_per_beat
	
	var start_time = layer * time_per_layer
	var end_time = start_time + time_per_layer
	
	print("Would remove layer " + str(layer) + " from recordings (" + str(start_time) + " to " + str(end_time) + ")")
	
	# This would involve:
	# 1. Converting AudioStream to WAV file
	# 2. Removing the segment from start_time to end_time
	# 3. Converting back to AudioStream

func insert_silent_layer_part_of_recordings(layer: int):
	"""Insert silence for a new layer in the recording"""
	var sanitized_time = Time.get_time_string_from_system().replace(":", "_")
	
	var beats_amount = get_beats_amount()
	var base_time_per_beat = get_base_time_per_beat()
	var time_per_layer = beats_amount * base_time_per_beat
	
	var insert_time = layer * time_per_layer
	
	print("Would insert " + str(time_per_layer) + " seconds of silence at " + str(insert_time))
	
	# This would involve:
	# 1. Converting AudioStream to WAV file
	# 2. Inserting silence at insert_time
	# 3. Converting back to AudioStream

func send_to_email(file_path: String, email: String):
	"""Send the audio file to an email address"""
	print("Would send " + file_path + " to " + email)
	# This would require email functionality (SMTP, API, etc.)

# Audio file manipulation functions (require implementation)
# These would need to use Godot's audio APIs or external libraries

func save_audio_stream_to_wav(stream: AudioStream, path: String):
	"""Save an AudioStream to a WAV file"""
	if not stream:
		return
	
	if stream is AudioStreamWAV:
		# AudioStreamWAV can be saved using .save_to_wav()
		var error = stream.save_to_wav(path)
		if error != OK:
			print("Error saving WAV file: " + str(error))
	else:
		print("Cannot save non-WAV AudioStream directly")

func mix_audio_files(file1: String, file2: String, output: String):
	"""Mix two audio files together"""
	# This requires custom audio processing
	# Could use AudioStreamGenerator or external tools
	print("Would mix " + file1 + " and " + file2 + " into " + output)

func trim_wav_file(input_path: String, output_path: String, start_time: float, end_time: float):
	"""Trim a WAV file to a specific time range"""
	# This requires reading, processing, and writing WAV data
	print("Would trim " + input_path + " from " + str(start_time) + " to " + str(end_time))

func remove_segment_from_wav(input_path: String, output_path: String, start_time: float, end_time: float):
	"""Remove a segment from a WAV file"""
	# This requires reading, processing, and writing WAV data
	print("Would remove segment from " + input_path + " (" + str(start_time) + " to " + str(end_time) + ")")

func insert_silence_into_wav(input_path: String, output_path: String, insert_time: float, duration: float):
	"""Insert silence into a WAV file"""
	# This requires reading, processing, and writing WAV data  
	print("Would insert " + str(duration) + "s silence into " + input_path + " at " + str(insert_time))

func combine_wav_files(file1: String, file2: String, output: String):
	"""Combine two WAV files sequentially"""
	# This requires reading, processing, and writing WAV data
	print("Would combine " + file1 + " and " + file2 + " into " + output)

# Helper functions to get data from other managers
func get_bpm() -> int:
	var bpm_manager = get_node_or_null("/root/BpmManager")
	if bpm_manager and bpm_manager.has("bpm"):
		return bpm_manager.bpm
	return 120

func get_beats_amount() -> int:
	var bpm_manager = get_node_or_null("/root/BpmManager")
	if bpm_manager and bpm_manager.has("beats_amount"):
		return bpm_manager.beats_amount
	return 16

func get_base_time_per_beat() -> float:
	var bpm_manager = get_node_or_null("/root/BpmManager")
	if bpm_manager and bpm_manager.has("base_time_per_beat"):
		return bpm_manager.base_time_per_beat
	return 60.0 / get_bpm()

func get_current_layer_index() -> int:
	var layer_manager = get_node_or_null("../LayerManager")
	if layer_manager and layer_manager.has("current_layer_index"):
		return layer_manager.current_layer_index
	return 0
