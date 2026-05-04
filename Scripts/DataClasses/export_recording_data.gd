extends RecordingData
class_name ExportRecordingData

@export var email := false
@export var download := false
@export var email_address := ""
@export var name := ""

@export var song_mode := false

func _init():
    super._init(null)