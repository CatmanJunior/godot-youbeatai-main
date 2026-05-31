extends Node

@export var message: String
@export var tutmessage: String

enum _State { IDLE, INTRO_PLAYING, DONE }
var _state: _State = _State.IDLE
var _uid: int = -1


func _ready() -> void:
	EventBus.utterance_ended.connect(_on_utterance_settled)
	EventBus.utterance_canceled.connect(_on_utterance_settled)
	# Wait for everything to be ready before speaking; TTS may not work immediately on web.
	await get_tree().create_timer(0.5).timeout
	_uid = TTSHelper.say(KlappyVoice.line_text(KlappyLine.Id.INTRO_GREETING))
	_state = _State.INTRO_PLAYING


func _on_utterance_settled(id: int) -> void:
	if id != _uid:
		return
	match _state:
		_State.INTRO_PLAYING:
			var msg: String = tutmessage if GameState.use_tutorial else message
			if msg.is_empty():
				_state = _State.DONE
				_disconnect_listeners()
				return
			_state = _State.DONE
			_uid = TTSHelper.say(msg)
		_State.DONE:
			_disconnect_listeners()


func _disconnect_listeners() -> void:
	if EventBus.utterance_ended.is_connected(_on_utterance_settled):
		EventBus.utterance_ended.disconnect(_on_utterance_settled)
	if EventBus.utterance_canceled.is_connected(_on_utterance_settled):
		EventBus.utterance_canceled.disconnect(_on_utterance_settled)

