extends Node
class_name Sequencer

signal on_note(element: SequenceElement)
signal off_note(element: SequenceElement)

@export var elements: Array[SequenceElement] = []

@export var debug: bool = false

@export var current: SequenceElement

func _ready():

	EventBus.beat_triggered.connect(_on_bpm)
	EventBus.playing_changed.connect(_on_playing_change)

func _on_playing_change(state: bool):
	if state:
		return

	off_note.emit(current)

func _on_bpm(currentBeat: int):

	if debug:
		print("beat: %s" % currentBeat)

	if not current or currentBeat >= current.start + current.duration:
		if current:
			off_note.emit(current)
		current = get_note(currentBeat)
		if not current: # no valid entry
			return

		on_note.emit(current)

	if debug:
		print("note: %s for %s" % [current.start, current.duration])



func set_note(note: SequenceElement) -> void:
	elements[note.start] = note

func get_note(beat: int) -> SequenceElement:
	var index = elements.find_custom(func (e): return e and e.start <= beat and e.start + e.duration > beat)
	if index == -1:
		return null

	return elements[index]
