class_name EmailExporter
extends Node

var http_request: HTTPRequest = HTTPRequest.new()

func _ready() -> void:
    add_child(http_request)
    http_request.request_completed.connect(_on_request_completed)

    EventBus.export_recording_requested.connect(exportByMail)

func exportByMail(context: ExportRecordingData):
    if not context.email:
        return

    var temp_path = "user://temp_recording.wav"
    var error = context.audio_stream.save_to_wav(temp_path)
    if error == OK:
        _send_file_to_api(_get_file_name(context.name), "https://ritme-robot-web-app-qra6j.ondigitalocean.app/api/send_to_user", GameState.export_mail)
    else:
        print("Failed to save temporary file", error)

func _construct_multipart_form(file_path: String, field_name: String = "file", content_type: String = "application/octet-stream") -> Dictionary:
    var file = FileAccess.open("user://temp_recording.wav", FileAccess.READ)
    if file == null:
        push_error("Failed to open file: %s" % "user://temp_recording.wav")
        return {
            "body": PackedByteArray(),
            "headers": [],
            "boundary": ""
        }

    var file_data: PackedByteArray = file.get_buffer(file.get_length())
    file.close()

    var boundary: String = "----GodotFormBoundary" + str(randi())
    var body: PackedByteArray = PackedByteArray()

    body += ("--%s\r\n" % boundary).to_utf8_buffer()
    body += ("Content-Disposition: form-data; name=\"%s\"; filename=\"%s\"\r\n" % [field_name, file_path]).to_utf8_buffer()
    body += ("Content-Type: %s\r\n\r\n" % content_type).to_utf8_buffer()
    body.append_array(file_data)
    body += "\r\n".to_utf8_buffer()
    body += ("--%s--\r\n" % boundary).to_utf8_buffer()

    var headers: PackedStringArray = PackedStringArray()
    headers.append("Content-Type: multipart/form-data; boundary=%s" % boundary)
    headers.append("Content-Length: %d" % body.size())

    return {
        "body": body,
        "headers": headers,
        "boundary": boundary
    }

func _send_file_to_api(file_path: String, api_url: String, user_email: String) -> void:
    var encoded_email: String = user_email.uri_encode()
    var url_with_query: String = "%s?to=%s" % [api_url, encoded_email]
    var form_data: Dictionary = _construct_multipart_form(file_path)
    var request_error: int = http_request.request_raw(
        url_with_query,
        form_data["headers"],
        HTTPClient.METHOD_POST, 
        form_data["body"]
    )
    if request_error != OK:
        push_error("HTTPRequest failed: %d" % request_error)

func _on_request_completed(_result: int, response_code: int, _headers: Array, body: PackedByteArray) -> void:
    if response_code == 200:
        print("File uploaded successfully!")
        print("Response: ", body.get_string_from_utf8())
    else:
        print("Error uploading file. Response code: ", response_code)
        print("Response: ", body.get_string_from_utf8())

func _get_file_name(_name: String) -> String:
    var date = Time.get_date_string_from_system().split("-")
    var bpm = "%sbpm" % SongState.bpm
    # {name} dd-mm-yyyy_HH-mm-ss.wav
    var filename = "%s %s-%s-%s_%s.wav" % [_name, date[2], date[1], date[0], bpm]
    return filename