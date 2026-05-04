class_name FileExporter
extends Node

func _ready():
	EventBus.export_recording_requested.connect(on_export)

func on_export(context: ExportRecordingData):
	if not context.download:
		return

	var _name = _get_file_name(context.name)
	if OS.has_feature("web"):
		download_wav_file(context.audio_stream, _name)
	else:
		export_wav_to_file(context.audio_stream, _name)   

func export_wav_to_file(stream_wav: AudioStreamWAV, _name: String = "soundtrack.wav"):
	# Save the WAV stream to a temporary file
	var documents_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	documents_path += "/Ritme Robot/%s" % _name
	print("saved to: ", documents_path)
	stream_wav.save_to_wav(documents_path)

func download_wav_file(stream_wav: AudioStreamWAV, _name: String):
	if OS.has_feature("web"):
		var temp_path = "user://temp_recording.wav"
		var error = stream_wav.save_to_wav(temp_path)
		if error == OK:
			# Read the file as a byte array (buffer)
			var file = FileAccess.open(temp_path, FileAccess.READ)
			var buffer = file.get_buffer(file.get_length())
			file.close()

			JavaScriptBridge.download_buffer(buffer, _name)
		else:
			print("Failed to save temporary file", error)
		# Convert the buffer to a base64 string (required for JavaScriptBridge)
		

func _get_file_name(_name: String) -> String:
	var date = Time.get_date_string_from_system().split("-")
	var time = Time.get_time_string_from_system().replace(":", "-")
	
	# {name} dd-mm-yyyy_HH-mm-ss.wav
	var filename = "%s %s-%s-%s_%s.wav" % [_name, date[2], date[1], date[0], time]
	return filename
