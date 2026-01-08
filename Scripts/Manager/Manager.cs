using System;
using System.Globalization;
using System.Text.RegularExpressions;
using Godot;

[GlobalClass]
public partial class Manager : Node
{
	public static Manager instance = null;

	public override void _ExitTree()
	{
		Achievements.Reset();
		if (instance == this) instance = null;
	}

	public override void _Ready()
	{
		instance ??= this;
		SpawnInitialLayerButtons();
		BpmManager.instance.OnBeatEvent += OnBeat;
		Tutorial.CheckIfTutorialWasChosen();
		Achievements.CheckIfAchievementsModeShouldBeActive();
		ReadJsonFromPreviousSceneAndSetValues();
		InitAllAudioPlayers();
		InitButtonActions();
		SpritePlacement();
		Tutorial.SetupTutorial();
		ExecuteNextFrame(SamplesMixing_ReApplyRememberedMixingVolumesForAllRings);
		ExecuteNextFrame(SynthMixing_ReApplyRememberedMixingVolumesForBothSynths);
		Achievements.OnReady();
		OnReadyMixing();
		UpdateLayerButtonsUserInterfaceDelayed();
		DisplayServer.TtsSetUtteranceCallback(DisplayServer.TtsUtteranceEvent.Ended, new Callable(this,nameof(UtteranceEnd)));

		// set chaos activate buttons colors (non drag drop buttons)
		activateGreenChaosButton.SelfModulate = colors[4];
		activatePurpleChaosButton.SelfModulate = colors[5];
		(SongSelectButton.GetParent() as Sprite2D).SelfModulate = colors[6];

		// set mic buttons colors
		for (int i = 0; i < micButtons.Length; i++) micButtons[i].SelfModulate = colors[i];

		// set line colors (not needed, they inherit the colors)
		layerVoiceOver0.bigLine.SelfModulate = colors[4];
		layerVoiceOver1.bigLine.SelfModulate = colors[5];
		layerVoiceOver0.smallLine.SelfModulate = colors[4];
		layerVoiceOver1.smallLine.SelfModulate = colors[5];

		originalDraganddropButton0Scale = draganddropButton0.Scale.X;
		originalDraganddropButton1Scale = draganddropButton1.Scale.X;
		originalDraganddropButton2Scale = draganddropButton2.Scale.X;
		originalDraganddropButton3Scale = draganddropButton3.Scale.X;
	}

	private void UtteranceEnd(int utterancId)
	{
		EmitSignal("OnUtteranceEnd", utterancId);
	}

	public override void _Process(double delta)
	{
		time += (float)delta;

		HandleCopyPasting();

		if (isShowingCountDown) UpdateCountDownLabel();

		if (SamplesMixing_activeRing == 0) ((Sprite2D)draganddropButton0.FindChild("OutlineSprite")).Texture = filled_beat_textures[0];
		else ((Sprite2D)draganddropButton0.FindChild("OutlineSprite")).Texture = outline_beat_textures[0];

		if (SamplesMixing_activeRing == 1) ((Sprite2D)draganddropButton1.FindChild("OutlineSprite")).Texture = filled_beat_textures[1];
		else ((Sprite2D)draganddropButton1.FindChild("OutlineSprite")).Texture = outline_beat_textures[1];

		if (SamplesMixing_activeRing == 2) ((Sprite2D)draganddropButton2.FindChild("OutlineSprite")).Texture = filled_beat_textures[2];
		else ((Sprite2D)draganddropButton2.FindChild("OutlineSprite")).Texture = outline_beat_textures[2];

		if (SamplesMixing_activeRing == 3) ((Sprite2D)draganddropButton3.FindChild("OutlineSprite")).Texture = filled_beat_textures[3];
		else ((Sprite2D)draganddropButton3.FindChild("OutlineSprite")).Texture = outline_beat_textures[3];

		UpdateLayerOutlineSpriteRotation();

		if (!Input.IsKeyPressed(Key.Shift) && Input.IsKeyPressed(Key.F6) && BpmManager.instance.bpm != 900) BpmManager.instance.bpm = 900;
		if (Input.IsKeyPressed(Key.Shift) && Input.IsKeyPressed(Key.F6) && BpmManager.instance.bpm != 4000) BpmManager.instance.bpm = 4000;
		if (Input.IsKeyPressed(Key.Ctrl) && Input.IsKeyPressed(Key.F6) && BpmManager.instance.bpm != 90) BpmManager.instance.bpm = 90;

		if (!interfaceSetToDefaultState)
		{
			SetEntireInterfaceVisibility(true);
			SetCopyPasteClearButtonsActive(false);
			achievementspanel.Visible = false;
			interfaceSetToDefaultState = true;
		}

		if (!Tutorial.tutorialActivated)
		{
			Tutorial.TryActivateTutorial();
			Tutorial.tutorialActivated = true;
		}

		Achievements.OnUpdate();

		if (copyPaseClearButtonHolderTimeSinceActivation >= 3.5f) SetCopyPasteClearButtonsActive(false);
		else if (anyLayerButtonHasBeenPressed) copyPaseClearButtonHolderTimeSinceActivation += (float)delta;

		if (savingLabelActive && savingLabelTimer < 4) savingLabelTimer += (float)delta;
		else savingLabelActive = false;
		SavingLabel.Visible = savingLabelActive;

		UpdateLayerSwitchButtonsColors();

		PlayPauseButton.Text = BpmManager.instance.playing ? "⏸️" : "▶️";

		var miclightvalue = MicrophoneCapture.instance.volume * 8;
		if (miclightvalue > 1) miclightvalue = 1;
		if (miclightvalue < 0.05f) miclightvalue = 0;
		micVolumeLight.Energy = miclightvalue;

		micVolumeLight.Visible = chaosPadTriangleSprite.Visible;

		float klappylightvalue = ((float)progressBar.Value) / 100f * 2f;
		if (klappylightvalue > 1) klappylightvalue = 1;
		if (klappylightvalue < 0.05f) klappylightvalue = 0;
		klappyLight.Energy = klappylightvalue;

		Sprite2D[] glow = new Sprite2D[4];
		glow[0] = (Sprite2D)draganddropButton0.FindChild("Glow");
		glow[1] = (Sprite2D)draganddropButton1.FindChild("Glow");
		glow[2] = (Sprite2D)draganddropButton2.FindChild("Glow");
		glow[3] = (Sprite2D)draganddropButton3.FindChild("Glow");

		for (int i = 0; i < glow.Length; i++)
		{
			var ringLight = glow[i];
			var busindex = AudioServer.GetBusIndex($"Ring{i}");
			var analyzer = (AudioEffectSpectrumAnalyzerInstance)AudioServer.GetBusEffectInstance(busindex, 0);
			var magnitude = analyzer.GetMagnitudeForFrequencyRange(20, 20000);
			var volume = magnitude.Length() * 10f;
			float alpha = 0f;
			if (volume > 0.10f) alpha = volume;
			else alpha = 0f;
			ringLight.SelfModulate = new Color(1, 1, 1, alpha);
		}

		UpdateGreenPurpleButtonLights();

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
		if (spacedown && spacedownlastframe == false && !emailPromptOpen && !PlayPauseButton.Disabled) OnPlayPauseButton();
		spacedownlastframe = spacedown;

		// enter as reset player
		var enterdown = Input.IsKeyPressed(Key.Enter);
		if (enterdown && enterdownlastframe == false && emailPromptOpen) { cachedEmailPromptAction.Invoke(); CloseEmailPrompt(); }
		enterdownlastframe = enterdown;

		// drag&drop
		if (dragginganddropping)
		{
			draganddropthing.Modulate = colors[holdingforring];
			draganddropthing.Position = GetViewport().GetMousePosition() - new Vector2(1280, 720) / 2;
		}
		else draganddropthing.Modulate = new Color(1, 1, 1, 0);

		// update pointer
		if (BpmManager.instance.playing)
		{
			float intergerFactor = (float)((float)(BpmManager.instance.currentBeat + (BpmManager.instance.beatTimer / BpmManager.instance.timePerBeat)) / (float)BpmManager.beatsAmount);
			pointer.RotationDegrees = intergerFactor * 360f - 7f;
		}

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

		recordingDelayLabel.Text = recordingDelaySlider.Value.ToString("0.00") + "s";

		if (BpmManager.instance.playing)
		{
			timeafterplay += ((float)delta);

			slowBeatTimer += (float)delta / 4;
			if (slowBeatTimer > BpmManager.instance.timePerBeat) slowBeatTimer -= BpmManager.instance.timePerBeat;
			var beatprogress = slowBeatTimer / BpmManager.instance.timePerBeat;
			metronome.Position = new Vector2(metronome.Position.X, Mathf.Lerp(-0.4f, 0.4f, beatprogress));
		}
		else timeafterplay = 0;

		if (progressBarValue > 100) progressBarValue = 100;
		if (progressBarValue < 0) progressBarValue = 0;
		progressBar.Value = progressBarValue;

		UpdateBeatSprites(delta);

		bpmLabel.Text = BpmManager.instance.bpm.ToString();

		songModeBackPanel.Visible = layerLoopToggle.ButtonPressed;

		OnUpdateMixing((float)delta);
	}

	public string Text_without_emoticons(string message)
	{
		var without_emoticons = (string input) =>
		{
			var output = "";
			var stringInfo = new StringInfo(input);
			for (int i = 0; i < stringInfo.LengthInTextElements; i++)
			{
				string element = stringInfo.SubstringByTextElements(i, 1);
				if (!Regex.IsMatch(element, @"\p{Cs}|\p{So}|\p{Sk}|\p{Mn}|\u200D")) output += element;
			}

			return output;
		};
		return without_emoticons(message);
	}
	
	public bool tutorialActivated()
	{
		return Tutorial.useTutorial;
	}
}
