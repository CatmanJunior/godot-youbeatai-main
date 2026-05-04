extends Control

var bus_index = AudioServer.get_bus_index("Master")

var phaser
var distortion
var highpass
var lowpass

@export var klappyLight: PointLight2D 
@export var KlappyEnergy: ProgressBar

var unlocked:= false
var start_energy
var flicker_done = false

var colors = ["green", "red", "blue", "yellow","green", "red", "blue", "yellow"]

@export var instruction_label:Label

@export var achievement_panel:Panel

func _ready() -> void:
	# TODO: GET THIS THE HELL OUT OF HERE
	bus_index = AudioServer.get_bus_index("SubMaster")

	phaser = AudioEffectPhaser.new()
	distortion = AudioEffectDistortion.new()
	highpass = AudioEffectHighPassFilter.new()
	lowpass = AudioEffectLowPassFilter.new()

	AudioServer.add_bus_effect(bus_index, phaser)
	AudioServer.add_bus_effect(bus_index, distortion)
	AudioServer.add_bus_effect(bus_index, highpass)
	AudioServer.add_bus_effect(bus_index, lowpass)
	
	AudioServer.set_bus_effect_enabled(bus_index, 0, false)
	AudioServer.set_bus_effect_enabled(bus_index, 1, false)
	AudioServer.set_bus_effect_enabled(bus_index, 2, false)
	AudioServer.set_bus_effect_enabled(bus_index, 3, false)
	
	start_energy = klappyLight.energy
	
	unlocked = false
	
	if KlappyEnergy != null:
		KlappyEnergy.value_changed.connect(on_klappy_energy)
		
	assert(GameState!= null,"manger not found")
	if not GameState.tutorial_activated:
		EventBus.utterance_ended.connect(_on_utterance_end)

func _on_gui_input(event: InputEvent) -> void:
	if unlocked == true:
		klappyLight.energy = 0.5
		if event is InputEventMouseButton:
			AudioServer.set_bus_effect_enabled(bus_index, 1, event.is_pressed())
			AudioServer.set_bus_effect_enabled(bus_index, 2, event.is_pressed())
			AudioServer.set_bus_effect_enabled(bus_index, 3, event.is_pressed())
			AudioServer.set_bus_effect_enabled(bus_index, 4, event.is_pressed())
			
			if event.is_released(): #wanneer muis losgelaten word pos 100,100 en klaplight normaal 
				var pos = Vector2(100, 100)
				$cursor.position = pos
				klappyLight.color = Color("#ffe8aa")
		
		if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
			var pos = event.position
			
			pos.x = clamp(pos.x, 0, size.x) #zorgt dat je binnen het grid blijft
			pos.y = clamp(pos.y, 0, size.y)
			
			$cursor.position = pos 
			
			var x_percent = pos.x / size.x #ipv pixels maakt hij er 200/0 van
			var y_percent = 1.0 - (pos.y / size.y)
			
			phaser.depth = clamp(1.0 - x_percent * 2.0, 0.0, 1.0)
			distortion.drive = clamp((x_percent - 0.5) * 2.0, 0.0, 1.0)
			highpass.resonance = 0.5
			highpass.cutoff_hz = lerp(20.0, 2000.0, clamp((y_percent - 0.5) * 2.0, 0.0, 1.0))
			lowpass.cutoff_hz = lerp(20000.0, 200.0, clamp((0.5 - y_percent) * 2.0, 0.0, 1.0))
			
			
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
			$cursor/Trail.default_color = color #trail word dezelfde kleur als light
			
func on_klappy_energy(value):
	if value >= 100 and not flicker_done:  
		unlocked = true
		flicker_done = true
		_fill_instruction_label("Wow! Beweeg je muis over mijn lampje en hoor wat er gebeurt!")
		lightFlicker()
	
func lightFlicker():
	for i in colors:
		klappyLight.color = i
		klappyLight.energy = 2
		await get_tree().create_timer(0.3).timeout
		klappyLight.energy = start_energy
		
	klappyLight.color = Color("#ffe8aa")
	
	
func _fill_instruction_label(_name:String):
	if instruction_label == null : push_error("Label not found")
	instruction_label.text = _name
	_achievement_panel_visibility(0)
	_start_tts(_name)
	
func _achievement_panel_visibility(_utterance_id:int):
	if not achievement_panel.visible :
		achievement_panel.visible = true
		
func _start_tts(message:String):
	TTSHelper.speak(TTSHelper.text_without_emoticons(message))

func _on_utterance_end(_utterance):
	achievement_panel.visible = false
