extends Control

var bus_index = AudioServer.get_bus_index("Master")

var phaser
var distortion
var highpass
var lowpass

@export var klappyLight: PointLight2D 

func _ready() -> void:
	bus_index = AudioServer.get_bus_index("Master")

	phaser = AudioEffectPhaser.new()
	distortion = AudioEffectDistortion.new()
	highpass = AudioEffectHighPassFilter.new()
	lowpass = AudioEffectLowPassFilter.new()

	AudioServer.add_bus_effect(bus_index, phaser)
	AudioServer.add_bus_effect(bus_index, distortion)
	AudioServer.add_bus_effect(bus_index, highpass)
	AudioServer.add_bus_effect(bus_index, lowpass)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT: #hier logica touchscreen bij
		var pos = event.position
		
		pos.x = clamp(pos.x, 0, size.x) #zorgt dat je binnen het grid blijft
		pos.y = clamp(pos.y, 0, size.y)
		
		$cursor.position = pos 
		
		var x_percent = pos.x / size.x #ipv pixels maakt hij er 200/0 van
		var y_percent = 1.0 - (pos.y / size.y)
		
		phaser.depth = 1.0 - x_percent
		distortion.drive = x_percent
		highpass.cutoff_hz = lerp(40.0, 1000.0, y_percent)
		lowpass.cutoff_hz = lerp(4000.0, 40.0, y_percent)
		
		#print(pos)
		
		#klappys lampje word veranderd van kleur op basis van muis positie in het vak
		var color := Color("#ffe8aa")
		var strength := 0.8
#het midden is 100 dus vanaf daar meten (0-200)
		if pos.x >= 130:
			color = color.lerp(Color.RED, strength)
		if pos.x <= 70:
			color = color.lerp(Color.GREEN, strength)
		if pos.y >= 130:
			color = color.lerp(Color.BLUE, strength)
		if pos.y <= 70:
			color = color.lerp(Color.YELLOW, strength)

		klappyLight.color = color 
