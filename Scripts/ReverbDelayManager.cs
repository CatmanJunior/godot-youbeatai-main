using Godot;

public partial class ReverbDelayManager : Node
{
    public static ReverbDelayManager instance = null;

    public override void _ExitTree()
    {
        if (instance == this) instance = null;
    }

    [Export] public Slider reverbSlider;
    [Export] public Slider delaySlider;

    [Export] public Slider highLowPassSlider;
    [Export] public Slider phaserDistortionSlider;


    AudioEffectReverb reverbEffect;
    AudioEffectDelay delayEffect;

    AudioEffectHighPassFilter highPassEffect;
    AudioEffectLowPassFilter lowPassEffect;
    AudioEffectPhaser phaserEffect;
    AudioEffectDistortion distortionEffect;



    public override void _Ready()
    {
        instance ??= this;

        reverbEffect = new AudioEffectReverb();
        delayEffect = new AudioEffectDelay();

        highPassEffect = new AudioEffectHighPassFilter();
        lowPassEffect = new AudioEffectLowPassFilter();
        phaserEffect = new AudioEffectPhaser();
        distortionEffect = new AudioEffectDistortion();

        AudioServer.AddBusEffect(AudioServer.GetBusIndex("Master"), reverbEffect);
        AudioServer.AddBusEffect(AudioServer.GetBusIndex("Master"), delayEffect);

        AudioServer.AddBusEffect(AudioServer.GetBusIndex("Master"), highPassEffect);
        AudioServer.AddBusEffect(AudioServer.GetBusIndex("Master"), lowPassEffect);
        AudioServer.AddBusEffect(AudioServer.GetBusIndex("Master"), phaserEffect);
        AudioServer.AddBusEffect(AudioServer.GetBusIndex("Master"), distortionEffect);


    }

    public override void _Process(double delta)
    {
        SetReverbLevel((float)reverbSlider.Value);
        SetDelayLevel((float)delaySlider.Value);

        SetHighLowPassLevel((float)highLowPassSlider.Value);
        SetPhaserDistortionLevel((float)phaserDistortionSlider.Value);
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

    private void SetHighLowPassLevel(float value)
    {
        int bus = AudioServer.GetBusIndex("Master");

        bool enabled = Mathf.Abs(value - 0.5f) > 0.02f;

        AudioServer.SetBusEffectEnabled(bus, 2, enabled); // highpass
        AudioServer.SetBusEffectEnabled(bus, 3, enabled); // lowpass

        float minFreq = 40f;
        float maxFreq = 20000f;

        if (!enabled)
        {
            // niks
            highPassEffect.CutoffHz = minFreq;
            lowPassEffect.CutoffHz = maxFreq;
            return;
        }

        if (value < 0.5f)
        {
            // lowpass
            float t = value / 0.5f;

            lowPassEffect.CutoffHz = Mathf.Lerp(maxFreq, 300f, t);
            highPassEffect.CutoffHz = minFreq;
        }
        else
        {
            // highpass
            float t = (value - 0.5f) / 0.5f;

            highPassEffect.CutoffHz = Mathf.Lerp(minFreq, 4000f, t);
            lowPassEffect.CutoffHz = maxFreq;
        }
    }

    private void SetPhaserDistortionLevel(float value)
    {
        int bus = AudioServer.GetBusIndex("Master");

        bool enabled = Mathf.Abs(value - 0.5f) > 0.02f;

        AudioServer.SetBusEffectEnabled(bus, 4, enabled); // phaser
        AudioServer.SetBusEffectEnabled(bus, 5, enabled); // distortion

        if (!enabled)
        {
            //niks
            phaserEffect.Depth = 0f;
            distortionEffect.Drive = 0f;
            return;
        }

        if (value < 0.5f)
        {
            // phaser
            float t = value / 0.5f;

            phaserEffect.Depth = Mathf.Lerp(1.0f, 0.0f, t);
            distortionEffect.Drive = 0f;
        }
        else
        {
            // distortion
            float t = (value - 0.5f) / 0.5f;

            distortionEffect.Drive = Mathf.Lerp(0.0f, 1.0f, t);
            phaserEffect.Depth = 0f;
        }
    }
}