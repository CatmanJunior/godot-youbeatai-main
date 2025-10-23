using Godot;

public partial class SongVoiceOver : Node
{
	// singleton
    public static SongVoiceOver instance = null;

	public override void _ExitTree()
    {
        if (instance == this) instance = null;
    }

	// user interface
	[Export] public ProgressBar progressbar;
	[Export] public Button recordSongButton;
	[Export] public Sprite2D recordSongSprite;

	// recording
	public AudioStreamWav voiceOver = null;
    AudioEffectRecord audioEffectRecord;
	public AudioStreamPlayer2D audioPlayer;
	public bool shouldRecord = false;
	public bool recording = false;
	float recordingTimer = 0;

	public float recordingLength = 0;

	public bool finished = false;


	// other
	[Export] public Button snellerButton;
	[Export] public Button langzamerButton;

	public override void _Ready()
    {
		// init singleton
        instance ??= this;

		// init record button
		recordSongButton.Pressed += OnButton;

		// create audioplayer
		audioPlayer = new AudioStreamPlayer2D();
		AddChild(audioPlayer);
		audioPlayer.Bus = "SongVoice";

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
		if (recording) progressbar.Value = recordingTimer / (Manager.instance.layersAmount * (BpmManager.beatsAmount * BpmManager.instance.baseTimePerBeat));

		//if (audioPlayer.Playing) GD.Print(SongVoiceOver.instance.audioPlayer.GetPlaybackPosition());

		audioPlayer.VolumeLinear = 6f;
	}

    public void OnButton()
    {
        Manager.instance.layerLoopToggle.ButtonPressed = true;
        shouldRecord = !shouldRecord;

		// buttons during recording
		snellerButton.Disabled = true;
		langzamerButton.Disabled= true;
		Manager.instance.SetLayerSwitchButtonsEnabled(false);
		Manager.instance.PlayPauseButton.Disabled = true;
		recordSongButton.Disabled = true;

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

	public void OnTop()
	{
		if (recording)
		{
			StopRecording();
			if (voiceOver != null) audioPlayer.Play();
		}
		else
		{
			if (shouldRecord) StartRecording();
			else if (voiceOver != null) audioPlayer.Play();
		}
	}

    private void StartRecording()
    {
		recording = true;
        audioEffectRecord.SetRecordingActive(true);
		GD.Print("recording started");

		Manager.instance.layerVoiceOver0.recordLayerButton.Disabled = true;
		Manager.instance.layerVoiceOver1.recordLayerButton.Disabled = true;

		AudioServer.SetBusVolumeLinear(AudioServer.GetBusIndex("SubMaster"), 0.1f);

		Manager.instance.metronome_toggle.ButtonPressed = false;

		Manager.instance.CloseCountDown();
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
		recordSongButton.Disabled = false;

		Manager.instance.layerVoiceOver0.recordLayerButton.Disabled = false;
		Manager.instance.layerVoiceOver1.recordLayerButton.Disabled = false;

		AudioServer.SetBusVolumeLinear(AudioServer.GetBusIndex("SubMaster"), 1f);

		finished = true;
    }
}