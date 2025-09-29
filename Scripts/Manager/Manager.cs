using Godot;

[GlobalClass]
public partial class Manager : Node
{
	public static Manager instance = null;

	public override void _Ready()
	{
		instance ??= this;
		BpmManager.instance.OnBeatEvent += OnBeat;
		ReadJsonFromPreviousSceneAndSetValues();
		InitAllAudioPlayers();
		InitButtonActions();
		SpritePlacement();
		Tutorial.SetupTutorial();
		OnReadyMixing();
		RealTimeAudioRecording.Initialize();
	}

	public override void _Process(double delta)
	{
		time += (float)delta;

		HandleCopyPasting();

		UpdateAchievementsVisibility();

		UpdateLayerOutlineSpriteRotation();

		if (Input.IsKeyPressed(Key.F6) && BpmManager.instance.bpm != 900) BpmManager.instance.bpm = 900;

		if (!Tutorial.tutorialActivated)
		{
			Tutorial.TryActivateTutorial();
			Tutorial.tutorialActivated = true;
		}

		if (copyPaseClearButtonHolderTimeSinceActivation >= 3.5f) SetCopyPasteClearButtonsActive(false);
		else copyPaseClearButtonHolderTimeSinceActivation += (float)delta;

		if (savingLabelActive && savingLabelTimer < 4) savingLabelTimer += (float)delta;
		else savingLabelActive = false;
		SavingLabel.Visible = savingLabelActive;

		UpdateLayerSwitchButtonsColors();

		PlayPauseButton.Text = BpmManager.instance.playing ? "⏸️" : "▶️";

		var miclightvalue = MicrophoneCapture.instance.volume * 8;
		if (miclightvalue > 1) miclightvalue = 1;
		if (miclightvalue < 0.05f) miclightvalue = 0;
		micVolumeLight.Energy = miclightvalue;

		float klappylightvalue = ((float)progressBar.Value) / 100f * 2f;
		if (klappylightvalue > 1) klappylightvalue = 1;
		if (klappylightvalue < 0.05f) klappylightvalue = 0;
		klappyLight.Energy = klappylightvalue;

		micmeter.Value = MicrophoneCapture.instance.volume;

		metronome_sfx_enabled = metronome_toggle.ButtonPressed;

		Tutorial.UpdateTutorial();

		HandleParticles(delta);

		// deal with arrowkeys
		up_pressed_lastframe = up_pressed;
		up_pressed = Input.IsKeyPressed(Key.Up);
		if (up_pressed && up_pressed != up_pressed_lastframe) OnBpmUpButton();
		dn_pressed_lastframe = dn_pressed;
		dn_pressed = Input.IsKeyPressed(Key.Down);
		if (dn_pressed && dn_pressed != dn_pressed_lastframe) OnBpmDownButton();

		// update swing amount
		BpmManager.instance.swing = (float)swingslider.Value;

		// space as play/pause
		var spacedown = Input.IsKeyPressed(Key.Space);
		if (spacedown && spacedownlastframe == false && !emailPromptOpen) OnPlayPauseButton();
		spacedownlastframe = spacedown;

		// enter as reset player
		var enterdown = Input.IsKeyPressed(Key.Enter);
		if (enterdown && enterdownlastframe == false && emailPromptOpen) { AudioSaving.CloseEmailPromptAndSaveAndSendSongFile(); }
		enterdownlastframe = enterdown;

		// drag&drop
		if (dragginganddropping)
		{
			draganddropthing.Modulate = colors[holdingforring];
			draganddropthing.Position = GetViewport().GetMousePosition() - (DisplayServer.WindowGetSize() / 2);
		}
		else draganddropthing.Modulate = new Color(1, 1, 1, 0);

		// update pointer
		float intergerFactor = (float)((float)(BpmManager.instance.currentBeat + (BpmManager.instance.beatTimer / BpmManager.instance.timePerBeat)) / (float)BpmManager.beatsAmount);
		pointer.RotationDegrees = intergerFactor * 360f - 7f;

		CheckIfClappingOrStomping();

		// make fullscreen if f11 is pressed
		f11_pressed_lastframe = f11_pressed;
		f11_pressed = Input.IsKeyPressed(Key.F11);
		bool toggle = f11_pressed && f11_pressed != f11_pressed_lastframe;
		if (toggle)
		{
			GD.Print("Toggle Fullscreen");
			var window = GetWindow();
			if (window.Mode == Window.ModeEnum.Fullscreen) window.Mode = Window.ModeEnum.Windowed;
			else window.Mode = Window.ModeEnum.Fullscreen;
		}

		if (BpmManager.instance.playing)
		{
			timeafterplay += ((float)delta);

			slowBeatTimer += (float)delta / 4;
			if (slowBeatTimer > BpmManager.instance.timePerBeat) slowBeatTimer -= BpmManager.instance.timePerBeat;
			var beatprogress = slowBeatTimer / BpmManager.instance.timePerBeat;
			metronome.Position = new Vector2(metronome.Position.X, Mathf.Lerp(-0.4f, 0.4f, beatprogress));

			if (progressBarValue > 100) progressBarValue = 100;
			progressBar.Value = progressBarValue;
		}
		else timeafterplay = 0;

		UpdateBeatSprites(delta);

		bpmLabel.Text = BpmManager.instance.bpm.ToString();

		songModeBackPanel.Visible = layerLoopToggle.ButtonPressed;

		OnUpdateMixing((float)delta);

		RealTimeAudioRecording.Update((float)delta);
	}
}
