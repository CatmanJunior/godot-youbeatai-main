using Godot;
using System;

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
            OnBpmChanged.Invoke(_bpm);
        }
    }

    // timing
    public int beatsAmount = 32;
    public bool playing = false;
    public int currentBeat = 31;
    public float beatTimer = 0;
    public float swing = 0.5f;

    // events
    public Action OnBeatEvent = () => {};
    public Action<int> OnBpmChanged = (bpm) => {};

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
            var timePerBeat = (currentBeat % 2 == 1) ? baseTimePerBeat * (1 + swing) : baseTimePerBeat * (1 - (swing / 2));
            if (beatTimer > timePerBeat)
            {
                beatTimer -= timePerBeat;
                currentBeat = (currentBeat + 1) % beatsAmount;
                OnBeatEvent.Invoke();
            }
        }
    }
}