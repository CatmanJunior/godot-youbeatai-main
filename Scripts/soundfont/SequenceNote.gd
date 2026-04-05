extends Resource
class_name SequenceNote

@export var note: int = 0
@export var duration: int = 1
@export var beat: int = 0
@export var sub_beat: int = 0  # 0-3, position within the beat (subdivision index)
@export var velocity: float = 1.0
@export var chord: String = ""
