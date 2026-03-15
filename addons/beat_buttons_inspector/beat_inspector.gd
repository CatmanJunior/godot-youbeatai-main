@tool
extends EditorInspectorPlugin


func _can_handle(object):
    return true


func _parse_property(object, type, name, hint, hint_text, usage, wide):

    if name == "beats_active" and type == TYPE_ARRAY:

        var container = VBoxContainer.new()

        var values: Array = object.get(name)

        # ensure array has 4 rows
        if values.size() != 4:
            values.resize(4)
            for i in range(4):
                if values[i] == null:
                    values[i] = 0
            object.set(name, values)

        for row in range(4):
            
            var hbox : HBoxContainer = HBoxContainer.new()
            
            for col in range(16):

                var cb = CheckBox.new()
                cb.text = ""
                
                var bit := 1 << col
                cb.button_pressed = (values[row] & bit) != 0

                cb.toggled.connect(func(pressed, r=row, c=col):

                    var arr = object.get(name)

                    var v = arr[r]
                    var mask = 1 << c

                    if pressed:
                        v |= mask
                    else:
                        v &= ~mask

                    arr[r] = v
                    object.set(name, arr)

                )

                hbox.add_child(cb)

            container.add_child(hbox)

        add_custom_control(container)
        return true

    return false