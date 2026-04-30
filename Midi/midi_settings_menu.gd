extends Control
class_name MidiSettingsMenu

const CHANNEL_MIN: int = 0
const CHANNEL_MAX: int = 15
const NOTE_MIN: int = 0
const NOTE_MAX: int = 127

# ── Device ────────────────────────────────────────────────────────────

@export_category("Device")
@export var device_select: OptionButton
@export var out_device_select: OptionButton

# ── Clock ─────────────────────────────────────────────────────────────

@export_category("Clock")
@export var clock_in: CheckButton
@export var clock_out: CheckButton

# ── Log ───────────────────────────────────────────────────────────────

@export_category("Log")
@export var log_in_box: TextEdit
@export var log_out_box: TextEdit

# ── Sample Channels ───────────────────────────────────────────────────

@export_category("Sample Channels")
@export var in_1: SpinBox
@export var out_1: SpinBox
@export var note_1: SpinBox

@export var in_2: SpinBox
@export var out_2: SpinBox
@export var note_2: SpinBox

@export var in_3: SpinBox
@export var out_3: SpinBox
@export var note_3: SpinBox

@export var in_4: SpinBox
@export var out_4: SpinBox
@export var note_4: SpinBox

# ── Synth Channels ────────────────────────────────────────────────────

@export_category("Synth Channels")
@export var in_5: SpinBox
@export var out_5: SpinBox

@export var in_6: SpinBox
@export var out_6: SpinBox

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	OS.open_midi_inputs()
	_configure_spinbox_ranges()
	_populate_device_select()
	_load_settings()
	_connect_ui_signals()
	EventBus.midi_input_received.connect(_on_midi_input_received)

#if m is pressed toggle visibility of the menu
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_M and event.is_pressed() and not event.is_echo():
		if is_visible():
			hide()
		else:
			show()

# ── Private ───────────────────────────────────────────────────────────

func _populate_device_select() -> void:
	if not is_instance_valid(device_select):
		return
	device_select.clear()
	var devices: PackedStringArray = OS.get_connected_midi_inputs()
	if devices.is_empty():
		device_select.add_item("No devices found", 0)
		device_select.disabled = true
	else:
		device_select.disabled = false
		for i: int in devices.size():
			device_select.add_item(devices[i], i)
		var saved_index: int = GameState.midi_settings.device_index
		if saved_index < device_select.item_count:
			device_select.select(saved_index)

	if not is_instance_valid(out_device_select):
		return
	out_device_select.clear()
	if not ClassDB.class_exists("MidiOut"):
		out_device_select.add_item("Not available", 0)
		out_device_select.disabled = true
		return
	var out_instance: Object = ClassDB.instantiate("MidiOut")
	var out_devices: PackedStringArray = out_instance.get_port_names()
	out_instance.free()
	if out_devices.is_empty():
		out_device_select.add_item("No devices found", 0)
		out_device_select.disabled = true
		return
	out_device_select.disabled = false
	for i: int in out_devices.size():
		out_device_select.add_item(out_devices[i], i)
	var saved_out_index: int = GameState.midi_settings.out_device_index
	if saved_out_index < out_device_select.item_count:
		out_device_select.select(saved_out_index)

func _configure_spinbox_ranges() -> void:
	var channel_spinboxes: Array[SpinBox] = [in_1, out_1, in_2, out_2, in_3, out_3, in_4, out_4, in_5, out_5, in_6, out_6]
	for spinbox: SpinBox in channel_spinboxes:
		if is_instance_valid(spinbox):
			spinbox.min_value = CHANNEL_MIN
			spinbox.max_value = CHANNEL_MAX

	var note_spinboxes: Array[SpinBox] = [note_1, note_2, note_3, note_4]
	for spinbox: SpinBox in note_spinboxes:
		if is_instance_valid(spinbox):
			spinbox.min_value = NOTE_MIN
			spinbox.max_value = NOTE_MAX

func _load_settings() -> void:
	var s := GameState.midi_settings
	if is_instance_valid(clock_in):
		clock_in.button_pressed = s.clock_in_enabled
	if is_instance_valid(clock_out):
		clock_out.button_pressed = s.clock_out_enabled

	var in_spinboxes: Array[SpinBox] = [in_1, in_2, in_3, in_4, in_5, in_6]
	var out_spinboxes: Array[SpinBox] = [out_1, out_2, out_3, out_4, out_5, out_6]
	var note_spinboxes: Array[SpinBox] = [note_1, note_2, note_3, note_4]

	for i: int in in_spinboxes.size():
		if is_instance_valid(in_spinboxes[i]):
			in_spinboxes[i].value = s.track_channel_in[i]
	for i: int in out_spinboxes.size():
		if is_instance_valid(out_spinboxes[i]):
			out_spinboxes[i].value = s.track_channel_out[i]
	for i: int in note_spinboxes.size():
		if is_instance_valid(note_spinboxes[i]):
			note_spinboxes[i].value = s.sample_note[i]

func _connect_ui_signals() -> void:
	if is_instance_valid(device_select):
		device_select.item_selected.connect(_on_device_selected)
	if is_instance_valid(out_device_select):
		out_device_select.item_selected.connect(_on_out_device_selected)
	if is_instance_valid(clock_in):
		clock_in.toggled.connect(_on_clock_in_toggled)
	if is_instance_valid(clock_out):
		clock_out.toggled.connect(_on_clock_out_toggled)

	_connect_channel_spinbox(in_1, 0, true)
	_connect_channel_spinbox(in_2, 1, true)
	_connect_channel_spinbox(in_3, 2, true)
	_connect_channel_spinbox(in_4, 3, true)
	_connect_channel_spinbox(in_5, 4, true)
	_connect_channel_spinbox(in_6, 5, true)

	_connect_channel_spinbox(out_1, 0, false)
	_connect_channel_spinbox(out_2, 1, false)
	_connect_channel_spinbox(out_3, 2, false)
	_connect_channel_spinbox(out_4, 3, false)
	_connect_channel_spinbox(out_5, 4, false)
	_connect_channel_spinbox(out_6, 5, false)

	_connect_note_spinbox(note_1, 0)
	_connect_note_spinbox(note_2, 1)
	_connect_note_spinbox(note_3, 2)
	_connect_note_spinbox(note_4, 3)

func _connect_channel_spinbox(spinbox: SpinBox, track: int, is_in: bool) -> void:
	if not is_instance_valid(spinbox):
		return
	spinbox.value_changed.connect(func(value: float) -> void:
		var ch := int(value)
		if is_in:
			GameState.midi_settings.track_channel_in[track] = ch
			# Synth tracks start at index 4
			if track >= 4:
				EventBus.midi_synth_channel_changed.emit(track, ch)
		else:
			GameState.midi_settings.track_channel_out[track] = ch
	)

func _connect_note_spinbox(spinbox: SpinBox, track: int) -> void:
	if not is_instance_valid(spinbox):
		return
	spinbox.value_changed.connect(func(value: float) -> void:
		GameState.midi_settings.sample_note[track] = int(value)
	)

func _on_device_selected(index: int) -> void:
	GameState.midi_settings.device_index = index
	EventBus.midi_device_changed.emit(index)

func _on_out_device_selected(index: int) -> void:
	GameState.midi_settings.out_device_index = index
	EventBus.midi_out_device_changed.emit(index)

func _on_clock_in_toggled(enabled: bool) -> void:
	GameState.midi_settings.clock_in_enabled = enabled
	EventBus.midi_clock_in_toggled.emit(enabled)

func _on_clock_out_toggled(enabled: bool) -> void:
	GameState.midi_settings.clock_out_enabled = enabled

func _on_midi_input_received(message: String) -> void:
	if not is_instance_valid(log_in_box):
		return
	const MAX_LOG_LINES: int = 100
	var lines: PackedStringArray = log_in_box.text.split("\n", false)
	if lines.size() >= MAX_LOG_LINES:
		lines = lines.slice(lines.size() - MAX_LOG_LINES + 1)
		log_in_box.text = "\n".join(lines) + "\n"
	log_in_box.text += message + "\n"
	log_in_box.scroll_vertical = log_in_box.get_line_count()
