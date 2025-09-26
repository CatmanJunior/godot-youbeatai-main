extends Node
class_name VoiceProcessor

@export var bpmManager: Node
@export var notes: Notes
@export var octaveRange: Vector2i

signal on_processed(data: PackedVector3Array)

func filter_time(data: Vector3):
	var beatDuration = 60.0/bpmManager.bpm /4.0
	return data.z <= bpmManager.amount_of_beats * beatDuration

func reduce_to_average(group: Array): 
	# filter low volume samples
	group = group.filter(func(e): return e.y > 0.000505)
	
	var reduced_group = group.reduce(func(accum, e): return accum + e)
	
	return reduced_group  / float(len(group))

func start_processing(data: PackedVector3Array):
	var result: PackedVector3Array = []
	var groups: Array[Array] = []
	
	var data_array: Array = Array(data)
	data_array = data_array.filter(filter_time)
	
	var group_size = (len(data_array) / bpmManager.amount_of_beats) 
	for i in range(len(data_array) / group_size):
		groups.append(data_array.slice( i * group_size, (i+1) * group_size ) )

	var beats = groups.map(reduce_to_average)
	beats.resize(bpmManager.amount_of_beats)
	
	for sample in beats:	
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
	
	print("notes(%d) \n %s" % [len(result), result])
	on_processed.emit(result)
