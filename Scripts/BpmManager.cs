using Godot;
using System;
using System.IO;
using System.Text.Json;

public partial class BpmManager : Node
{
    public static BpmManager instance = null;

    // bpm
    private int _bpm = 120;
    public int bpm
    {
        get => _bpm;
        set
        {
            _bpm = value;
            EmitSignal(SignalName.OnBpmChanged, _bpm);
        }
    }

    // timing
    public static int beatsAmount = ReadBeatsAmount();

    private static int ReadBeatsAmount()
    {
        string path = Path.Combine(ProjectSettings.GlobalizePath("user://"), "beats_amount.txt");

        int amount = int.Parse(File.ReadAllText(path));

        File.Delete(path);

        return amount;
    }


    public bool playing = false;
    public int currentBeat = beatsAmount - 1;
    public float beatTimer = 0;
    public float swing = 0.5f;
    public float timePerBeat;

    // events
    [Signal]
    public delegate void OnBeatEventEventHandler();
    [Signal]
    public delegate void OnBpmChangedEventHandler(float bpm);

    public override void _Ready()
    {
        instance ??= this;
    }

    public override void _Process(double delta)
    {
        if (playing)
        {
            beatTimer += (float)delta;
            var baseTimePerBeat = 60f / bpm / 2;
            timePerBeat = (currentBeat % 2 == 1) ? baseTimePerBeat * (1 + swing) : baseTimePerBeat * (1 - (swing / 2));
            if (beatTimer > timePerBeat)
            {
                beatTimer -= timePerBeat;
                currentBeat = (currentBeat + 1) % beatsAmount;
                EmitSignal(SignalName.OnBeatEvent);
            }
        }
    }
}
