@tool
extends EditorPlugin

var inspector_plugin

func _enter_tree():
    inspector_plugin = preload("res://addons/beat_buttons_inspector/beat_inspector.gd").new()
    add_inspector_plugin(inspector_plugin)


func _exit_tree():
    remove_inspector_plugin(inspector_plugin)