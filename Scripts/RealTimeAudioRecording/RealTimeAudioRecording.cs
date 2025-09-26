using Godot;

using System;
using System.IO;
using System.Threading.Tasks;
using System.Collections.Generic;

using NAudio.Wave;
using NAudio.Wave.SampleProviders;

public static class RealTimeAudioRecording
{
    public static AudioStreamWav recording_result = null;
    public static AudioEffectRecord audioEffectRecord;

    public static bool shouldRecord = false;
    public static bool recording = false;
    public static float recordingTimer = 0;

    public static void Initialize()
    {
        var masterAudioBus = AudioServer.GetBusIndex("SubMaster");
        audioEffectRecord = (AudioEffectRecord)AudioServer.GetBusEffect(masterAudioBus, 0);
    }

    public static void Update(float delta)
    {
        if (recording) recordingTimer += (float)delta;
        else recordingTimer = 0;

        if (Input.IsActionJustPressed("f1"))
        {
            if (!recording) StartRecordingMaster();
            else StopRecordingMaster();
        }
    }

    public static void StartRecordingMaster()
    {
        GD.Print("Starting Recording");
        recording = true;
        shouldRecord = false;
        audioEffectRecord.SetRecordingActive(true);

        // disable buttons during recording
        DisableButtons(true);

        Manager.instance.metronome_toggle.ButtonPressed = false;
    }

    public static void OnTop()
    {
        if (recording) StopRecordingMaster();
        else if (shouldRecord) StartRecordingMaster();
    }

    public static void OnButton()
    {
        Manager.instance.layerLoopToggle.ButtonPressed = true;
        Manager.instance.metronome_toggle.ButtonPressed = true;
        Manager.instance.SwitchLayer(10);
        BpmManager.instance.currentBeat = BpmManager.beatsAmount / 2;
        BpmManager.instance.playing = true;
        shouldRecord = true;
    }

    public static void StopRecordingMaster()
    {
        GD.Print("Stopping Recording");
        recording = false;
        shouldRecord = false;
        audioEffectRecord.SetRecordingActive(false);
        recording_result = audioEffectRecord.GetRecording();

        // re-enable buttons during recording
        DisableButtons(false);
    }

    private static void DisableButtons(bool Disabled)
    {
        SongVoiceOver.instance.snellerButton.Disabled = Disabled;
        SongVoiceOver.instance.langzamerButton.Disabled = Disabled;
        Manager.instance.SetLayerSwitchButtonsEnabled(!Disabled);
        Manager.instance.PlayPauseButton.Disabled = Disabled;
        SongVoiceOver.instance.recordSongButton.Disabled = Disabled;
        Manager.instance.layerVoiceOver0.recordLayerButton.Disabled = Disabled;
        Manager.instance.layerVoiceOver1.recordLayerButton.Disabled = Disabled;
        Manager.instance.layerLoopToggle.Disabled = Disabled;
    }
}