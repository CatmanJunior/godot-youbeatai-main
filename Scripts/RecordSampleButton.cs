using Godot;
using System;

public partial class RecordSampleButton : Sprite2D
{
    [Export] int ring = 0;

    private bool inside => IsPixelOpaque(GetLocalMousePosition());
    private bool pressing = false;

    public AudioStream recordedAudio = null;

    private AudioEffectRecord audioEffectRecord;

    private bool recording = false;
    private float silenceLength = 0;
    private float recordingLength = 0;
    private bool hasDetectedSound = false;

    private float recordingVolume => MicrophoneCapture.instance.volume;
    private float recordingTreshold = 0.01f;

    public override void _Ready()
    {
        var busIndex = AudioServer.GetBusIndex("Microphone");
        audioEffectRecord = (AudioEffectRecord)AudioServer.GetBusEffect(busIndex, 1);
		if (audioEffectRecord == null) GD.Print("no record effect found");
    }

    public override void _Process(double delta)
    {
        if (recording)
        {
            recordingLength += (float)delta;
            if (recordingVolume > recordingTreshold) hasDetectedSound = true;
            if (!hasDetectedSound) silenceLength += (float)delta;
        }

        if (ring == 0 && recording)
        {
            GD.Print("---------------------");
            GD.Print("recording: " + recording);
            GD.Print("volume: " + recordingVolume);
            GD.Print("length: " + recordingLength);
            GD.Print("silence: " + silenceLength);
            GD.Print("detected: " + hasDetectedSound);
            GD.Print("treshold: " + recordingTreshold);
            GD.Print("---------------------");
        }
    }

    public override void _Input(InputEvent inputEvent)
    {
        if (inputEvent is InputEventMouseButton mouseEvent && mouseEvent.ButtonIndex == MouseButton.Left)
        {
            // On Mouse Down
            if (mouseEvent.IsPressed() && inside)
            {
                pressing = !pressing;
                if (pressing) StartRecording();
                else StopRecording();
            }
        }
    }

    private AudioStreamWav TrimAudioStream(AudioStreamWav original, float secondsToTrim)
    {
        byte[] originalData = original.Data;
        float audioLength = (float)original.GetLength(); // actual length in seconds

        if (audioLength <= 0)
        {
            GD.Print("Invalid audio length.");
            return original;
        }

        float bytesPerSecond = originalData.Length / audioLength;
        int frameSize = (original.Stereo ? 2 : 1) * (original.Format == AudioStreamWav.FormatEnum.Format16Bits ? 2 : 1);
        int rawTrimBytes = Mathf.FloorToInt(secondsToTrim * bytesPerSecond);
        int alignedTrimBytes = (rawTrimBytes / frameSize) * frameSize;

        GD.Print($"Trim {secondsToTrim} seconds → {alignedTrimBytes} bytes");

        if (alignedTrimBytes >= originalData.Length)
        {
            GD.Print("Trim amount exceeds or matches original audio length.");
            return original;
        }

        byte[] trimmedData = new byte[originalData.Length - alignedTrimBytes];
        Array.Copy(originalData, alignedTrimBytes, trimmedData, 0, trimmedData.Length);

        return new AudioStreamWav
        {
            Data = trimmedData,
            Format = original.Format,
            Stereo = original.Stereo,
            MixRate = original.MixRate,
            LoopMode = original.LoopMode
        };
    }

    void SetVolume(float value)
    {
        float db = Mathf.LinearToDb(value);
        Manager.instance.firstAudioPlayer.VolumeDb = db;
        Manager.instance.secondAudioPlayer.VolumeDb = db;
        Manager.instance.thirdAudioPlayer.VolumeDb = db;
        Manager.instance.fourthAudioPlayer.VolumeDb = db;
    }

    private void StartRecording()
    {
        SetVolume(0f);
		Modulate = new Color(1, 0, 0, 1);
        audioEffectRecord.SetRecordingActive(true);
        recording = true;
    }

    private void StopRecording()
    {
        SetVolume(1);
		Modulate = new Color(1, 1, 1, 1);
        audioEffectRecord.SetRecordingActive(false);
		recordedAudio = audioEffectRecord.GetRecording();
        recordedAudio = TrimAudioStream((AudioStreamWav)recordedAudio, silenceLength);
        recording = false;
        hasDetectedSound = false;
        silenceLength = 0;
        recordingLength = 0;

        if (ring == 0)
        {
            var manager = Manager.instance;
            manager.firstAudioPlayer.Stop();
            var istoggleon = manager.recordSampleCheckButton0.ButtonPressed;
            manager.audioFilesToUse[ring] = istoggleon ? manager.recordSampleButton0.recordedAudio : manager.mainAudioFiles[ring];
            manager.firstAudioPlayer.Stream = manager.audioFilesToUse[ring];
        }
        if (ring == 1)
        {
            var manager = Manager.instance;
            manager.secondAudioPlayer.Stop();
            var istoggleon = manager.recordSampleCheckButton1.ButtonPressed;
            manager.audioFilesToUse[ring] = istoggleon ? manager.recordSampleButton1.recordedAudio : manager.mainAudioFiles[ring];
            manager.secondAudioPlayer.Stream = manager.audioFilesToUse[ring];
        }
        if (ring == 2)
        {
            var manager = Manager.instance;
            manager.thirdAudioPlayer.Stop();
            var istoggleon = manager.recordSampleCheckButton2.ButtonPressed;
            manager.audioFilesToUse[ring] = istoggleon ? manager.recordSampleButton2.recordedAudio : manager.mainAudioFiles[ring];
            manager.thirdAudioPlayer.Stream = manager.audioFilesToUse[ring];
        }
        if (ring == 3)
        {
            var manager = Manager.instance;
            manager.fourthAudioPlayer.Stop();
            var istoggleon = manager.recordSampleCheckButton3.ButtonPressed;
            manager.audioFilesToUse[ring] = istoggleon ? manager.recordSampleButton3.recordedAudio : manager.mainAudioFiles[ring];
            manager.fourthAudioPlayer.Stream = manager.audioFilesToUse[ring];
        }
    }
}