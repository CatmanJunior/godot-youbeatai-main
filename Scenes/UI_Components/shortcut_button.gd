class_name ShortcutButton
extends Button

var is_down := false

func _shortcut_input(event):
    if is_visible_in_tree():
        return

    if not shortcut.matches_event(event):
        return

    if not event.is_pressed():
        if is_down:
            is_down = false # reset pressed

        return

    if is_down:
        return # already down
    
    is_down = true
    pressed.emit()

