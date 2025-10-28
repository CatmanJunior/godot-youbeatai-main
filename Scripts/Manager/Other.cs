using System;
using Godot;

public partial class Manager : Node
{
    public bool loadedtemplate = false;
    public bool hassavedtofile = false;
    bool metronome_sfx_enabled = false;
    bool up_pressed = false;
	bool up_pressed_lastframe = false;
    bool dn_pressed = false;
	bool dn_pressed_lastframe = false;
    bool lf_pressed = false;
	bool lf_pressed_lastframe = false;
    bool rt_pressed = false;
	bool rt_pressed_lastframe = false;
    public bool f7_pressed = false;
	public bool f7_pressed_lastframe = false;
    public bool f11_pressed = false;
	public bool f11_pressed_lastframe = false;
    float time = 0;
    float slowBeatTimer = 0;
    public bool first_tts_done = false;
    private bool ctrlc_pressed = false;
    private bool ctrl_v_pressed = false;
    bool[,] beatClipboard = new bool[4, BpmManager.beatsAmount];
    public bool showTemplate = false;
    public bool selectedTemplate = false;
    bool haschangedbpm = false;
    bool hasclearedlayout = false;
    private bool spacedownlastframe = false;
    private bool enterdownlastframe = false;
    float timeafterplay = 0;
    public bool savedToLaout = false;
    private float startswing;
    bool anyLayerButtonHasBeenPressed = false;
    [Export] public Area2D PianoArea;
    [Export] public Label PianoMesh;
    [Export] public Area2D InBetweenArea;
    [Export] public Label InBetweenMesh;
    [Export] public Area2D OutSideArea;
    [Export] public Label OutSideMesh;
    [Export] public Node3D Klappy;

    AudioStream clipboardLayerVoice0;
    AudioStream clipboardLayerVoice1;

    public void CopyLayer()
    {
        CopyBeatLayoutToClipboard();
        CopyLayerVoiceToClipBoard();
        SamplesMixing_CopyKnobsForLayer();
        SynthMixing_CopyKnobsForLayer();
        EmitSignal(SignalName.OnCopyLayerEvent, currentLayerIndex);
    }

    public void PasteLayer()
    {
        PasteBeatLayoutFromClipboard();
        PasteLayerVoiceFromClipBoard();
        SamplesMixing_PasteKnobsForLayer();
        SynthMixing_PasteKnobsForLayer();
        EmitSignal(SignalName.OnPasteLayerEvent, currentLayerIndex);
    }

    public void ClearLayer()
    {
        RemoveLayer(currentLayerIndex);
        ClearLayerVoiceOver();
        EmitSignal(SignalName.OnClearLayerEvent);
        hasclearedlayout = true;
    }

    public void CopyLayerVoiceToClipBoard()
    {
        clipboardLayerVoice0 = layerVoiceOver0.GetCurrentLayerVoiceOver();
        clipboardLayerVoice1 = layerVoiceOver1.GetCurrentLayerVoiceOver();
    }

    public void PasteLayerVoiceFromClipBoard()
    {
        layerVoiceOver0.SetCurrentLayerVoiceOver(clipboardLayerVoice0);
        layerVoiceOver1.SetCurrentLayerVoiceOver(clipboardLayerVoice1);
    }

    public void ClearLayerVoiceOver()
    {
        layerVoiceOver0.SetCurrentLayerVoiceOver(null);
        layerVoiceOver1.SetCurrentLayerVoiceOver(null);
    }

    public void CopyBeatLayoutToClipboard()
    {
        beatClipboard = (bool[,])beatActives.Clone();
        savedToLaout = true;
    }

    public void PasteBeatLayoutFromClipboard()
    {
        beatActives = (bool[,])beatClipboard.Clone();
        loadedtemplate = true;
    }

    public void ClearLayout()
    {
        beatActives = new bool[4, BpmManager.beatsAmount];
        hasclearedlayout = true;
    }

    public void OnPlayPauseButton()
    {
        BpmManager.instance.playing = !BpmManager.instance.playing;

        layerVoiceOver0.audioPlayer.StreamPaused = !BpmManager.instance.playing;
        layerVoiceOver1.audioPlayer.StreamPaused = !BpmManager.instance.playing;

        SongVoiceOver.instance.audioPlayer.StreamPaused = !BpmManager.instance.playing;

        UpdateSongVoiceOverPlayBackPosition();
    }

    public void OnBpmUpButton()
    {
        if (BpmManager.instance.bpm < 300) BpmManager.instance.bpm += 5;
        haschangedbpm = true;
    }
    
    public void OnBpmDownButton()
    {
        if (BpmManager.instance.bpm > 40) BpmManager.instance.bpm -= 5;
        haschangedbpm = true;
    }

    public void ShowSavingLabel(string name)
    {
        savingLabelActive = true;
        savingLabelTimer = 0;
        SavingLabel.Text = "Opgeslagen naar:" + "\n" + name;
    }

    public void PlayExtraSFX(AudioStream audioStream)
    {
        sfxAudioPlayer.Stop();
        sfxAudioPlayer.Stream = audioStream;
        sfxAudioPlayer.Play();
    }

    private void HandleCopyPasting()
    {
        if (Input.IsKeyPressed(Key.Ctrl) && Input.IsKeyPressed(Key.C))
        {
            if (!ctrlc_pressed)
            {
                ctrlc_pressed = true;
                CopyLayer();
            }
        }
        else ctrlc_pressed = false;

        if (Input.IsKeyPressed(Key.Ctrl) && Input.IsKeyPressed(Key.V))
        {
            if (!ctrl_v_pressed)
            {
                ctrl_v_pressed = true;
                PasteLayer();
            }
        }
        else ctrl_v_pressed = false;
    }

    AudioEffectInstance GetBusEffectInstanceByName(int busIndex, string effectName)
	{
		int effectCount = AudioServer.GetBusEffectCount(busIndex);
		for (int i = 0; i < effectCount; i++) if (AudioServer.GetBusEffect(busIndex, i).ResourceName == effectName) return AudioServer.GetBusEffectInstance(busIndex, i);
		GD.PushWarning($"Effect '{effectName}' not found.");
		return null;
	}

    AudioEffect GetBusEffectByName(int busIndex, string effectName)
	{
		int effectCount = AudioServer.GetBusEffectCount(busIndex);
		for (int i = 0; i < effectCount; i++) if (AudioServer.GetBusEffect(busIndex, i).ResourceName == effectName) return AudioServer.GetBusEffect(busIndex, i);
		GD.PushWarning($"Effect '{effectName}' not found.");
		return null;
	}

	float GetVolumeFromBus(string busName)
	{
		var busindex = AudioServer.GetBusIndex(busName);
		var analyzer = (AudioEffectSpectrumAnalyzerInstance)GetBusEffectInstanceByName(busindex, "SpectrumAnalyzer");
		var magnitude = analyzer.GetMagnitudeForFrequencyRange(20, 20000);
		var volume = magnitude.Length();
		return volume * 30f;
	}

	void UpdateGreenPurpleButtonLights()
    {
        var greenLight = activateGreenChaosButton.GetChild<Light2D>(1);
		var purpleLight = activatePurpleChaosButton.GetChild<Light2D>(1);
		var green_volume_voice = GetVolumeFromBus("GreenVoice");
		var purple_volume_voice = GetVolumeFromBus("PurpleVoice");

		if (green_volume_voice > 0.1f && BpmManager.instance.playing && layerVoiceOver0.GetCurrentLayerVoiceOver() != null) greenLight.Energy = green_volume_voice;
		else greenLight.Energy = 0f;

		if (purple_volume_voice > 0.1f && BpmManager.instance.playing && layerVoiceOver1.GetCurrentLayerVoiceOver() != null) purpleLight.Energy = purple_volume_voice;
		else purpleLight.Energy = 0f;
    }

    public async void ExecuteNextFrame(Action action)
    {
        await ToSignal(GetTree(), "process_frame");
        action.Invoke();
    }
}