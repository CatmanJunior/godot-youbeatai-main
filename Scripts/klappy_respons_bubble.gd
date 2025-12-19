extends Node2D
@onready var response_label:Label = $Panel/Label
@onready var response_panel:Panel = $Panel
@onready var continue_button:Button = $Panel/Continue
signal continue_pressed


func fill_response_label(message):
	response_label.text = message

func change_panel_visibility(visibile):
	response_panel.visible = visibile
	if visibile:
		continue_button.animation_play.emit()
	else:
		continue_button.animation_stop.emit()


func _on_continue_pressed() -> void:
	continue_pressed.emit()
