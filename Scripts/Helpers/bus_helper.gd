class_name BusHelper

const SILENT_DB : float = -80.0

static func save_layout() -> void:
    var layout = AudioServer.generate_bus_layout()
    var path = "user://runtime_bus_layout.tres"
    var result = ResourceSaver.save(layout, path)

    if result == OK:
        print("Runtime bus layout saved to: %s" % path)
        print("Full path: %s" % ProjectSettings.globalize_path(path))
    else:
        push_error("Failed to save layout. Error: %d" % result)

static func create_bus(bus_name: String, send_to: String) -> int:
    var existing := AudioServer.get_bus_index(bus_name)
    if existing != -1:
        return existing

    AudioServer.add_bus()
    var idx := AudioServer.bus_count - 1
    AudioServer.set_bus_name(idx, bus_name)
    AudioServer.set_bus_send(idx, send_to)
    print("Created bus '%s' with send to '%s' at index %d" % [bus_name, send_to, idx])
    return idx

static func remove_bus(bus_name: String) -> void:
    var idx := AudioServer.get_bus_index(bus_name)
    if idx != -1:
        AudioServer.remove_bus(idx)

static func set_volume(bus_name: String, db: float) -> void:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), db)

static func set_volume_linear(bus_name: String, db: float) -> float:
    AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(bus_name), db)
    return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name))

static func set_mute(bus_name: String, muted: bool) -> void:
    AudioServer.set_bus_mute(AudioServer.get_bus_index(bus_name), muted)

# Constant-power crossfade. t = 0.0 → full A, t = 1.0 → full B
static func crossfade(bus_a: String, bus_b: String, t: float) -> void:
    var angle := t * PI * 0.5
    set_volume(bus_a, linear_to_db(cos(angle)))
    set_volume(bus_b, linear_to_db(sin(angle)))

## Crossfade between three buses based on weights. Weights are normalized to sum to 1, so they can be any non-negative values.
static func crossfade3(
    bus_names: Array[String], weights: Vector3, invert: bool = false
) -> Vector3:
    if bus_names.size() != 3:
        printerr("crossfade3 requires exactly 3 bus names")
        return Vector3.ZERO

    if invert:
        weights.x = 1.0 / (weights.x + 0.001)
        weights.y = 1.0 / (weights.y + 0.001)
        weights.z = 1.0 / (weights.z + 0.001)

    # --- 1. Normalize ---
    for i in range(bus_names.size()):
        set_volume_linear(bus_names[i], weights[i]) 

    return weights

static func get_volume(bus_name: String) -> float:
    var bus_index = AudioServer.get_bus_index(bus_name)
    if bus_index == -1:
        printerr("Bus '%s' not found for get_volume" % bus_name)
        return 0.0
    var left = AudioServer.get_bus_peak_volume_left_db(bus_index, 0)
    var right = AudioServer.get_bus_peak_volume_right_db(bus_index, 0)
    return db_to_linear((left + right) / 2.0)

