using Godot;
using System;

public partial class LayerVoiceOver : Node
{
	[Signal] public delegate void OnStartedRecordingEventHandler();
	[Signal] public delegate void OnStoppedRecordingEventHandler();

	// user interface
	[Export] public TextureProgressBar textureProgressBar;
	[Export] public Button recordLayerButton;

	[Export] public Slider volumeSlider;

	// recording
	public AudioStream[] voiceOvers = new AudioStream[10];
	AudioEffectRecord audioEffectRecord;
	public AudioStreamPlayer2D audioPlayer;
	bool shouldRecord = false;
	bool recording = false;
	float recordingTimer = 0;

	public bool finished = false;

	// other
	[Export] Button snellerButton;
	[Export] Button langzamerButton;

	[Export] public Line2D smallLine;
	[Export] public Line2D bigLine;

	[Export] public int bigLineBaseDist = 280;
	[Export] public int bigLineVolumeDist = 28;
	[Export] public bool bigLineReversed = false;

	private double volume = 0.5;

	public int currentLayer => Manager.instance.currentLayerIndex;
	public void SetCurrentLayerVoiceOver(AudioStream voiceOver) => voiceOvers[currentLayer] = voiceOver;
	public AudioStream GetCurrentLayerVoiceOver() => voiceOvers[currentLayer];

	public override void _Ready()
    {
		if (volumeSlider != null)
		{	
			volumeSlider.ValueChanged += (double volume) =>
			{
				double new_volume = 1 - volume;
				volume = new_volume;
				audioPlayer.VolumeLinear = (float)new_volume * 1.5f;
			};

		}

		BpmManager.instance.OnPlayingChanged += (playing) =>
		{
			//OnTop();
		};

		// init record button
		recordLayerButton.Pressed += () => 
		{
			Manager.instance.layerLoopToggle.ButtonPressed = false;
			shouldRecord = !shouldRecord;

			// metronoom aan
			Manager.instance.metronome_toggle.ButtonPressed = true;

			// begin on top with the build up
			BpmManager.instance.currentBeat = 0;

			// playing true
			BpmManager.instance.playing = true;
		};

		// create audioplayer
		audioPlayer = new AudioStreamPlayer2D();
		AddChild(audioPlayer);
		if( volumeSlider != null )
			audioPlayer.VolumeLinear = 0.5f;

		// setup record effect
		audioEffectRecord = (AudioEffectRecord)AudioServer.GetBusEffect(AudioServer.GetBusIndex("Microphone"), 1);

		// pause voiceover button
		Manager.instance.PlayPauseButton.Pressed += () =>
		{
			if (voiceOvers[currentLayer] != null)
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
		if (recording)
		{
			textureProgressBar.Value = progress;
			bigLine.Visible = false;
		}
		else
		{
			textureProgressBar.Value = 0;
			if (GetCurrentLayerVoiceOver() != null) bigLine.Visible = true;
		}
	}

	bool shouldUpdateLines = false;

	public void OnTop() // tested: gets called on time
	{
		if (audioPlayer.Playing) audioPlayer.Stop();

		if (shouldRecord && !recording) StartRecording();
		else if (recording) StopRecording();

		if (!recording)
		{
			audioPlayer.Stream = GetCurrentLayerVoiceOver();  // tested: gets called on time
			audioPlayer.Play(); // tested: gets called on time

			shouldMeasureAudioDelay = true;
			audioDelayBeginMs = Time.GetTicksMsec();
		}

		if (shouldUpdateLines)
		{
			SetSmallVolumeline();
			SetBigVolumeline();
			shouldUpdateLines = false;
		}
	}

	private void StartRecording()
	{
		// buttons during recording
		snellerButton.Disabled = true;
		langzamerButton.Disabled = true;
		Manager.instance.SetLayerSwitchButtonsEnabled(false);
		Manager.instance.PlayPauseButton.Disabled = true;
		recordLayerButton.Disabled = true;
		SongVoiceOver.instance.recordSongButton.Disabled = true;

		SetVolume(0.1f);

		Manager.instance.metronome_toggle.ButtonPressed = false;
		

		GetTree().CreateTimer(0.3).Timeout += () =>
		{
			recording = true;
			audioEffectRecord.SetRecordingActive(true);
			GD.Print("recording started");
			EmitSignal(SignalName.OnStartedRecording);
		};
    }

    private void StopRecording()
    {
		GetTree().CreateTimer(0.3).Timeout += () =>
		{
			audioEffectRecord.SetRecordingActive(false);
			SetCurrentLayerVoiceOver(audioEffectRecord.GetRecording());
			SetVolume(volume);
			GD.Print("recording stopped");
			recording = false;
			shouldRecord = false;
			finished = true;
			shouldUpdateLines = true;

			EmitSignal(SignalName.OnStoppedRecording);
		};

		// buttons after recording
		snellerButton.Disabled = false;
		langzamerButton.Disabled= false;
		Manager.instance.SetLayerSwitchButtonsEnabled(true);
		Manager.instance.PlayPauseButton.Disabled = false;
		recordLayerButton.Disabled = false;
		SongVoiceOver.instance.recordSongButton.Disabled = false;
    }

	public void SetVolumeLine(Line2D line, AudioStream audio, int points, int baseDist, int volumeDist, bool reversed = false)
	{
		line.ClearPoints();
		for (int i = 0; i < points; i++)
		{
			float volumeoffset = 0;
			if (voiceOvers[currentLayer] != null)
			{
				float length = (float)voiceOvers[currentLayer].GetLength();
				float percentage = (float)i / (float)points;
				float volume = GetVolumeAtTime((AudioStreamWav)audio, percentage * length);
				volumeoffset = volume * volumeDist;
			}

			float angle = -Mathf.Pi / 2 + Mathf.Tau * i / (float)points;
			
			float finaldist = reversed ? baseDist - volumeoffset : baseDist + volumeoffset;
			Vector2 offset = new Vector2(Mathf.Cos(angle), Mathf.Sin(angle)) * finaldist;
			line.AddPoint(offset);
		}
	}

	public void SetSmallVolumeline()
	{
		SetVolumeLine(smallLine, voiceOvers[currentLayer], 40, 15, 15);
	}

	public void SetBigVolumeline()
	{
		SetVolumeLine(bigLine, voiceOvers[currentLayer], 100, bigLineBaseDist, bigLineVolumeDist, bigLineReversed);
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

	void SetVolume(double value)
    {
        float db = Mathf.LinearToDb((float)value);
        Manager.instance.firstAudioPlayer.VolumeDb = db;
        Manager.instance.secondAudioPlayer.VolumeDb = db;
        Manager.instance.thirdAudioPlayer.VolumeDb = db;
        Manager.instance.fourthAudioPlayer.VolumeDb = db;
    }
}