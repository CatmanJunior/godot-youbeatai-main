extends Resource
class_name MidiSettingsData

## Runtime-only MIDI settings (not persisted to disk).
## Holds device selection, clock flags, per-track channel mappings, and sample notes.

## Index of the selected MIDI input device in OS.get_connected_midi_inputs().
var device_index: int = 0

## Whether MIDI Start (250) / Stop (252) messages control BeatManager play/pause.
var clock_in_enabled: bool = false

## Reserved for future MIDI clock output support.
var clock_out_enabled: bool = false

## MIDI input channel per track (indices 0–5 → tracks 1–6). Default 0–5.
var track_channel_in: Array[int] = [0, 1, 2, 3, 4, 5]

## MIDI output channel per track — stored but unused until MIDI output is supported.
var track_channel_out: Array[int] = [0, 1, 2, 3, 4, 5]

## MIDI note number that triggers each sample track (indices 0–3 → tracks 1–4).
## Defaults to GM kick, snare, closed hat, open hat.
var sample_note: Array[int] = [36, 38, 42, 46]
