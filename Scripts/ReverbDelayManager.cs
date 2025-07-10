using Godot;

public partial class ReverbDelayManager : Node
{
    public static ReverbDelayManager instance = null;

	[Export] public Slider reverbSlider;
	[Export] public Slider delaySlider;

	AudioEffectReverb reverbEffect;
    AudioEffectDelay delayEffect;

    public override void _Ready()
    {
        instance ??= this;
        reverbEffect = new AudioEffectReverb();
        delayEffect = new AudioEffectDelay();
        AudioServer.AddBusEffect(AudioServer.GetBusIndex("Master"), reverbEffect);
        AudioServer.AddBusEffect(AudioServer.GetBusIndex("Master"), delayEffect);
    }

    public override void _Process(double delta)
    {
        SetReverbLevel((float)reverbSlider.Value);
        SetDelayLevel((float)delaySlider.Value);
    }

    private void SetReverbLevel(float level)
    {
        AudioServer.SetBusEffectEnabled(AudioServer.GetBusIndex("Master"), 0, level > 0);
        reverbEffect.Wet = level;
        reverbEffect.RoomSize = level;
    }

    private void SetDelayLevel(float level)
    {
        AudioServer.SetBusEffectEnabled(AudioServer.GetBusIndex("Master"), 1, level > 0);
        delayEffect.Tap1Active = true;
        delayEffect.Tap2Active = false;
        delayEffect.Tap1DelayMs = level * 1000f;
        delayEffect.Tap1LevelDb = -20;
    }
}