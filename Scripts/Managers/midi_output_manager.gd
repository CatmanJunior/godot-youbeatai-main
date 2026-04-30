extends Node
class_name MidiOutputManager

## Manages MIDI output via the godot_rtmidi MidiOut class.
## Sends Note On/Off for sample and synth tracks, MIDI Clock (24 PPQ),
## and MIDI Start/Stop when playback begins/ends.
##
## Platform note: MidiOut is not available on web exports.
## All methods guard with _is_available() before accessing _midi_out.

# ── Constants ─────────────────────────────────────────────────────────

const MIDI_NOTE_ON_BASE: int  = 0x90
const MIDI_NOTE_OFF_BASE: int = 0x80
const MIDI_CLOCK_TICK: int    = 0xF8
const MIDI_START: int         = 0xFA
const MIDI_STOP: int          = 0xFC

## Number of sample tracks to route to MIDI out on beat fire.
const SAMPLE_TRACK_COUNT: int = 4
## Fixed note-off delay for drum/sample tracks (seconds).
const SAMPLE_GATE: float = 0.05

# ── Private ───────────────────────────────────────────────────────────

var _midi_out: Object = null  # MidiOut — typed as Object for web safety
var _clock_accumulator: float = 0.0

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	if not _is_available():
		push_warning("MidiOutputManager: MidiOut class not available on this platform.")
		return

	_midi_out = ClassDB.instantiate("MidiOut")
	add_child(_midi_out)

	var saved_index: int = GameState.midi_settings.out_device_index
	_open_port(saved_index)

	EventBus.midi_out_device_changed.connect(_on_out_device_changed)
	EventBus.beat_triggered.connect(_on_beat_triggered)
	EventBus.midi_note_out_requested.connect(_on_midi_note_out_requested)
	EventBus.playing_changed.connect(_on_playing_changed)

func _process(delta: float) -> void:
	if not GameState.midi_settings.clock_out_enabled:
		return
	if not GameState.playing:
		return
	if not _is_port_open():
		return

	var tick_interval: float = 60.0 / float(SongState.bpm) / 24.0
	_clock_accumulator += delta
	while _clock_accumulator >= tick_interval:
		_clock_accumulator -= tick_interval
		_midi_out.send_message(PackedByteArray([MIDI_CLOCK_TICK]))

# ── Private ───────────────────────────────────────────────────────────

func _is_available() -> bool:
	return ClassDB.class_exists("MidiOut")

func _is_port_open() -> bool:
	return _midi_out != null and _midi_out.is_port_open()

func _open_port(index: int) -> void:
	if not _is_available():
		return
	if _is_port_open():
		_midi_out.close_port()
	var count: int = _midi_out.get_port_count()
	if count == 0:
		push_warning("MidiOutputManager: No MIDI output ports available.")
		return
	var clamped: int = clampi(index, 0, count - 1)
	_midi_out.open_port(clamped)

func _send_note_on(channel: int, note: int, velocity: int) -> void:
	if not _is_port_open():
		return
	_midi_out.send_message(PackedByteArray([MIDI_NOTE_ON_BASE | (channel & 0x0F), note & 0x7F, velocity & 0x7F]))

func _send_note_off(channel: int, note: int) -> void:
	if not _is_port_open():
		return
	_midi_out.send_message(PackedByteArray([MIDI_NOTE_OFF_BASE | (channel & 0x0F), note & 0x7F, 0]))

func _schedule_note_off(channel: int, note: int, gate: float) -> void:
	get_tree().create_timer(gate).timeout.connect(func() -> void:
		_send_note_off(channel, note)
	)

# ── Signal handlers ───────────────────────────────────────────────────

func _on_beat_triggered(beat: int) -> void:
	if not _is_port_open():
		return
	var settings := GameState.midi_settings
	for i: int in SAMPLE_TRACK_COUNT:
		if SongState.current_section.get_beat(i, beat):
			var channel: int = settings.track_channel_out[i]
			var note: int    = settings.sample_note[i]
			_send_note_on(channel, note, 100)
			_schedule_note_off(channel, note, SAMPLE_GATE)

func _on_midi_note_out_requested(channel: int, note: int, velocity: int, gate: float) -> void:
	_send_note_on(channel, note, velocity)
	_schedule_note_off(channel, note, gate)

func _on_playing_changed(is_playing: bool) -> void:
	if not GameState.midi_settings.clock_out_enabled:
		return
	if not _is_port_open():
		return
	_clock_accumulator = 0.0
	if is_playing:
		_midi_out.send_message(PackedByteArray([MIDI_START]))
	else:
		_midi_out.send_message(PackedByteArray([MIDI_STOP]))

func _on_out_device_changed(index: int) -> void:
	GameState.midi_settings.out_device_index = index
	_open_port(index)
