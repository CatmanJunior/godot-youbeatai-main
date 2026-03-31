class_name AudioBank
extends Resource

@export var kick: AudioStream
@export var kick_alt: AudioStream

@export var snare: AudioStream
@export var snare_alt: AudioStream

@export var clap: AudioStream
@export var clap_alt: AudioStream

@export var closed: AudioStream
@export var closed_alt: AudioStream

@export var green_soundfont: Resource
@export var green_instrument_id: int
@export var green_beats: float
@export var green_effectProfile: EffectProfile

@export var purple_soundfont: Resource
@export var purple_instrument_id: int
@export var purple_beats: float




#getters for synth tracks (not stored directly on the bank, but derived from the main synth settings)


var synth1_soundfont: Resource = null:
    get:
        return green_soundfont

var synth1_instrument_id: int = 0:
    get:
        return green_instrument_id

var synth1_beats: float = 0.0:
    get:
        return green_beats

var synth1_effectProfile: EffectProfile = null:
    get:
        return green_effectProfile

var synth2_soundfont: Resource = null:
    get:
        return purple_soundfont

var synth2_instrument_id: int = 0:
    get:
        return purple_instrument_id

var synth2_beats: float = 0.0:
    get:
        return purple_beats

var synth2_effectProfile: EffectProfile = null:
    get:
        return green_effectProfile

var effectProfile: EffectProfile = null:
    get:
        # If the synths have their own effect profile, use that. Otherwise fall back to the main one.
        return green_effectProfile