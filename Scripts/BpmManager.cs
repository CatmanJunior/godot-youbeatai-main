using Godot;
using System.IO;

[GlobalClass]
public partial class BpmManager : Node
{
    public static BpmManager instance = null;

    // bpm
    private int _bpm = 120;
    [Export]
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
    public int amount_of_beats => beatsAmount;
    private static int ReadBeatsAmount()
    {
        int amount;
        try
        {
            string path = Path.Combine(ProjectSettings.GlobalizePath("user://"), "beats_amount.txt");
            string content = File.ReadAllText(path);
            amount = int.Parse(content);
            if (File.Exists(path)) File.Delete(path);
        }
        catch
        {
            amount = 16;
        }

        return amount;
    }


    private bool _playing;
    [Export]
    public bool playing
    {
        set
        {
            if (_playing != value)
                EmitSignal(SignalName.OnPlayingChanged, value);
            _playing = value;
        }
        get => _playing;
    }

    [Export] public int currentBeat = beatsAmount - 1;
    public float beatTimer = 0;
    [Export] public float swing = 0.5f;

    public float baseTimePerBeat;
    public float timePerBeat;

    // events
    [Signal]
    public delegate void OnBeatEventEventHandler();
    [Signal]
    public delegate void OnBpmChangedEventHandler(float bpm);

    [Signal]
    public delegate void OnPlayingChangedEventHandler(bool playing);

    public override void _Ready()
    {
        instance ??= this;
    }

    public override void _Process(double delta)
    {
        if (playing)
        {
            beatTimer += (float)delta;
            float beats_per_bar = 4;
            baseTimePerBeat = 60f / bpm / beats_per_bar;
            timePerBeat =
                (currentBeat % 2 == 1) ?
                    baseTimePerBeat + (baseTimePerBeat * swing)
                    : baseTimePerBeat - (baseTimePerBeat * swing);

            if (beatTimer > timePerBeat)
            {
                beatTimer -= timePerBeat;
                currentBeat = (currentBeat + 1) % beatsAmount;
                EmitSignal(SignalName.OnBeatEvent);
            }
        }
    }
}
