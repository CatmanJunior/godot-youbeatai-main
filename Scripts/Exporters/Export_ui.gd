class_name ExportUI
extends Node

@export var loading: LoadingContainer
@export var started: bool = false

func _ready() -> void:
	EventBus.export_requested.connect(export_started)
	EventBus.export_recording_requested.connect(export_ended)
	EventBus.export_progress_update.connect(update_progress)
	EventBus.export_failed.connect(_on_export_failed)

func _on_export_failed(_message: String) -> void:
	loading.close()
	started = false

func update_progress(progress: float) -> void:
	loading.set_progress(progress)

func export_started(_mail: bool, _mode: bool) -> void:
	loading.open()
	started = true

func export_ended(_data: ExportRecordingData) -> void:
	loading.close()
	started = false