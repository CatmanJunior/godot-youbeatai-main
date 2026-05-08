class_name AchievementList
extends RefCounted
## Builds the ordered list of AchievementDef entries.
## [member tracker] must be set before calling [method build].

## Reference to the manager — closures read its public counters.
var tracker: AchievementManager


func build() -> Array[AchievementDef]:
	var N := AchievementDef.AchievementNode
	var list: Array[AchievementDef] = []
	list.assign([
		_def(N.TRACK_2,
			"Verzamel meer energie om de Snare ring vrij te spelen",
			func() -> bool: return true,
			50.0,
			func(): EventBus.track_sprites_visibility_requested.emit(2, true)),

		_def(N.SYNTH_2,
			"Verzamel meer energie om een hoger geluid op te kunnen nemen",
			func() -> bool: return true,
			70.0,
			_unlock_big_line),

		_def(N.TEMPLATE_TIP,
			"In de instellingen kan je op tip klikken, dan laat ik een voorbeeld liedje zien",
			func() -> bool: return true,
			50.0,),

		_def(N.ADD_SECTION,
			"Als je een nieuwe patroon toevoegt, kan je hier een heel liedje opnemen.",
			func() -> bool: return true,
			50.0,
			_unlock_sections,
		),

		_def(N.FIRST_SAMPLE,
			"Een cadeautje van mij! neem met deze 🎤 microfoon een kort hard geluid op hem te gebruiken als instrument in de ring.",
			func() -> bool: return tracker.samples_recorded >= 1),

		_def(N.SECOND_SAMPLE,
			"Kan je hier voor mij een kort gek geluid opnemen?",
			func() -> bool: return tracker.samples_recorded >= 2),

		_def(N.TRACK_3,
			"Verzamel meer energie om de hi-hat vrij te spelen",
			func() -> bool: return true,
			50.0,
			func(): EventBus.track_sprites_visibility_requested.emit(3, true)),
	])
	return list


# ── Unlock callbacks ──────────────────────────────────────────────────────────

func _unlock_sections() -> void:
	tracker.section_ui.show_all_context_buttons()
	

func _unlock_big_line() -> void:
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.SYNTH2_LAYER, true)
	EventBus.synth_progress_bar_visible_requested.emit(1, true)
	EventBus.track_select_button_visibility_requested.emit(5, true)


# ── Factory helper ────────────────────────────────────────────────────────────

func _def(
	p_node_id: int,
	p_tooltip: String,
	p_condition: Callable,
	p_worth: float = -1.0,
	p_result: Callable = Callable()
) -> AchievementDef:
	return AchievementDef.new(p_node_id, p_tooltip, p_condition, p_worth, p_result)
