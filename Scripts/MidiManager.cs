using Godot;
using System.Collections.Generic;

partial class MidiManager : Node
{
    public override void _Ready()
    {
		OS.OpenMidiInputs();
    	GD.Print(OS.GetConnectedMidiInputs());
    }

	public override void _Process(double delta)
    {
    }

	public override void _Input(InputEvent inputEvent)
	{
		if (inputEvent is InputEventMidi midiEvent)
		{
			/*
			GD.Print($"Channel {midiEvent.Channel}");
			GD.Print($"Message {midiEvent.Message}");
			GD.Print($"Pitch {midiEvent.Pitch}");
			GD.Print($"Velocity {midiEvent.Velocity}");
			GD.Print($"Instrument {midiEvent.Instrument}");
			GD.Print($"Pressure {midiEvent.Pressure}");
			GD.Print($"Controller number: {midiEvent.ControllerNumber}");
			GD.Print($"Controller value: {midiEvent.ControllerValue}");
			*/

			// bpm
			if (midiEvent.Message == MidiMessage.ControlChange && midiEvent.ControllerNumber == 92)
			{
				GD.Print($"BPM Change Detected: {midiEvent.ControllerValue}");
				BpmManager.instance.bpm = midiEvent.ControllerValue;
			}

			// notes
			if (midiEvent.Message == MidiMessage.NoteOn && midiEvent.Velocity > 0)
			{
				int pitch = midiEvent.Pitch;
				string noteName = GetNoteName(pitch);
				GD.Print($"Note Played: {noteName}");
			}

			// pitch
			if (midiEvent.Message == MidiMessage.PitchBend)
			{
				var scaled = Mathf.Clamp(Mathf.InverseLerp(0, 16000, midiEvent.Pitch), 0, 1);
				GD.Print($"Pitchblend: {scaled}");
			}
		}
	}

	private string GetNoteName(int pitch)
    {
		var NoteNames = new Dictionary<int, string>
		{
			{ 0, "C" },
			{ 1, "C#" },
			{ 2, "D" },
			{ 3, "D#" },
			{ 4, "E" },
			{ 5, "F" },
			{ 6, "F#" },
			{ 7, "G" },
			{ 8, "G#" },
			{ 9, "A" },
			{ 10, "A#" },
			{ 11, "B" }
		};

        int octave = (pitch / 12) - 1;
        int noteIndex = pitch % 12;
        string note = NoteNames.ContainsKey(noteIndex) ? NoteNames[noteIndex] : "Unknown";
        return $"{note}{octave}";
    }
}