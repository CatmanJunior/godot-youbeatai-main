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
			KlappyVoice.line_text(KlappyLine.Id.ACH_TIP_TRACK_2),
			func() -> bool: return true,
			50.0,
			func(): EventBus.track_sprites_visibility_requested.emit(2, true),
			KlappyLine.Id.ACH_TRACK_2),

		_def(N.SYNTH_2,
			KlappyVoice.line_text(KlappyLine.Id.ACH_TIP_SYNTH_2),
			func() -> bool: return true,
			70.0,
			_unlock_big_line,
			KlappyLine.Id.ACH_SYNTH_2),

		_def(N.TEMPLATE_TIP,
			KlappyVoice.line_text(KlappyLine.Id.ACH_TIP_TEMPLATE),
			func() -> bool: return true,
			50.0,
			Callable(),
			KlappyLine.Id.ACH_TEMPLATE_TIP),

		_def(N.ADD_SECTION,
			KlappyVoice.line_text(KlappyLine.Id.ACH_TIP_ADD_SECTION),
			func() -> bool: return true,
			50.0,
			_unlock_sections,
			KlappyLine.Id.ACH_ADD_SECTION),

		_def(N.FIRST_SAMPLE,
			KlappyVoice.line_text(KlappyLine.Id.ACH_TIP_FIRST_SAMPLE),
			func() -> bool: return tracker.samples_recorded >= 1,
			-1.0,
			Callable(),
			KlappyLine.Id.ACH_FIRST_SAMPLE),

		_def(N.SECOND_SAMPLE,
			KlappyVoice.line_text(KlappyLine.Id.ACH_TIP_SECOND_SAMPLE),
			func() -> bool: return tracker.samples_recorded >= 2,
			-1.0,
			Callable(),
			KlappyLine.Id.ACH_SECOND_SAMPLE),

		_def(N.TRACK_3,
			KlappyVoice.line_text(KlappyLine.Id.ACH_TIP_TRACK_3),
			func() -> bool: return true,
			50.0,
			func(): EventBus.track_sprites_visibility_requested.emit(3, true),
			KlappyLine.Id.ACH_TRACK_3),
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
	p_result: Callable = Callable(),
	p_unlock_message: int = KlappyLine.Id.NONE
) -> AchievementDef:
	return AchievementDef.new(p_node_id, p_tooltip, p_condition, p_worth, p_result, p_unlock_message)
