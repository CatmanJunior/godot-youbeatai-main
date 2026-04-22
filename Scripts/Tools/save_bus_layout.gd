@tool
extends EditorScript

func _run() -> void:
    var layout = AudioServer.generate_bus_layout()
    var path = "res://current_bus_layout.tres"
    var result = ResourceSaver.save(layout, path)
    #print all bus names and their sends for debugging
    for i in range(AudioServer.bus_count):
        var bus_name = AudioServer.get_bus_name(i)
        var send_to = AudioServer.get_bus_send(i)
        print("Bus %d: %s, sends to: %s" % [i, bus_name, send_to])
    

    if result == OK:
        print("Audio bus layout saved to: %s" % path)
    else:
        push_error("Failed to save audio bus layout. Error code: %d" % result)