class_name KlappyLineData
extends Resource
## A single Klappy dialogue line, authored in [code]Data/klappy_lines.csv[/code] and
## generated into a [code].tres[/code] by [code]Scripts/Tools/klappy_lines_importer.gd[/code].
##
## Looked up at runtime by [member id] (a [enum KlappyLine] value) via the generated
## registry and played through the [code]KlappyVoice[/code] autoload.

## The unique line identifier. Matches a value of the generated [enum KlappyLine].
@export var id: int = -1

## The main text shown in the speech bubble and spoken via TTS.
@export_multiline var text: String = ""

## Optional secondary title text shown above the main text in the bubble.
@export var title: String = ""

## Whether this line should be spoken via text-to-speech.
@export var use_tts: bool = true

## Whether this line should display the speech bubble.
@export var use_bubble: bool = true

## Whether the bubble shows the "continue" button (gates progression on a tap).
@export var show_continue: bool = false

## Whether this line clears the queue and plays immediately, cutting off the current line.
@export var interrupt: bool = false

## TTS speech rate multiplier (1.0 = normal speed).
@export var rate: float = 1.0
