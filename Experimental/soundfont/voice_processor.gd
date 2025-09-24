extends Node
class_name VoiceProcessor

@export var bpmManager: Node
@export var notes: Notes
@export var octaveRange: Vector2i

signal on_processed(data: PackedVector3Array)

func start_processing(data: PackedVector3Array):
	var beatDuration = 60.0/bpmManager.bpm /4.0
	var result: PackedVector3Array = []
	
	# TODO: reduce array size with needed kernel
	# kernel size should maybe be depend on reduction amount?
	for sample in data:
		if sample.z > len(result) * beatDuration:
			# clamp frequency to octave range closests note
			var closest_diff: float = 9999
			var closest: Note = notes.get_octave(octaveRange.x).notes[0]
			
			for octaveNumber in range(octaveRange.x, octaveRange.y + 1):
				var octave = notes.get_octave(octaveNumber)
				for note in octave.notes:
					var diff: float = abs(sample.x - note.frequency)
					if diff < closest_diff:
						closest_diff = diff
						closest = note
			sample.x = closest.id
			result.push_back(sample)
	
	result.resize(bpmManager.amount_of_beats)	
	print("samples(%d) \n %s" % [len(result), result])
	on_processed.emit(result)
