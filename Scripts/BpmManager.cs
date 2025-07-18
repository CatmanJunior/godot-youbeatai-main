using Godot;
using System.IO;

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

    [Export]
    private bool _playing;
    public bool playing
    {
        set {
            if (_playing != value )
                EmitSignal(SignalName.OnPlayingChanged, value);
            _playing = value;
        }
        get => _playing;
    }

    public int currentBeat = beatsAmount - 1;
    public float beatTimer = 0;
    public float swing = 0.5f;
    
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
            baseTimePerBeat = 60f / bpm / 4;
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
