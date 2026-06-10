extends Label


func _ready():
	text = "versie: %s" % str(ProjectSettings.get_setting("application/config/version"))
