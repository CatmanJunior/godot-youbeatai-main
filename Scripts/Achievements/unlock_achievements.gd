extends Button

var unlocked = false

#TODO: make this a singleton and add a function to unlock all achievements, then call that function from the manager when all achievements are unlocked. This is just for testing purposes, so we can see the achievement popups without having to unlock them all manually.

#func _ready() -> void:
	#assert(manager != null,"Manager not found")
	#if OS.is_debug_build():
		#visible = true

#func _on_pressed() -> void:
	#if unlocked:return
	#manager.OnAllAchievementUnlocked.emit()
