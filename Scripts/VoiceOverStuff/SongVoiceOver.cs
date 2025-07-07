using Godot;
using System;

public partial class SongVoiceOver : Node
{
	// singleton
    public static SongVoiceOver instance = null;

	// user interface
	[Export] public ProgressBar progressbar;
	[Export] public Button recordSongButton;

	// recording
	public AudioStream voiceOver = null;
    AudioEffectRecord audioEffectRecord;
	public AudioStreamPlayer2D audioPlayer;
	bool shouldRecord = false;
	public bool recording = false;
	float recordingTimer = 0;

	public float recordingLength = 0;

	public bool finished = false;


	// other
	[Export] Button snellerButton;
	[Export] Button langzamerButton;

	public override void _Ready()
    {
		// init singleton
        instance ??= this;

		// init record button
		recordSongButton.Pressed += () =>
		{
			Manager.instance.layerLoopToggle.ButtonPressed = true;
			shouldRecord = !shouldRecord;

			// metronoom aan
			Manager.instance.metronome_toggle.ButtonPressed = true;

			// 4 beats voor de eerste noot op eerste laag
			Manager.instance.SwitchLayer(10);
			BpmManager.instance.currentBeat = BpmManager.beatsAmount / 2;

			// playing true
			BpmManager.instance.playing = true;
		};

		// create audioplayer
		audioPlayer = new AudioStreamPlayer2D();
		AddChild(audioPlayer);

		// setup record effect
        audioEffectRecord = (AudioEffectRecord)AudioServer.GetBusEffect(AudioServer.GetBusIndex("Microphone"), 1);
    }

    public override void _Process(double delta)
	{
		// set color of fake button
		((RecordButton)recordSongButton.GetParent()).pressed = shouldRecord;

		// update recording timer
		if (recording) recordingTimer += (float)delta;
		else
		{
			recordingTimer = 0;
		}

		// set progress bar value
		if (recording) progressbar.Value = recordingTimer / (10f * (BpmManager.beatsAmount * BpmManager.instance.baseTimePerBeat));

		//if (audioPlayer.Playing) GD.Print(SongVoiceOver.instance.audioPlayer.GetPlaybackPosition());
	}

	public void OnBeginning()
	{
		if (recording)
		{
			StopRecording();
			if (voiceOver != null) audioPlayer.Play();
		}
		else
		{
			if (shouldRecord)
			{
				StartRecording();
			}
			else if (voiceOver != null) audioPlayer.Play();
		}
	}

    private void StartRecording()
    {
		recording = true;
        audioEffectRecord.SetRecordingActive(true);
		GD.Print("recording started");

		// buttons during recording
		snellerButton.Disabled = true;
		langzamerButton.Disabled= true;
		Manager.instance.SetLayerSwitchButtonsEnabled(false);
		Manager.instance.PlayPauseButton.Disabled = true;
		Manager.instance.ResetPlayerButton.Disabled = true;
		recordSongButton.Disabled = true;

		Manager.instance.layerVoiceOver0.recordLayerButton.Disabled = true;
		Manager.instance.layerVoiceOver1.recordLayerButton.Disabled = true;

		SetVolume(0.5f);

		Manager.instance.metronome_toggle.ButtonPressed = false;
    }

    private void StopRecording()
    {
        audioEffectRecord.SetRecordingActive(false);
		GD.Print("recording stopped");
		recordingLength = recordingTimer;
		recording = false;
		shouldRecord = false;
		voiceOver = audioEffectRecord.GetRecording();
		audioPlayer.Stream = voiceOver;


		// buttons during recording
		snellerButton.Disabled = false;
		langzamerButton.Disabled= false;
		Manager.instance.SetLayerSwitchButtonsEnabled(true);
		Manager.instance.PlayPauseButton.Disabled = false;
		Manager.instance.ResetPlayerButton.Disabled = false;
		recordSongButton.Disabled = false;

		Manager.instance.layerVoiceOver0.recordLayerButton.Disabled = false;
		Manager.instance.layerVoiceOver1.recordLayerButton.Disabled = false;

		SetVolume(1f);

		finished = true;
    }

	void SetVolume(float value)
    {
        float db = Mathf.LinearToDb(value);
        Manager.instance.firstAudioPlayer.VolumeDb = db;
        Manager.instance.secondAudioPlayer.VolumeDb = db;
        Manager.instance.thirdAudioPlayer.VolumeDb = db;
        Manager.instance.fourthAudioPlayer.VolumeDb = db;
    }
}
