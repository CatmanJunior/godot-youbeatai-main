extends Button
@export var manager:Manager
var unlocked = false

#func _ready() -> void:
	#assert(manager != null,"Manager not found")
	#if OS.is_debug_build():
		#visible = true

#func _on_pressed() -> void:
	#if unlocked:return
	#manager.OnAllAchievementUnlocked.emit()
