extends Node

func _ready():
    await get_tree().process_frame
    EventBus.level_loaded.emit()
    
    await get_tree().process_frame
    EventBus.post_ready.emit()