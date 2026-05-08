extends Control

var bus_index = AudioServer.get_bus_index(BusNames.MASTER_BUS)

var phaser
var distortion
var highpass
var lowpass

@export var klappy_light: PointLight2D
@export var face_light: SpotLight3D

var unlocked := false
var start_energy
var flicker_done = false

var colors_string :Array[String] = ["green", "red", "blue", "yellow", "green", "red", "blue", "yellow"]

@export var instruction_label: Label
@export var achievement_panel: Panel
@export var colormapje: Node3D

func _ready() -> void:
	EventBus.energy_points_changed.connect(on_klappy_energy)
	bus_index = AudioServer.get_bus_index(BusNames.SUBMASTER_BUS)

	phaser = AudioServer.get_bus_effect(bus_index, 0) as AudioEffectPhaser
	distortion = AudioServer.get_bus_effect(bus_index, 1) as AudioEffectDistortion
	highpass = AudioServer.get_bus_effect(bus_index, 2) as AudioEffectHighPassFilter
	lowpass = AudioServer.get_bus_effect(bus_index, 3) as AudioEffectLowPassFilter

	AudioServer.set_bus_effect_enabled(bus_index, 0, false)
	AudioServer.set_bus_effect_enabled(bus_index, 1, false)
	AudioServer.set_bus_effect_enabled(bus_index, 2, false)
	AudioServer.set_bus_effect_enabled(bus_index, 3, false)
	
	start_energy = klappy_light.energy

	unlocked = false
	klappy_light.visible = true
	colormapje.visible = false

	
	if not GameState.tutorial_activated:
		EventBus.utterance_ended.connect(_on_utterance_end)

func _on_gui_input(event: InputEvent) -> void:
	if unlocked == true:
		colormapje.visible = true
		if event is InputEventMouseButton:
			AudioServer.set_bus_effect_enabled(bus_index, 0, event.is_pressed())
			AudioServer.set_bus_effect_enabled(bus_index, 1, event.is_pressed())
			AudioServer.set_bus_effect_enabled(bus_index, 2, event.is_pressed())
			AudioServer.set_bus_effect_enabled(bus_index, 3, event.is_pressed())
			
			if event.is_released(): # wanneer muis losgelaten word pos 100,100 en klaplight normaal
				var pos = Vector2(100, 100)
				$cursor.position = pos
				colormapje.visible = true
				klappy_light.visible = false

		
		if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
			var pos = event.position
			
			pos.x = clamp(pos.x, 0, size.x) # zorgt dat je binnen het grid blijft
			pos.y = clamp(pos.y, 0, size.y)
			
			$cursor.position = pos
			
			var x_percent = pos.x / size.x # ipv pixels maakt hij er 200/0 van
			var y_percent = 1.0 - (pos.y / size.y)
			
			phaser.depth = clamp(1.0 - x_percent * 2.0, 0.0, 1.0)
			distortion.drive = clamp((x_percent - 0.5) * 2.0, 0.0, 1.0)
			highpass.resonance = 0.5
			highpass.cutoff_hz = lerp(20.0, 2000.0, clamp((y_percent - 0.5) * 2.0, 0.0, 1.0))
			lowpass.cutoff_hz = lerp(20000.0, 200.0, clamp((0.5 - y_percent) * 2.0, 0.0, 1.0))
			
			klappy_light.visible = true
			face_light.light_color = klappy_light.color
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

			klappy_light.color = color
			$cursor/Trail.default_color = color # trail word dezelfde kleur als light

func _set_klappy_light_energy(value: float) -> void:
	klappy_light.energy = value / 50.0

func on_klappy_energy(value: float) -> void:
	_set_klappy_light_energy(value)
	if value >= AchievementManager.ENERGY_THRESHOLD_LIGHT_PAD and not flicker_done:
		unlocked = true
		flicker_done = true
		if GameState.achievements_active:
			_fill_instruction_label("Wow! Beweeg je muis over mijn lampje en hoor wat er gebeurt!")
		lightFlicker()
		await get_tree().create_timer(7.0).timeout
		achievement_panel.visible = false
	
func lightFlicker():
	for i in colors_string:
		klappy_light.color = Color(i)
		
		await get_tree().create_timer(0.3).timeout
		
		
	colormapje.visible = true
	klappy_light.color = Color.WHITE	
	
func _fill_instruction_label(_name: String):
	if instruction_label == null: push_error("Label not found")
	instruction_label.text = _name
	_achievement_panel_visibility(0)
	_start_tts(_name)
	
func _achievement_panel_visibility(_utterance_id: int):
	if not achievement_panel.visible:
		achievement_panel.visible = true
		
func _start_tts(message: String):
	TTSHelper.speak(TTSHelper.text_without_emoticons(message))

func _on_utterance_end(_utterance):
	achievement_panel.visible = false
