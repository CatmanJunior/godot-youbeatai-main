using Godot;
using NAudio.Mixer;
using System;
using System.Threading.Tasks;

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
    private float actualSoundLength = 0;

    private float recordingVolume => MicrophoneCapture.instance.volume;
    private float recordingTreshold = 0.01f;

    private Node2D mixerToMove;
    private Node2D pivotToMove => (Node2D)mixerToMove.FindChild("Pivot");


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

            if (hasDetectedSound)
            {
                actualSoundLength += (float)delta;

                var baseTimePerBeat = 60f / BpmManager.instance.bpm / 2;
                var percentage = actualSoundLength / (baseTimePerBeat * 2);

                if (percentage > 1f)
                {
                    pressing = !pressing;
                    StopRecording();
                }
                else
                {
                    var icon = GetChild(0) as Label;
                    icon.RotationDegrees = percentage * 360f;
                }
            }
        }

        /*
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
        */
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
        
        recording = false;
        recordedAudio = TrimAudioStream((AudioStreamWav)recordedAudio, silenceLength);
        hasDetectedSound = false;
        silenceLength = 0;
        recordingLength = 0;
        actualSoundLength = 0;

        var manager = Manager.instance;

        if (ring == 0)
        {
            manager.firstAudioPlayerRec.Stop();
            manager.firstAudioPlayerRec.Stream = manager.recordSampleButton0.recordedAudio;
            mixerToMove = manager.sampleMixer0;
            
        }
        if (ring == 1)
        {
            manager.secondAudioPlayerRec.Stop();
            manager.secondAudioPlayerRec.Stream = manager.recordSampleButton1.recordedAudio;
            mixerToMove = manager.sampleMixer1;

        }
        if (ring == 2)
        {
            manager.thirdAudioPlayerRec.Stop();
            manager.thirdAudioPlayerRec.Stream = manager.recordSampleButton2.recordedAudio;
            mixerToMove = manager.sampleMixer2;

        }
        if (ring == 3)
        {
            manager.fourthAudioPlayerRec.Stop();
            manager.fourthAudioPlayerRec.Stream = manager.recordSampleButton3.recordedAudio;
            mixerToMove = manager.sampleMixer3;
        }

        if (pivotToMove.RotationDegrees > -360 / 3) _ = RotateMixerLeft();  // fire-and-forget coroutine
        else if (pivotToMove.RotationDegrees < -360 / 3) _ = RotateMixerRight();  // fire-and-forget coroutine
    }

    async Task RotateMixerRight()
    {
        var increase = mixerToMove.FindChild("IncreaseButton") as Button;
        var pressedStyle = increase.GetThemeStylebox("pressed") as StyleBoxFlat;
        var normalStyle = increase.GetThemeStylebox("normal") as StyleBoxFlat;
        var originalStyle = (StyleBoxFlat)normalStyle.Duplicate();
        var tempStyle = (StyleBoxFlat)pressedStyle.Duplicate();

        increase.AddThemeStyleboxOverride("normal", tempStyle);
        while (pivotToMove.RotationDegrees < -360 / 3)
        {
            Manager.instance.RotatePivot(5, pivotToMove, ring);
            await Task.Delay(50);
        }
        increase.AddThemeStyleboxOverride("normal", originalStyle);
    }

    async Task RotateMixerLeft()
    {
        var decrease = mixerToMove.FindChild("DecreaseButton") as Button;
        var pressedStyle = decrease.GetThemeStylebox("pressed") as StyleBoxFlat;
        var normalStyle = decrease.GetThemeStylebox("normal") as StyleBoxFlat;
        var originalStyle = (StyleBoxFlat)normalStyle.Duplicate();
        var tempStyle = (StyleBoxFlat)pressedStyle.Duplicate();

        decrease.AddThemeStyleboxOverride("normal", tempStyle);
        while (pivotToMove.RotationDegrees > -360 / 3)
        {
            Manager.instance.RotatePivot(-5, pivotToMove, ring);
            await Task.Delay(50);
        }
        decrease.AddThemeStyleboxOverride("normal", originalStyle);
    }
}