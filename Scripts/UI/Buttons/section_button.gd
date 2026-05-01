extends Button
class_name SectionButton

@export var outline : TextureRect

@export var inactive_ring: SectionRingGraphic
@export var active_ring: SectionRingGraphic

var index: int

func _ready():
    outline.visible = false
    EventBus.section_loop.connect(_on_next_section)
    EventBus.on_set_loop_count.connect(_on_loop_count_set)
    EventBus.section_switched.connect(_on_new_section)
    EventBus.beat_triggered.connect(_on_beat)

func _exit_tree():
    EventBus.section_loop.disconnect(_on_next_section)
    EventBus.on_set_loop_count.disconnect(_on_loop_count_set)
    EventBus.section_switched.disconnect(_on_new_section)
    EventBus.beat_triggered.disconnect(_on_beat)

func rotate_outline(outline_rotation_angle: float):
    outline.rotation_degrees = outline_rotation_angle

func _on_beat(beat: int):
    if SongState.current_section_index != index:  
        return

    var fill = float(beat) / SongState.total_beats
    active_ring.set_fill( fill )

func _on_new_section(section: SectionData):
    if index != section.index:
        return

    active_ring.set_repeating(0)
    active_ring.set_fill(0)

func _on_loop_count_set(section: int, count: int):
    if index != section:
        return

    inactive_ring.set_repeating(count)
    inactive_ring.set_fill(0)

func _on_next_section(section: int, cursor: int):
    if index != section:
        # make sure to reset progress
        return

    active_ring.set_repeating(cursor)
