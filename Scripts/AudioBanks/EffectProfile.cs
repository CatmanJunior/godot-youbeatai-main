using Godot;

[GlobalClass]
public partial class EffectProfile : Resource
{
    [Export] public float pitch_shift {get;set;}
    [Export] public float distortion_db	{get;set;}
    [Export] public float phaser {get;set;}
    [Export] public float delay {get;set;}
    [Export] public float reverb {get;set;}

    public void Apply(int bus_index)
    {
        AudioEffectPitchShift pitch = AudioServer.GetBusEffect(bus_index, 0) as AudioEffectPitchShift;
        AudioServer.SetBusEffectEnabled(bus_index, 0, pitch_shift > 0);
        pitch.PitchScale = pitch_shift > 0? pitch_shift: 1;

        AudioEffectDistortion distortion = AudioServer.GetBusEffect(bus_index, 1) as AudioEffectDistortion;
        AudioServer.SetBusEffectEnabled(bus_index, 1, distortion_db > 0);
        distortion.PreGain = distortion_db;

        AudioEffectPhaser phaser = AudioServer.GetBusEffect(bus_index, 2) as AudioEffectPhaser;
        AudioServer.SetBusEffectEnabled(bus_index, 2, this.phaser > 0);
        if(this.phaser > 0)
            phaser.RateHz = this.phaser;

        // AudioEffectDelay delay = AudioServer.GetBusEffect(bus_index, 3) as AudioEffectDelay;
        // AudioServer.SetBusEffectEnabled(bus_index, 3, this.delay > 0);
        // if (this.delay > 0)
        // {
        //     delay.Tap1DelayMs = this.delay;
        //     delay.Tap2DelayMs = this.delay * 2;
        // }

        AudioEffectReverb reverb = AudioServer.GetBusEffect(bus_index, 4) as AudioEffectReverb;
        AudioServer.SetBusEffectEnabled(bus_index, 4, this.reverb > 0);
        if(this.reverb > 0)
            reverb.RoomSize = this.reverb;
    }

    public EffectProfile() { }
}