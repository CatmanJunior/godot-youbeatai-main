using Godot;

using System;
using System.IO;
using System.Threading.Tasks;
using System.Collections.Generic;

using NAudio.Wave;
using NAudio.Wave.SampleProviders;

public partial class RealTimeAudioRecording : Node
{
    public static RealTimeAudioRecording instance = null;

    public override void _ExitTree()
    {
        if (instance == this) instance = null;
    }

    public AudioStreamWav recording_result = null;
    public AudioEffectRecord audioEffectRecord;

    public bool shouldRecord = false;
    public bool recording = false;
    public float recordingTimer = 0;

    // other
    public float recordingLength = 0;
    public bool finished = false;

    // user interface
	[Export] public ProgressBar progressbar;
	[Export] public Button recordSongButton;
	[Export] public Sprite2D recordSongSprite;

    public override void _Ready()
    {
        // init singleton
        instance ??= this;

        // init record button
        recordSongButton.Pressed += OnButton;

        // setup record effect
        var masterAudioBus = AudioServer.GetBusIndex("SubMaster");
        audioEffectRecord = (AudioEffectRecord)AudioServer.GetBusEffect(masterAudioBus, 0);
    }

    public override void _Process(double delta)
    {
        // set color of fake button
        ((RecordButton)recordSongButton.GetParent()).pressed = shouldRecord;

        // update recording timer
        if (recording) recordingTimer += (float)delta;
        else recordingTimer = 0;

        // set progress bar value
        if (recording) progressbar.Value = recordingTimer / (Manager.instance.layersAmount * (BpmManager.beatsAmount * BpmManager.instance.baseTimePerBeat));
        
        // debug
        if (Input.IsActionJustPressed("f1"))
        {
            if (!recording) StartRecordingMaster();
            else StopRecordingMaster();
        }
    }

    public void StartRecordingMaster()
    {
        GD.Print("Starting Recording");
        recording = true;
        audioEffectRecord.SetRecordingActive(true);

        // also record voice over
        SongVoiceOver.instance.shouldRecord = true;

        // disable buttons during recording
        DisableButtons(true);

        Manager.instance.metronome_toggle.ButtonPressed = false;

        Manager.instance.CloseCountDown();
    }

    public void OnTop()
    {
        if (recording) StopRecordingMaster();
        else if (shouldRecord) StartRecordingMaster();
    }

    public void OnButton()
    {
        Manager.instance.layerLoopToggle.ButtonPressed = true;
        shouldRecord = !shouldRecord;

        // metronoom aan
        Manager.instance.metronome_toggle.ButtonPressed = true;

        // 4 beats voor de eerste noot op eerste laag
        Manager.instance.SwitchLayer(Manager.instance.layersAmount - 1);
        BpmManager.instance.currentBeat = BpmManager.beatsAmount / 2;
        
        // playing true
        BpmManager.instance.playing = true;

        // also play metronome sound on first beat
        Manager.instance.PlayExtraSFX(Manager.instance.metronome_sfx);

        Manager.instance.ShowCountDown();
    }

    public void StopRecordingMaster()
    {
        GD.Print("Stopping Recording");
        recording = false;
        shouldRecord = false;
        audioEffectRecord.SetRecordingActive(false);
        recording_result = audioEffectRecord.GetRecording();

        recordingLength = recordingTimer;
        finished = true;

        // re-enable buttons during recording
        DisableButtons(false);
    }

    private void DisableButtons(bool Disabled)
    {
        SongVoiceOver.instance.snellerButton.Disabled = Disabled;
        SongVoiceOver.instance.langzamerButton.Disabled = Disabled;
        Manager.instance.SetLayerSwitchButtonsEnabled(!Disabled);
        Manager.instance.PlayPauseButton.Disabled = Disabled;
        SongVoiceOver.instance.recordSongButton.Disabled = Disabled;
        Manager.instance.layerVoiceOver0.recordLayerButton.Disabled = Disabled;
        Manager.instance.layerVoiceOver1.recordLayerButton.Disabled = Disabled;
        Manager.instance.layerLoopToggle.Disabled = Disabled;
        recordSongButton.Disabled = Disabled;
    }
}