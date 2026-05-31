class_name KlappyLineLibrary
extends Resource
## Registry of all Klappy lines, generated from [code]Data/klappy_lines.csv[/code] by
## [code]Scripts/Tools/klappy_lines_importer.gd[/code]. Loaded once by the
## [code]KlappyVoice[/code] autoload, which indexes it by [member KlappyLineData.id].

## All authored lines, one per row of the source CSV.
@export var lines: Array[KlappyLineData] = []

## Returns the line whose [member KlappyLineData.id] matches [param line_id], or null.
func get_line(line_id : int) -> KlappyLineData:
	for line in lines:
		if line.id == line_id:
			return line
	return null
