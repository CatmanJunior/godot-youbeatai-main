extends Node
## Central façade for playing Klappy dialogue lines.
##
## Looks up a line by its [enum KlappyLine.Id] in the generated registry and plays it
## through TTS and/or the speech bubble, coordinating the two. Adds behaviour the raw
## [code]TTSHelper[/code] lacks:
##   • Queuing       — lines play one at a time instead of cutting each other off.
##   • Interruption  — a line flagged [member KlappyLineData.interrupt] clears the queue
##                     and plays immediately.
##   • Auto-hide     — the bubble hides shortly after a line finishes (unless it shows a
##                     continue button or another line is queued).
##
## Usage:
##   [codeblock]
##   KlappyVoice.say(KlappyLine.Id.ACH_FIRST_SAMPLE)
##   KlappyVoice.say(KlappyLine.Id.SOME_LINE, "Nog 3 te gaan")  # override the bubble title
##   # Dynamic templates: a line authored as "Nog {0} te gaan" filled at runtime.
##   KlappyVoice.say(KlappyLine.Id.COUNT_LEFT, "", [3])
##   [/codeblock]

const REGISTRY_PATH: String = "res://Resources/Klappy/klappy_lines_registry.tres"

## How long the bubble lingers after a line finishes before auto-hiding.
const AUTO_HIDE_LINGER_SEC: float = 0.6

## Reading time per word for bubble-only (non-spoken) lines before the queue advances.
const READING_SECONDS_PER_WORD: float = 0.35
const READING_SECONDS_MIN: float = 2.0

var _library: KlappyLineLibrary = null
var _queue: Array[KlappyLineData] = []
var _current: KlappyLineData = null
var _current_uid: int = -1
## Bumped on every play/hide so stale auto-hide timers can detect they were superseded.
var _generation: int = 0


func _ready() -> void:
	_library = load(REGISTRY_PATH) as KlappyLineLibrary
	if _library == null:
		push_error("KlappyVoice: failed to load line registry at %s" % REGISTRY_PATH)
	EventBus.utterance_ended.connect(_on_utterance_settled)
	EventBus.utterance_canceled.connect(_on_utterance_settled)
	EventBus.continue_button_pressed.connect(_on_continue_pressed)


## Plays the line identified by [param line_id] (a [enum KlappyLine.Id] value).
## [param override_title] replaces the line's authored title for this playback only.
## [param args] fills [code]{0}[/code], [code]{1}[/code]… placeholders in the line's text
## and title (see [method String.format]), enabling dynamic templates.
func say(line_id: int, override_title: String = "", args: Array = []) -> void:
	var line: KlappyLineData = _resolve(line_id)
	if line == null:
		push_warning("KlappyVoice: no line found for id %d" % line_id)
		return

	var effective: KlappyLineData = line
	if override_title != "" or not args.is_empty():
		effective = line.duplicate()
		if override_title != "":
			effective.title = override_title
		if not args.is_empty():
			effective.text = effective.text.format(args)
			effective.title = effective.title.format(args)

	if effective.interrupt:
		_queue.clear()
		_stop_current()
		_play(effective)
		return

	_queue.append(effective)
	if _current == null:
		_advance()


## Stops any current line, empties the queue and hides the bubble.
func clear() -> void:
	_queue.clear()
	_stop_current()
	_generation += 1
	EventBus.set_klappy_speech_bubble.emit("", "", false)


## Returns the authored main text for [param line_id], or "" if unknown.
## [param args] fills [code]{0}[/code], [code]{1}[/code]… placeholders (see [method String.format]).
## Useful for callers that need the CSV-authored text but run their own sequencing.
func line_text(line_id: int, args: Array = []) -> String:
	var line: KlappyLineData = _resolve(line_id)
	if line == null:
		return ""
	return line.text.format(args) if not args.is_empty() else line.text


# ── Internal ──────────────────────────────────────────────────────────────────

func _resolve(line_id: int) -> KlappyLineData:
	if _library == null:
		return null
	return _library.get_line(line_id)


func _advance() -> void:
	if _queue.is_empty():
		return
	_play(_queue.pop_front())


func _play(line: KlappyLineData) -> void:
	_generation += 1
	_current = line

	if line.use_bubble:
		EventBus.set_klappy_speech_bubble.emit(line.text, line.title, line.show_continue)

	if line.use_tts and not line.text.strip_edges().is_empty():
		_current_uid = TTSHelper.speak(line.text, line.rate)
		# Settles via _on_utterance_settled when the matching utterance ends.
		if _current_uid == -1:
			_settle_current()
	else:
		_current_uid = -1
		# No speech: continue lines wait for the button; others settle after a read delay.
		if not line.show_continue:
			_settle_after_delay(_reading_time(line.text))


func _stop_current() -> void:
	_current = null
	_current_uid = -1
	TTSHelper.stop_speaking()


func _settle_current() -> void:
	var finished: KlappyLineData = _current
	_current = null
	_current_uid = -1
	if not _queue.is_empty():
		_advance()
	elif finished != null and not finished.show_continue and finished.auto_close:
		_auto_hide()


func _reading_time(text: String) -> float:
	var words: int = text.strip_edges().split(" ", false).size()
	return maxf(READING_SECONDS_MIN, float(words) * READING_SECONDS_PER_WORD)


func _settle_after_delay(seconds: float) -> void:
	var gen: int = _generation
	await get_tree().create_timer(seconds).timeout
	if gen != _generation:
		return
	_settle_current()


func _auto_hide() -> void:
	var gen: int = _generation
	await get_tree().create_timer(AUTO_HIDE_LINGER_SEC).timeout
	if gen != _generation or _current != null:
		return
	EventBus.set_klappy_speech_bubble.emit("", "", false)


func _on_utterance_settled(uid: int) -> void:
	if _current == null or uid != _current_uid:
		return
	_settle_current()


func _on_continue_pressed() -> void:
	if _current != null and _current.show_continue:
		_settle_current()
