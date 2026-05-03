extends Node
# Manages blocker-based achievements that unlock UI elements.

var use_achievements: bool = false
var _done_late_ready: bool = false
var _paused: bool = true
var _timer: SceneTreeTimer = null
## Accumulated energy points earned by clapping on beat.
var _energy_points: float = 0.0

# Exported scene-node references (assign from the editor or parent scene).
@export var achievements_panel: Panel
@export var instruction_label: Label
@export var mute_speech_button: BaseButton
@export var audio_player_manager: AudioPlayerManager

## Nodes guarded by Blocker children. Assign from the editor.
@export var unlockable_nodes: Array[Node2D] = []

# Voice-over layers (optional; checked via null guards).
@export var layer_voice_over_0: Node  ## green layer voice over
@export var layer_voice_over_1: Node  ## purple layer voice over

# Achievement definition helper class
class AchievementDef:
	var condition: Callable  # () -> bool
	var tooltip: String
	var worth: float
	var result: Callable     # () -> void  (may be empty)

	func _init(p_condition: Callable, p_tooltip: String, p_worth: float = -1.0, p_result: Callable = Callable()) -> void:
		condition = p_condition
		tooltip = p_tooltip
		worth = p_worth
		result = p_result


func _ready() -> void:
	check_if_achievements_mode_should_be_active()
	EventBus.clap_on_beat_detected.connect(_on_clap_on_beat)
	_setup_blockers()


func _process(_delta: float) -> void:
	_update_achievements()

## Increment energy when the player claps on beat.
func _on_clap_on_beat() -> void:
	_energy_points += 1.0


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
		func(): EventBus.track_sprites_visibility_requested.emit(2, true)
	))

	# 1 – Clap along, earn 20 energy points → unlock ring 3 (Hi-hat)
	list.append(AchievementDef.new(
		func() -> bool: return true,
		"klap 👏 mee op de beat, verzamel 20 energie punten⚡voor een Hi-hat geluid.",
		20.0,
		func(): EventBus.track_sprites_visibility_requested.emit(3, true)
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
			if layer_voice_over_1 and layer_voice_over_1.get("big_line") != null:
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
		func() -> bool: return SongState.sections.size() > 1,
		"Als je een nieuwe laag toevoegt, kan je hier een heel liedje opnemen."
	))

	# 5 – First recorded sample → gift unlock
	list.append(AchievementDef.new(
		func() -> bool:
			if SongState.current_section == null or SongState.current_section.tracks.size() <= 2:
				return false
			return SongState.current_section.tracks[2].recording_data != null,
		"Een cadeautje van mij! neem met deze 🎤 microfoon een kort hard geluid op hem te gebruiken als instrument in de ring."
	))

	# 6 – Second recorded sample
	list.append(AchievementDef.new(
		func() -> bool:
			if SongState.current_section == null or SongState.current_section.tracks.size() <= 3:
				return false
			return SongState.current_section.tracks[3].recording_data != null,
		"Kan je hier voor mij een kort gek geluid opnemen?"
	))

	return list


# ── Nodes that can be unlocked ───────────────────────────────────────────────

func _get_nodes() -> Array[Node2D]:
	return unlockable_nodes


# ── Core lifecycle ───────────────────────────────────────────────────────────

func _setup_blockers() -> void:
	var nodes := _get_nodes()
	for node in nodes:
		var blocker := _find_blocker(node)
		if blocker:
			_set_blocker_state(blocker, use_achievements)


func _update_achievements() -> void:
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
		var enough_worth: bool = _energy_points > worth
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
					_energy_points -= worth
					if _energy_points < 0.0:
						_energy_points = 0.0
					_play_achievement_sfx()
					if ach.result.is_valid():
						ach.result.call()
					EventBus.achievement_done.emit(i)

	if not _done_late_ready:
		_init_tooltip_actions(nodes, achievements)
		_setup_default_ui_state()
		_done_late_ready = true


# ── Tooltip / blocker interaction ────────────────────────────────────────────

func _init_tooltip_actions(nodes: Array[Node2D], achievements: Array[AchievementDef]) -> void:
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
					if achievements_panel and achievements_panel.visible:
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
		var enough_worth: bool = _energy_points > worth
		if blocker == target_blocker:
			if use_worth and enough_worth:
				return false
	return true


func open_tooltip(node: Node2D) -> void:
	var nodes := _get_nodes()
	var achievements := _get_achievements()
	var index := nodes.find(node)
	if index < 0 or index >= achievements.size():
		return
	if achievements_panel:
		achievements_panel.visible = true
	if instruction_label:
		instruction_label.text = achievements[index].tooltip
	_speak_tooltip(index)


func close_tooltip() -> void:
	if instruction_label:
		instruction_label.text = ""
	if achievements_panel:
		achievements_panel.visible = false
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()


func _start_loop_to_check_if_tooltip_can_close() -> void:
	get_tree().create_timer(0.4).timeout.connect(func():
		if DisplayServer.tts_is_speaking():
			_start_loop_to_check_if_tooltip_can_close()
		else:
			close_tooltip()
	)


# ── TTS ──────────────────────────────────────────────────────────────────────

func _speak_tooltip(index: int) -> void:
	if mute_speech_button and mute_speech_button.button_pressed:
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


func _set_blocker_state(blocker: Control, enabled: bool) -> void:
	blocker.visible = enabled
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func unlock_all_achievements() -> void:
	var nodes := _get_nodes()
	for node in nodes:
		var blocker := _find_blocker(node)
		if blocker:
			_set_blocker_state(blocker, false)
	EventBus.all_achievements_unlocked.emit()


# ── Default UI state ─────────────────────────────────────────────────────────

func _setup_default_ui_state() -> void:
	EventBus.track_sprites_visibility_requested.emit(2, false)
	EventBus.track_sprites_visibility_requested.emit(3, false)
	if layer_voice_over_1 and layer_voice_over_1.get("big_line") != null:
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


func _on_pause_timeout() -> void:
	_paused = false


# ── SFX helper ───────────────────────────────────────────────────────────────

func _play_achievement_sfx() -> void:
	if audio_player_manager:
		EventBus.play_sfx_requested.emit(audio_player_manager.achievement_sfx)

# ── Beat counting ────────────────────────────────────────────────────────────

func _active_beats_per_ring(ring_index: int) -> int:
	var section: SectionData = SongState.current_section
	if section == null or ring_index < 0 or ring_index >= SectionData.SAMPLE_TRACKS_PER_SECTION:
		return 0
	var count: int = 0
	for beat_index in range(SongState.total_beats):
		if section.get_beat(ring_index, beat_index):
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
	return use


func check_if_achievements_mode_should_be_active() -> void:
	use_achievements = _read_use_achievements()


func reset() -> void:
	check_if_achievements_mode_should_be_active()
	_done_late_ready = false
	_paused = true
	_timer = null
	_energy_points = 0.0
