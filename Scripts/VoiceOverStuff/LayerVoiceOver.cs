using Godot;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

public partial class LayerVoiceOver : Node
{
    // events for stopping and starting recording
    [Signal] public delegate void OnStartedRecordingEventHandler();
    [Signal] public delegate void OnStoppedRecordingEventHandler();

    // the actual storage of all layer recordings (ground truth)
    public List<AudioStream> layersVoiceOvers = [];

    // reference to the current layer index
    public int currentLayerIndex => Manager.instance.currentLayerIndex;
    
    // current layer recording and playback
    AudioEffectRecord audioEffectRecord;
    public AudioStreamPlayer2D audioPlayer;
    public bool shouldRecord = false;
    public bool recording = false;
    public bool shouldUpdateProgressBar = false;
    public bool finished = false;
    public float recordingTimer = 0;

    // user interface
    [Export] public TextureProgressBar textureProgressBar;
    [Export] public Button recordLayerButton;
    [Export] Button snellerButton;
    [Export] Button langzamerButton;

    // lines
    [Export] public Line2D smallLine;
    [Export] public Line2D bigLine;
    [Export] public int bigLineBaseDist = 280;
    [Export] public int bigLineVolumeDist = 28;
    [Export] public bool bigLineReversed = false;

    public void SetCurrentLayerVoiceOver(AudioStream voiceOver) // important
    {
        layersVoiceOvers[currentLayerIndex] = voiceOver;

        audioPlayer.Stream = GetCurrentLayerVoiceOver();
        audioPlayer.Stop();
        audioPlayer.Play();
        shouldUpdateLines = true;
    }

    public AudioStream GetCurrentLayerVoiceOver() => layersVoiceOvers[currentLayerIndex]; // important

    public override void _Ready()
    {
        // init record button
        recordLayerButton.Pressed += () =>
        {
            if (!recording && !shouldRecord)
            {
                Manager.instance.layerLoopToggle.ButtonPressed = false;
                shouldRecord = !shouldRecord;

                // buttons during recording
                snellerButton.Disabled = true;
                langzamerButton.Disabled = true;
                Manager.instance.SetLayerSwitchButtonsEnabled(false);
                Manager.instance.PlayPauseButton.Disabled = true;
                SongVoiceOver.instance.recordSongButton.Disabled = true;

                // metronoom aan
                Manager.instance.metronome_toggle.ButtonPressed = true;

                // begin on top with the build up
                BpmManager.instance.currentBeat = 0;

                // playing true
                BpmManager.instance.playing = true;

                // also play metronome sound on first beat
                Manager.instance.PlayExtraSFX(Manager.instance.metronome_sfx);

                Manager.instance.ShowCountDown();
            }
            else if (!recording && shouldRecord) // cancel should record
            {
                // cancel should record
                shouldRecord = !shouldRecord;

                // enable buttons
                snellerButton.Disabled = false;
                langzamerButton.Disabled = false;
                Manager.instance.SetLayerSwitchButtonsEnabled(true);
                Manager.instance.PlayPauseButton.Disabled = false;
                SongVoiceOver.instance.recordSongButton.Disabled = false;

                // stop tic sounds
                Manager.instance.metronome_toggle.ButtonPressed = false;
                
                // close countdown
                Manager.instance.CloseCountDown();
            }
        };

        // create audioplayer
        audioPlayer = new AudioStreamPlayer2D();
        AddChild(audioPlayer);

        if (this == Manager.instance.layerVoiceOver0) audioPlayer.Bus = "GreenVoice";
        else if (this == Manager.instance.layerVoiceOver1) audioPlayer.Bus = "PurpleVoice";

        // setup record effect
        audioEffectRecord = (AudioEffectRecord)AudioServer.GetBusEffect(AudioServer.GetBusIndex("Microphone"), 1);

        // pause voiceover button
        Manager.instance.PlayPauseButton.Pressed += () =>
        {
            if (layersVoiceOvers[currentLayerIndex] != null)
            {
                if (audioPlayer.Playing) audioPlayer.Stop();
                else audioPlayer.Play();
            }
        };

        // line
        SetSmallVolumeline();
        SetBigVolumeline();
    }

    bool shouldMeasureAudioDelay = false;
    ulong audioDelayBeginMs;
    ulong audioDelayEndMs;
    float audioDelayTotalSeconds;

    public override void _Process(double delta)
    {
        if (shouldMeasureAudioDelay && audioPlayer.GetPlaybackPosition() > 0)
        {
            audioDelayEndMs = Time.GetTicksMsec();
            audioDelayTotalSeconds = ((float)audioDelayEndMs - (float)audioDelayBeginMs) / 1000f;
            GD.Print("⚠️ audio delay is: " + audioDelayTotalSeconds.ToString("0.000") + " seconds");
            shouldMeasureAudioDelay = false;
        }

        // set color of fake button
        ((RecordButton)recordLayerButton.GetParent()).pressed = shouldRecord;

        // update recording timer
        if (recording) recordingTimer += (float)delta;
        else recordingTimer = 0;

        // set progress bar value
        int currentBeat = BpmManager.instance.currentBeat;
        float beatTimer = BpmManager.instance.beatTimer;
        float progress = ((float)((float)(currentBeat + (beatTimer / BpmManager.instance.timePerBeat))) / BpmManager.beatsAmount);

        if (shouldUpdateProgressBar)
        {
            textureProgressBar.Value = progress;
        }
        else
        {
            textureProgressBar.Value = 0;
        }

        if (shouldUpdateLines)
        {
            SetSmallVolumeline();
            SetBigVolumeline();
            shouldUpdateLines = false;
        }
    }

    bool shouldUpdateLines = false;

    public void OnTop()
    {
        if (shouldRecord && !recording) StartRecording();
        else if (recording) StopRecording();

        if (!recording)
        {
            audioPlayer.Stream = GetCurrentLayerVoiceOver();
            shouldMeasureAudioDelay = true;
            audioDelayBeginMs = Time.GetTicksMsec();
        }

        GetTree().CreateTimer(0.4).Timeout += OnTopDelayed;
    }

    private void OnTopDelayed()
    {
        if (audioPlayer.Playing) audioPlayer.Stop();
        if (!recording) audioPlayer.Play();
    }

    private void StartRecording()
    {
        shouldUpdateProgressBar = true;
        bigLine.Visible = false;

        GetTree().CreateTimer(0.4).Timeout += () =>
        {
            recording = true;
            audioEffectRecord.SetRecordingActive(true);
            GD.Print("recording started");
            EmitSignal(SignalName.OnStartedRecording);
        };

        // stop tic sounds
        Manager.instance.metronome_toggle.ButtonPressed = false;

        AudioServer.SetBusVolumeLinear(AudioServer.GetBusIndex("SubMaster"), 0.1f);

        Manager.instance.CloseCountDown();
    }

    private void StopRecording()
    {
        shouldUpdateProgressBar = false;
        bigLine.Visible = true;

        GetTree().CreateTimer(0.4).Timeout += () =>
        {
            audioEffectRecord.SetRecordingActive(false);
            SetCurrentLayerVoiceOver(audioEffectRecord.GetRecording());
            GD.Print("recording stopped");
            recording = false;
            shouldRecord = false;
            finished = true;
            shouldUpdateLines = true;

            EmitSignal(SignalName.OnStoppedRecording);
        };

        // buttons after recording
        snellerButton.Disabled = false;
        langzamerButton.Disabled = false;
        Manager.instance.SetLayerSwitchButtonsEnabled(true);
        Manager.instance.PlayPauseButton.Disabled = false;
        SongVoiceOver.instance.recordSongButton.Disabled = false;

        // stop tic sounds
        Manager.instance.metronome_toggle.ButtonPressed = false;

        AudioServer.SetBusVolumeLinear(AudioServer.GetBusIndex("SubMaster"), 1f);
    }

    public async void SetVolumeLine(Line2D line, AudioStream audio, int points, int baseDist, int volumeDist, bool reversed = false)
    {
        var lambda = () =>
        {
            var offsets = new Vector2[points];

            for (int i = 0; i < points; i++)
            {
                float volumeoffset = 0;
                if (layersVoiceOvers[currentLayerIndex] != null)
                {
                    float length = (float)layersVoiceOvers[currentLayerIndex].GetLength();
                    float percentage = (float)i / points;
                    float volume = GetVolumeAtTime((AudioStreamWav)audio, percentage * length);
                    volumeoffset = volume * volumeDist;
                }

                float angle = -Mathf.Pi / 2 + Mathf.Tau * i / points;
                float finaldist = reversed ? baseDist - volumeoffset : baseDist + volumeoffset;

                offsets[i] = new Vector2(Mathf.Cos(angle), Mathf.Sin(angle)) * finaldist;
            }

            return offsets;
        };

        // async de zwaare volume offset calculaties doen
        var offsets = await Task.Run(lambda);

        // nu op de main thread de godot functies roepen
        line.ClearPoints();
        foreach (var offset in offsets) line.AddPoint(offset);
    }

    public void SetSmallVolumeline()
    {
        SetVolumeLine(smallLine, layersVoiceOvers[currentLayerIndex], 40, 15, 15);
    }

    public void SetBigVolumeline()
    {
        SetVolumeLine(bigLine, layersVoiceOvers[currentLayerIndex], 100, bigLineBaseDist, bigLineVolumeDist, bigLineReversed);
    }

    public float GetVolumeAtTime(AudioStreamWav audio, float time)
    {
        if (audio == null || audio.Data.Length == 0)
        {
            GD.PrintErr("Invalid sample.");
            return 0f;
        }

        int sampleRate = audio.MixRate;
        int channels = audio.Stereo ? 2 : 1;
        int formatSize = audio.Format == AudioStreamWav.FormatEnum.Format16Bits ? 2 : 1;

        int sampleIndex = (int)(time * sampleRate) * channels;
        int byteIndex = sampleIndex * formatSize;

        if (byteIndex >= audio.Data.Length - formatSize)
        {
            GD.PrintErr("Time exceeds sample length.");
            return 0f;
        }

        // Read sample depending on format
        if (audio.Format == AudioStreamWav.FormatEnum.Format16Bits)
        {
            short value = BitConverter.ToInt16(audio.Data, byteIndex);
            return Mathf.Abs(value / 32768f);
        }
        else // 8-bit
        {
            sbyte value = (sbyte)audio.Data[byteIndex];
            return Mathf.Abs(value / 128f);
        }
    }
}