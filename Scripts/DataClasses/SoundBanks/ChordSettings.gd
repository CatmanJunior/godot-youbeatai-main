extends Resource
class_name ChordSettings

@export var progressions: Array[ChordProgression]
@export var soundFont: SoundFont
@export var instrument: int = 0
## Maps section textures to chord progressions. When populated, overrides ChordPlayerSettings.tex_lookup.
@export var tex_lookup: Dictionary[Texture2D, ProgressionOffset] = {}