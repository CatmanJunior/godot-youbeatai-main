extends Node
# Manages blocker-based achievements that unlock UI elements.

var use_achievements: bool = false
var _done_late_ready: bool = false
var _paused: bool = true
var _timer: SceneTreeTimer = null

# References
var ui_manager: Node
var beat_manager: Node
var audio_player_manager: Node
var visibility_manager: Node
var layer_voice_over_0: Node  # green layer voice over
var layer_voice_over_1: Node  # purple layer voice over

# Achievement definition helper class
class AchievementDef:
	var condition: Callable  # () -> bool
	var tooltip: String
	var worth: float
	var result: Callable     # () -> void  (may be empty)

	func _init(p_condition: Callable, p_tooltip: String, p_worth: float = -1.0, p_result: Callable = Callable()):
		condition = p_condition
		tooltip = p_tooltip
		worth = p_worth
		result = p_result


func _ready():
	ui_manager = %UiManager
	beat_manager = %BeatManager
	audio_player_manager = %AudioPlayerManager
	visibility_manager = %VisibilityManager
	layer_voice_over_0 = get_node_or_null("%LayerVoiceOver0")
	layer_voice_over_1 = get_node_or_null("%LayerVoiceOver1")

	check_if_achievements_mode_should_be_active()
	on_ready()


func _process(_delta: float):
	on_update()


# ── Achievement definitions (evaluated every frame) ──────────────────────────

func _get_achievements() -> Array[AchievementDef]:
	var nodes := _get_nodes()
	# Guard: if references aren't ready yet, return empty
	if nodes.is_empty():
		return []

	var list: Array[AchievementDef] = []

	# 0 – Place 4 beats on ring 0 → unlock ring 2 (Snare)
	list.append(AchievementDef.new(
		func() -> bool: return _active_beats_per_ring(0) >= 4,
		"Door 4 beats te plaatsen op de rode ring speel je deze Snare vrij.",
		-1.0,
		func(): visibility_manager.set_ring_visibility(2, true)
	))

	# 1 – Clap along, earn 20 energy points → unlock ring 3 (Hi-hat)
	list.append(AchievementDef.new(
		func() -> bool: return true,
		"klap 👏 mee op de beat, verzamel 20 energie punten⚡voor een Hi-hat geluid.",
		20.0,
		func(): visibility_manager.set_ring_visibility(3, true)
	))

	# 2 – Record green ring → unlock purple synth ring
	list.append(AchievementDef.new(
		func() -> bool:
			if layer_voice_over_0 == null:
				return false
			return layer_voice_over_0.get_current_layer_voice_over() != null and _pause_between_synth_unlock(),
		"Door de groene ring 🐻 op te nemen speel je de paarse drukke 🐦 Synth ring vrij.",
		-1.0,
		func():
			if layer_voice_over_1 and layer_voice_over_1.big_line:
				layer_voice_over_1.big_line.visible = true
	))

	# 3 – Record purple ring → enable adding new layers
	list.append(AchievementDef.new(
		func() -> bool:
			if layer_voice_over_1 == null:
				return false
			return layer_voice_over_1.get_current_layer_voice_over() != null,
		"Als je de paarse ring 🐦 op neemt kan je daarna hier nieuwe lagen toevoegen."
	))

	# 4 – Add a layer → enable full song recording
	list.append(AchievementDef.new(
		func() -> bool: return ui_manager.added_layer if ui_manager else false,
		"Als je een nieuwe laag toevoegt, kan je hier een heel liedje opnemen."
	))

	# 5 – First recorded sample → gift unlock
	list.append(AchievementDef.new(
		func() -> bool:
			if audio_player_manager == null or audio_player_manager.audio_players_rec.size() < 3:
				return false
			return audio_player_manager.audio_players_rec[2].stream != null,
		"Een cadeautje van mij! neem met deze 🎤 microfoon een kort hard geluid op hem te gebruiken als instrument in de ring."
	))

	# 6 – Second recorded sample
	list.append(AchievementDef.new(
		func() -> bool:
			if audio_player_manager == null or audio_player_manager.audio_players_rec.size() < 4:
				return false
			return audio_player_manager.audio_players_rec[3].stream != null,
		"Kan je hier voor mij een kort gek geluid opnemen?"
	))

	return list


# ── Nodes that can be unlocked ───────────────────────────────────────────────

func _get_nodes() -> Array[Node2D]:
	if ui_manager and ui_manager.get("nodes_that_can_be_unlocked") != null:
		return ui_manager.nodes_that_can_be_unlocked
	return []


# ── Core lifecycle ───────────────────────────────────────────────────────────

func on_ready():
	var nodes := _get_nodes()
	for node in nodes:
		var blocker := _find_blocker(node)
		if blocker:
			_set_blocker_state(blocker, use_achievements)


func on_update():
	if not use_achievements:
		return

	var nodes := _get_nodes()
	var achievements := _get_achievements()
	if nodes.is_empty() or achievements.is_empty():
		return

	var count := mini(nodes.size(), achievements.size())

	for i in range(count):
		var node := nodes[i]
		var ach := achievements[i]
		var cond: bool = ach.condition.call()
		var worth: float = ach.worth
		var use_worth: bool = worth > 0.0 and worth != -1.0
		var enough_worth: bool = beat_manager.progress_bar_value > worth if beat_manager else false
		var blocker = _find_blocker(node)
		if blocker == null or not blocker.visible:
			continue

		if cond:
			if not use_worth:
				_set_blocker_state(blocker, false)
				_play_achievement_sfx()
				if ach.result.is_valid():
					ach.result.call()
				EventBus.achievement_done.emit(i)
			else:
				if enough_worth and blocker.get("pressed"):
					_set_blocker_state(blocker, false)
					beat_manager.progress_bar_value -= worth
					if beat_manager.progress_bar_value < 0:
						beat_manager.progress_bar_value = 0
					_play_achievement_sfx()
					if ach.result.is_valid():
						ach.result.call()
					EventBus.achievement_done.emit(i)

	if not _done_late_ready:
		_init_tooltip_actions(nodes, achievements)
		_setup_default_ui_state()
		_done_late_ready = true


# ── Tooltip / blocker interaction ────────────────────────────────────────────

func _init_tooltip_actions(nodes: Array[Node2D], achievements: Array[AchievementDef]):
	var count := mini(nodes.size(), achievements.size())
	for i in range(count):
		var node := nodes[i]
		var blocker = _find_blocker(node)
		if blocker == null:
			continue

		# Use a lambda that captures node reference
		blocker.gui_input.connect(func(input_event: InputEvent):
			if input_event is InputEventMouseButton:
				var mouse_event := input_event as InputEventMouseButton
				if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
					if not _allowed_to_speak(blocker):
						return
					if ui_manager.achievements_panel and ui_manager.achievements_panel.visible:
						close_tooltip()
					open_tooltip(node)
					_start_loop_to_check_if_tooltip_can_close()
		)


func _allowed_to_speak(target_blocker: Control) -> bool:
	var nodes := _get_nodes()
	var achievements := _get_achievements()
	var count := mini(nodes.size(), achievements.size())
	for i in range(count):
		var blocker = _find_blocker(nodes[i])
		var worth: float = achievements[i].worth
		var use_worth: bool = worth > 0.0 and worth != -1.0
		var enough_worth: bool = beat_manager.progress_bar_value > worth if beat_manager else false
		if blocker == target_blocker:
			if use_worth and enough_worth:
				return false
	return true


func open_tooltip(node: Node2D):
	var nodes := _get_nodes()
	var achievements := _get_achievements()
	var index := nodes.find(node)
	if index < 0 or index >= achievements.size():
		return
	if ui_manager.achievements_panel:
		ui_manager.achievements_panel.visible = true
	if ui_manager.instruction_label:
		ui_manager.instruction_label.text = achievements[index].tooltip
	_speak_tooltip(index)


func close_tooltip():
	if ui_manager.instruction_label:
		ui_manager.instruction_label.text = ""
	if ui_manager.achievements_panel:
		ui_manager.achievements_panel.visible = false
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()


func _start_loop_to_check_if_tooltip_can_close():
	get_tree().create_timer(0.4).timeout.connect(func():
		if DisplayServer.tts_is_speaking():
			_start_loop_to_check_if_tooltip_can_close()
		else:
			close_tooltip()
	)


# ── TTS ──────────────────────────────────────────────────────────────────────

func _speak_tooltip(index: int):
	if ui_manager.audio_export_ui and ui_manager.audio_export_ui.mute_speach and ui_manager.audio_export_ui.mute_speach.button_pressed:
		return
	var achievements := _get_achievements()
	if index < 0 or index >= achievements.size():
		return
	TTSHelper.speak(_extract_emoticons(achievements[index].tooltip))


func _extract_emoticons(input: String) -> String:
	# Strip emoji / symbol characters via regex
	var regex := RegEx.new()
	# Match common emoji ranges (surrogate pairs, symbols, modifiers, ZWJ)
	regex.compile("[\\u200D\\uFE0F\\u{1F000}-\\u{1FFFF}\\u{2600}-\\u{27BF}\\u{2B50}\\u{23CF}-\\u{23FA}\\u{2934}-\\u{2935}\\u{25AA}-\\u{25FE}]")
	return regex.sub(input, "", true)


# ── Blocker helpers ──────────────────────────────────────────────────────────

func _find_blocker(node: Node) -> Control:
	if node == null:
		return null
	var blocker = node.find_child("Blocker", true, false)
	return blocker as Control if blocker else null


func _set_blocker_state(blocker: Control, enabled: bool):
	blocker.visible = enabled
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func unlock_all_achievements():
	var nodes := _get_nodes()
	for node in nodes:
		var blocker := _find_blocker(node)
		if blocker:
			_set_blocker_state(blocker, false)
	EventBus.all_achievements_unlocked.emit()


# ── Default UI state ─────────────────────────────────────────────────────────

func _setup_default_ui_state():
	visibility_manager.set_ring_visibility(2, false)
	visibility_manager.set_ring_visibility(3, false)
	if layer_voice_over_1 and layer_voice_over_1.big_line:
		layer_voice_over_1.big_line.visible = false


# ── Pause timer between synth unlock ─────────────────────────────────────────

func _pause_between_synth_unlock() -> bool:
	if layer_voice_over_0 and layer_voice_over_0.get_current_layer_voice_over() != null:
		if _timer == null:
			_timer = get_tree().create_timer(3.0)
			_timer.timeout.connect(_on_pause_timeout)
		if not _paused:
			return true
	return false


func _on_pause_timeout():
	_paused = false


# ── SFX helper ───────────────────────────────────────────────────────────────

func _play_achievement_sfx():
	EventBus.play_sfx_requested.emit(audio_player_manager.achievement_sfx)

# ── Beat counting ────────────────────────────────────────────────────────────

func _active_beats_per_ring(ring_index: int) -> int:
	var section : SectionData = beat_manager.current_section
	if section == null or ring_index < 0 or ring_index >= section.sample_tracks.size():
		return 0
	var count := 0
	for active in section.sample_tracks[ring_index].beats:
		if active:
			count += 1
	return count


# ── Persistence ──────────────────────────────────────────────────────────────

func _read_use_achievements() -> bool:
	var use := false
	var path := ProjectSettings.globalize_path("user://") + "/use_achievements.txt"
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var content := file.get_as_text().strip_edges()
			use = content.to_lower() == "true"
			file.close()
		# Delete after reading
		DirAccess.remove_absolute(path)
	print("use achievements: " + str(use))
	return use


func check_if_achievements_mode_should_be_active():
	use_achievements = _read_use_achievements()


func reset():
	check_if_achievements_mode_should_be_active()
	_done_late_ready = false
	_paused = true
	_timer = null
