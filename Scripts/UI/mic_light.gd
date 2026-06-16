extends PointLight2D

func _process(_delta: float) -> void:
    var mic_volume = BusHelper.get_volume(BusNames.MICROPHONE_BUS)
    self.energy = mic_volume * 8.0