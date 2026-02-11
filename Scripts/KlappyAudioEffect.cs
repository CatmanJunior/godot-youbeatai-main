using Godot;

public partial class KlappyAudioEffect : Sprite2D
{

    [Export] public Slider HighPassSlider;
    [Export] public Slider PhaserSlider;

    AudioEffectHighPassFilter HighPassEffect;
    AudioEffectPhaser PhaserEffect;

    public override void _Ready()
    {
        HighPassEffect = new AudioEffectHighPassFilter();
        PhaserEffect = new AudioEffectPhaser();
        AudioServer.AddBusEffect(AudioServer.GetBusIndex("Master"), HighPassEffect);
        AudioServer.AddBusEffect(AudioServer.GetBusIndex("Master"), PhaserEffect);
    }

    public override void _Process(double delta)
    {
        SetHighPassLevel((float)HighPassSlider.Value);
        SetPhaserLevel((float)PhaserSlider.Value);
    }

    private void SetHighPassLevel(float level)
    {
        AudioServer.SetBusEffectEnabled(AudioServer.GetBusIndex("Master"), 0, level > 0);
        //HighPassEffect.CutoffHz = Mathf.Lerp(20f, 5000f, level);
        //HighPassEffect.Resonance = Mathf.Lerp(0.1f, 1.5f, level);
    }

    private void SetPhaserLevel(float level)
    {
        AudioServer.SetBusEffectEnabled(AudioServer.GetBusIndex("Master"), 1, level > 0);
        //PhaserEffect.RateHz = Mathf.Lerp(0.1f, 5f, level);
        //PhaserEffect.Feedback = Mathf.Lerp(0f, 0.8f, level);
    }
}
