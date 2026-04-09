@tool
extends EditorScript

func _run() -> void:
    var layout = AudioServer.generate_bus_layout()
    var path = "res://current_bus_layout.tres"
    var result = ResourceSaver.save(layout, path)
    
    if result == OK:
        print("Audio bus layout saved to: %s" % path)
    else:
        push_error("Failed to save audio bus layout. Error code: %d" % result)