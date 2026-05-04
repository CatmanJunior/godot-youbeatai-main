extends Node2D
@onready var response_label:Label = $Panel/Label
@onready var response_panel:Panel = $Panel
@onready var continue_button:Button = $Panel/Continue

@export var talking : Node

signal continue_pressed


func fill_response_label(message):
	response_label.text = message

func change_panel_visibility(visibile):
	response_panel.visible = visibile
	if visibile:
		talking.talking = true
	else:
		talking.talking = false


func _on_continue_pressed() -> void:
	continue_pressed.emit()
