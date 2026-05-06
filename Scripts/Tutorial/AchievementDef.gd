class_name AchievementDef
extends RefCounted
## Data class for a single achievement entry.
## Contains the condition, tooltip text, optional energy cost,
## optional unlock callback, and the node it is coupled to.

enum AchievementNode {
	NONE         = -1,
	TRACK_2   =  0,
	SYNTH_2     =  1,
	TEMPLATE_TIP =  2,
	ADD_SECTION=  3,
	FIRST_SAMPLE =  4,
	SECOND_SAMPLE=  5,
	TRACK_3    =  6,
}

## Callable () -> bool  evaluated every frame while blocked.
var condition: Callable
## Text shown in the tooltip panel.
var tooltip: String
## Energy required to press-unlock (-1 = no energy gate).
var worth: float
## Callable () -> void  called when the achievement unlocks.
var result: Callable
## Which entry in unlockable_nodes this achievement is coupled to.
var node_id: int  # AchievementNode enum value


func _init(
	p_node_id: int,
	p_tooltip: String,
	p_condition: Callable,
	p_worth: float = -1.0,
	p_result: Callable = Callable()
) -> void:
	node_id   = p_node_id
	tooltip   = p_tooltip
	condition = p_condition
	worth     = p_worth
	result    = p_result
