extends Node
class_name VoiceProcessor

@export var bpmManager: Node
@export var notes: Notes
@export var combine_threshold: float = -1 # -1 is off
@export var octaveRange: Vector2i

@export var beats_amount_scaler: float = 1.0

signal on_processed(data: Array[SequenceNote])

func filter_time(data: Vector3):
	var beatDuration = 60.0/bpmManager.bpm /4.0
	return data.z <= bpmManager.total_beat_count * beatDuration

func reduce_to_average(group: Array): 
	# filter low volume samples
	var base = group[0]
	group = group.filter(func(e): return e.y > 0.000505)
	if len(group) == 0:
		return base
	var reduced_group = group.reduce(func(accum, e): return accum + e)
	
	return reduced_group  / float(len(group))

func start_processing(data: PackedVector3Array):
	if len(data) == 0:
		printerr("no data received")
		return
		
	var result: PackedVector3Array = []
	var groups: Array[Array] = []
	
	var data_array: Array = Array(data)
	data_array = data_array.filter(filter_time)
	
	var length = bpmManager.total_beat_count * beats_amount_scaler
	var group_size = (len(data_array) / length)
	if group_size == 0:
		printerr("not enought data received got: %d" % len(data_array))
		return
	
	for i in range(len(data_array) / group_size):
		groups.append(data_array.slice( i * group_size, (i+1) * group_size ) )

	var beats = groups.map(reduce_to_average)
	beats.resize(length)
	
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
		
	var sequence_notes: Array[SequenceNote] = []
	for i in range(len(result)):
		var current = result[i]
		var last: SequenceNote = null
		
		if len(sequence_notes) > 0:
			last = sequence_notes.back()
		
		if last == null or abs(last.note - current.x) > combine_threshold:
			last = SequenceNote.new()
			last.beat = round(i / beats_amount_scaler)
			last.note = current.x
			last.duration = round(1.0 / beats_amount_scaler)
			last.velocity = current.y
			sequence_notes.append(last)
		else:
			last.duration += round(1.0 / beats_amount_scaler)
	
	for index in range(len(sequence_notes)):
		print("beat: %d, note: %d, duration: %d" % [sequence_notes[index].beat, sequence_notes[index].note, sequence_notes[index].duration])	
	
	var sequence = Sequence.new()
	sequence.sequence = sequence_notes
	on_processed.emit(sequence)
