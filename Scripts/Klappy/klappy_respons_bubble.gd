extends Node2D
@onready var response_label:Label = $Panel/Label
@onready var response_panel:Panel = $Panel
@onready var continue_button:Button = $Panel/Continue

@onready var talking = $"../Robot/SubViewportContainer/SubViewport/Klappy"

signal continue_pressed


func fill_response_label(message):
	response_label.text = message

func change_panel_visibility(visibile):
	response_panel.visible = visibile
	if visibile:
		continue_button.animation_play.emit()
		talking.talking = true
	else:
		continue_button.animation_stop.emit()
		talking.talking = false


func _on_continue_pressed() -> void:
	continue_pressed.emit()
