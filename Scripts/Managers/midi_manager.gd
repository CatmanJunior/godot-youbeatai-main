extends Node
class_name MidiManager

# ── Constants ─────────────────────────────────────────────────────────

const MIDI_CLOCK_TICK: int = 248   # Sent 24x per beat — never log
const MIDI_CLOCK_START: int = 250
const MIDI_CLOCK_STOP: int = 252
const MIDI_ACTIVE_SENSING: int = 254  # Sent every 300ms — never log
const MIDI_SYSTEM_RESET: int = 255

## System realtime messages that are too frequent or noisy to log.
const SILENT_MESSAGES: Array[int] = [MIDI_ACTIVE_SENSING, MIDI_CLOCK_TICK, MIDIMessage.MIDI_MESSAGE_QUARTER_FRAME]

var cc_values: Dictionary = {}
# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	OS.open_midi_inputs()
	EventBus.midi_device_changed.connect(_on_midi_device_changed)

func _input(event: InputEvent) -> void:
	if not event is InputEventMIDI:
		return
	var midi := event as InputEventMIDI
	_log_event(midi)
	_route_clock(midi)
	_route_sample_trigger(midi)

# ── Private ───────────────────────────────────────────────────────────

func _on_midi_device_changed(_device_index: int) -> void:
	OS.close_midi_inputs()
	OS.open_midi_inputs()

func _log_event(event: InputEventMIDI) -> void:
	# Skip high-frequency realtime messages to prevent flooding the log.
	
	if event.message in SILENT_MESSAGES:
		return
	var msg: String
	if event.message == MIDIMessage.MIDI_MESSAGE_CONTROL_CHANGE:
		if event.controller_number in cc_values: 
			#check if it changed more than 10 since last value to prevent flooding the log with minor changes
			if abs(cc_values[event.controller_number] - event.controller_value) < 10:
				return # Skip logging if the CC value hasn't changed since the last message.
		cc_values[event.controller_number] = event.controller_value
		msg = "cc ch:%d  controller:%d  value:%d" % [event.channel, event.controller_number, event.controller_value]
	elif event.message == MIDI_CLOCK_START:
		msg = "Start"
	elif event.message == MIDI_CLOCK_STOP:
		msg = "Stop"
	elif event.message == MIDI_MESSAGE_NOTE_ON and event.velocity > 0:
		msg = "Note On  ch:%d  pitch:%d  vel:%d" % [event.channel, event.pitch, event.velocity]
	elif (event.message == MIDI_MESSAGE_NOTE_ON and event.velocity == 0) or event.message == MIDI_MESSAGE_NOTE_OFF:
		msg = "Note Off ch:%d  pitch:%d" % [event.channel, event.pitch]
	else:
		msg = "msg:%d  ch:%d" % [event.message, event.channel]
	
	EventBus.midi_input_received.emit(msg)

func _route_clock(event: InputEventMIDI) -> void:
	if not GameState.midi_settings.clock_in_enabled:
		return
	if event.message == MIDIMessage.MIDI_MESSAGE_CONTROL_CHANGE:
		if event.controller_number == 6 and event.controller_value == 46: # Start
			EventBus.playing_change_requested.emit(true)
		elif event.controller_number == 6 and event.controller_value == 47: # Stop
			EventBus.playing_change_requested.emit(false)
	if event.message == MIDI_CLOCK_START:
		EventBus.playing_change_requested.emit(true)
	elif event.message == MIDI_CLOCK_STOP:
		EventBus.playing_change_requested.emit(false)

func _route_sample_trigger(event: InputEventMIDI) -> void:
	if event.message != MIDI_MESSAGE_NOTE_ON or event.velocity == 0:
		return
	var settings := GameState.midi_settings
	for i: int in settings.sample_note.size():
		if event.channel == settings.track_channel_in[i] and event.pitch == settings.sample_note[i]:
			EventBus.play_track_requested.emit(i)
