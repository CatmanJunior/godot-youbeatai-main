@tool
class_name ImportChordSettings
extends Resource

@export_tool_button("import_banks") var import_button = import_banks

func import_banks():
    var banks: JSON = preload("res://Resources/SoundBankMatrix/bank_chord_settings.json")
    
    for name: String in banks.data:        
        var bank : Dictionary = banks.data.get(name)
        var path = "res://Resources/Audio/SoundBanks/%s/%s.tres" % [name, name]
        var bank_resource: SoundBank = load(path)

        var progressions = ChordSettings.new()

        # assign setting values
        progressions.instrument = bank.get("instrument", 0)
        
        var font_path = "res://Resources/SoundFonts/" + bank.get("font", "florestan-subset.sfo")
        progressions.soundFont = load(font_path)
        
        progressions.progressions = [] as Array[ChordProgression]
        for progression_data: Array in bank.get("progressions"):
            var chords: Array[Chord] = []
            for chord: Dictionary in progression_data:
                var new_chord = Chord.new()
                # { "note": 69, "type": 1 },
                new_chord.base_note = chord.get("note", 60)
                new_chord.type = chord.get("type", 1)
                chords.append(new_chord)

            var new_progression = ChordProgression.new()
            new_progression.progression = chords
            progressions.progressions.append(new_progression)

        bank_resource.chord_progressions = progressions
        ResourceSaver.save(bank_resource, bank_resource.resource_path)