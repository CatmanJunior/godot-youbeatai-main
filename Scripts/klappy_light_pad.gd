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

	#nog iets dat je eerst op lampje moet klikken

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT: #hier logica touchscreen bij
		var pos = event.position
		
		pos.x = clamp(pos.x, 0, size.x) #zorgt dat je binnen het grid blijft
		pos.y = clamp(pos.y, 0, size.y)
		
		$cursor.position = pos 
		
		var x_percent = pos.x / size.x #ipv pixels maakt hij er 1/0 van
		var y_percent = 1.0 - (pos.y / size.y)
		
		phaser.depth = 1.0 - x_percent
		distortion.drive = x_percent
		highpass.cutoff_hz = lerp(40.0, 4000.0, y_percent)
		lowpass.cutoff_hz = lerp(4000.0, 40.0, y_percent)
		
		#print(pos)
		
		#dit werkt maar omdat red bovenstaat zal hij rechtsbovenin altijd rood worden enz
		if pos.x == 200:
			klappyLight.color = "red"
		elif pos.x == 0:
			klappyLight.color = "green"
		elif pos.y == 200:
			klappyLight.color = "blue"
		elif pos.y == 0:
			klappyLight.color = "yellow"
			
		#elif pos.x == 0 && pos.y == 0:
			#klappyLight.color = "lightgreen"
		#elif pos.x == 200 && pos.y == 200:
			#klappyLight.color = "violet"
		#elif pos.x == 0 && pos.y == 200:
			#klappyLight.color = "teal"
		#elif pos.x == 200 && pos.y == 0:
			#klappyLight.color = "orange"

		else:
			klappyLight.color = "#ffe8aa"
			
