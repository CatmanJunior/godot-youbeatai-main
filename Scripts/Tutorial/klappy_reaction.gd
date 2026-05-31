extends Node


func _ready() -> void:
	EventBus.achievement_done.connect(_on_achievement_done)

func _on_achievement_done(i: int) -> void:
	print("Achievement %d done, showing instruction for it" % i)
	if not GameState.achievements_active:
		return
	match i:
		AchievementDef.AchievementNode.TRACK_2:
			KlappyVoice.say(KlappyLine.Id.ACH_TRACK_2)
		AchievementDef.AchievementNode.TRACK_3:
			KlappyVoice.say(KlappyLine.Id.ACH_TRACK_3)
		AchievementDef.AchievementNode.SYNTH_2:
			KlappyVoice.say(KlappyLine.Id.ACH_SYNTH_2)
		AchievementDef.AchievementNode.ADD_SECTION:
			KlappyVoice.say(KlappyLine.Id.ACH_ADD_SECTION)
		AchievementDef.AchievementNode.SONG_MODE:
			KlappyVoice.say(KlappyLine.Id.ACH_SONG_MODE)
		AchievementDef.AchievementNode.FIRST_SAMPLE:
			KlappyVoice.say(KlappyLine.Id.ACH_FIRST_SAMPLE)
		AchievementDef.AchievementNode.SECOND_SAMPLE:
			KlappyVoice.say(KlappyLine.Id.ACH_SECOND_SAMPLE)
		AchievementDef.AchievementNode.TEMPLATE_TIP:
			KlappyVoice.say(KlappyLine.Id.ACH_TEMPLATE_TIP)
