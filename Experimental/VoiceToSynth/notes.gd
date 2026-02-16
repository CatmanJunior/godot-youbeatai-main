@tool extends Resource
class_name Notes

@export var octaves: Array[Octave] = []

@export_tool_button("import from csv") var import_csv_button = import_csv 

func import_csv():
	var records = preload("res://Experimental/VoiceToSynth/data.csv").records.slice(1)
	
	var append_to_octaves := func (notes: Array[Note], dest):
		var octave = Octave.new()
		octave.notes = notes.duplicate()
		dest.append(octave)
		notes.clear()

	var new_octaves: Array[Octave] = []
	var notes: Array[Note] = []
	for record in records:
		if "C" in record[0] and len(notes) > 0:
			append_to_octaves.call(notes, new_octaves)

		var note = Note.new()
		note.name = record[0]
		note.id = record[1]
		note.frequency = record[2]
		notes.append(
			note
		)
		
	# append last octave
	append_to_octaves.call(notes, new_octaves)
	octaves = new_octaves

func get_octave(num: int) -> Octave:
	var length = len(octaves)
	# early out when wrong octave number is given
	if num < 0 or length < num:
		printerr("invalid octave number provided expected number within (%s - %s)" % [0, length])
		return null
	
	return octaves[num]
