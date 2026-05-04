class_name ExportUI
extends Node

@export var loading: LoadingContainer
@export var started: bool = false

func _ready():
    EventBus.export_requested.connect(export_started)
    EventBus.export_recording_requested.connect(export_ended)
    EventBus.export_progress_update.connect(update_progress)

func update_progress(progress: float):
    loading.set_progress( progress) 

func export_started(_mail: bool, _mode: bool):
    loading.open()
    started = true

func export_ended(_data: ExportRecordingData):
    loading.close()
    started = false