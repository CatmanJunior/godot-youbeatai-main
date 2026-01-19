using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using Godot;

public partial class Manager : Node
{
	// switch layer buttons
	[Export] PackedScene layerButtonPrefab;
	[Export] HBoxContainer layerButtonsContainer;
	[Export] Button addLayerButton;

	// left buttons
	[Export] Button SaveLayoutButton;
	[Export] Button LoadLayoutButton;
	[Export] Button ClearLayoutButton;
	[Export] public Button PlayPauseButton;
	[Export] Button BpmUpButton;
	[Export] Button BpmDownButton;

	// idk
	[Export] public Button SongSelectButton;

	// sample buttons
	[Export] public Sprite2D draganddropButton0;
	[Export] public Sprite2D draganddropButton1;
	[Export] public Sprite2D draganddropButton2;
	[Export] public Sprite2D draganddropButton3;
	[Export] public RecordSampleButton recordSampleButton0;
	[Export] public RecordSampleButton recordSampleButton1;
	[Export] public RecordSampleButton recordSampleButton2;
	[Export] public RecordSampleButton recordSampleButton3;

	public ProgressBar songModeBackPanel => RealTimeAudioRecording.instance?.progressbar;

	// other interface
	[Export] public Node2D[] NodesThatCanBeUnlocked;
	[Export] public Button restartButton;
	[Export] public CheckButton muteSpeach;
	[Export] public Button saveToWavButton;
	[Export] public Node2D cross;
	[Export] Label chosen_emoticons_label;
	[Export] public CheckButton metronome_toggle;
	[Export] ProgressBar micmeter;
	[Export] public CheckButton add_beats;
	[Export] public CheckButton button_is_clap;
	[Export] public CheckButton button_add_beats;
	[Export] public Slider volume_treshold;
	[Export] public Slider recordingDelaySlider;
	[Export] public Label recordingDelayLabel;
	[Export] public Panel settingsPanel;
	[Export] public Button settingsButton;
	[Export] public Button settingsBackButton;
	[Export] Button skiptutorialbutton;
	[Export] public ProgressBar progressBar;
	public float progressBarValue = 25;
	[Export] public Sprite2D pointer;
	[Export] public Sprite2D metronome;
	[Export] public Sprite2D metronomebg;
	[Export] Label bpmLabel;
	[Export] Sprite2D draganddropthing;
	public bool dragginganddropping = false;
	public int holdingforring;
	[Export] Slider swingslider;
	[Export] Label swinglabel;
	[Export] Slider ClapBiasSlider;
	[Export] public Panel achievementspanel;
	[Export] public CheckButton layerLoopToggle;
	[Export] Label SavingLabel;
	bool savingLabelActive = false;
	float savingLabelTimer = 0;
	[Export] public Label InstructionLabel;
	[Export] public Button allLayersToMp3;
	[Export] Sprite2D layerOutline;
	[Export] Node2D layerOutlineHolder;
	

	float global_beat_sprite_scale_factor = 0.28f;
	float beatScale32 = 1;
	float beatScale16 = 1.6f;
	float beatScale8 = 1.6f;

	[Export] PackedScene spritePrefab;

	public Sprite2D[,] beatSprites;

	[Export] Texture2D[] filled_beat_textures;
	[Export] Texture2D[] outline_beat_textures;
	[Export] Texture2D[] dotted_synth_textures;
	[Export] Texture2D[] outline_synth_textures;
	[Export] Texture2D filled_song_texture;
	[Export] Texture2D outline_song_texture;
	[Export] Texture2D dot_beat_texture;

	Sprite2D[,] templateSprites;
	[Export] public Color[] colors;
	public Color[] colorsOverride;
	[Export] PointLight2D micVolumeLight;
	[Export] PointLight2D klappyLight;
	[Export] public Sprite2D activateGreenChaosButton;
	[Export] public Sprite2D activatePurpleChaosButton;
	[Export] Node2D copyPasteClearButtonsHolder;
	[Export] public Button ContinueButton;
	[Export] public Button KlappyContinue;
	[Export] public Area2D KnobArea;
	[Export] public Label AmountLeft;
	[Export] public Button greenLayerRecordButton;
	public Sprite2D ChaosIconTop;
	float copyPaseClearButtonHolderTimeSinceActivation = 0;

	private void SetCopyPasteClearButtonsActive(bool active)
	{
		copyPasteClearButtonsHolder.Visible = active;
		copyPasteClearButtonsHolder.Position = active ? Vector2.Zero : copyPasteClearButtonsHolder.Position + new Vector2(0, 20000);
		copyPaseClearButtonHolderTimeSinceActivation = 0;
	}

	private void InitButtonActions()
	{
		colorsOverride = colors;

		foreach (var button in emojiButtons) button.ButtonUp += () => { AddLayer(currentLayerIndex + 1, button.Text); CloseEmojiPrompt(); addedLayer = true; };
		emojiPromptCancelButton.ButtonUp += CloseEmojiPrompt;

		allLayersToMp3.ButtonUp += () => { OpenEmailPrompt(AudioSaving.SaveRealTimeRecordedSongAsFileAndSendToEmail); settingsPanel.Visible = false; };
		saveToWavButton.Pressed += () => { OpenEmailPrompt(AudioSaving.SaveRealTimeRecordedBeatAsFileAndSendToEmail); settingsPanel.Visible = false; };
		muteSpeach.Pressed += DisplayServer.TtsStop;

		SaveLayoutButton.Pressed += () => { CopyLayer(); PlayExtraSFX(metronomealt_sfx); };
		LoadLayoutButton.Pressed += () => { PasteLayer(); PlayExtraSFX(metronomealt_sfx); };
		ClearLayoutButton.Pressed += () => { ConfirmationPrompt.instance.Open(ClearLayer); PlayExtraSFX(metronomealt_sfx); };

		addLayerButton.ButtonUp += () => 
		{
			OpenEmojiPrompt(); PlayExtraSFX(metronomealt_sfx);

			if (!pressed_add_layer_once)
			{
				TooltipHelper.OpenTooltip("Oke nu gaat het echt beginnen, klick zometeen de songmode knop!");
				TooltipHelper.StartLoopToCheckIfTooltipCanClose();
				pressed_add_layer_once = true;
			}
		};

		restartButton.Pressed += () =>
		{
			GetTree().ChangeSceneToFile("res://Scenes/main_menu.tscn");
			
			string[] filesToReset = 
			[
				Path.Combine(ProjectSettings.GlobalizePath("user://"), "chosen_emoticons.json"),
				Path.Combine(ProjectSettings.GlobalizePath("user://"), "chosen_soundbank.json"),
				Path.Combine(ProjectSettings.GlobalizePath("user://"), "beats_amount.txt"),
				Path.Combine(ProjectSettings.GlobalizePath("user://"), "use_tutorial.txt"),
				Path.Combine(ProjectSettings.GlobalizePath("user://"), "use_achievements.txt")
			];

			foreach (var path in filesToReset) File.Delete(path);

			Tutorial.Reset();
			Achievements.Reset();
		};
		PlayPauseButton.ButtonUp += OnPlayPauseButton;
		BpmUpButton.Pressed += OnBpmUpButton;
		BpmDownButton.Pressed += OnBpmDownButton;
		skiptutorialbutton.Pressed += () =>
		{
			Tutorial.tutorial_level = -1;
			SetEntireInterfaceVisibility(true);
			achievementspanel.Visible = false;
			if (DisplayServer.TtsIsSpeaking()) DisplayServer.TtsStop();
		};
		settingsButton.Pressed += () => settingsPanel.Visible = !settingsPanel.Visible;
		settingsBackButton.Pressed += () => settingsPanel.Visible = !settingsPanel.Visible;
		var Button = SongSelectButton;
        Button.ButtonUp += () =>
        {
            layerLoopToggle.ButtonPressed = !layerLoopToggle.ButtonPressed;
			SongMixing_ChangeToSongMixer();
        };
	}

	private void UpdateLayerOutlineSpriteRotation()
	{
		if (BpmManager.instance.timePerBeat != 0)
		{
			float clockrot = (float)((float)(BpmManager.instance.currentBeat + (BpmManager.instance.beatTimer / BpmManager.instance.timePerBeat)) / (float)BpmManager.beatsAmount);
			layerOutline.RotationDegrees = clockrot * 360f - 7f;
		}
		else
		{
			float clockrot = (float)(BpmManager.instance.currentBeat / (float)BpmManager.beatsAmount);
			layerOutline.RotationDegrees = clockrot * 360f - 7f;
		}
	}

	float originalDraganddropButton0Scale;
	float originalDraganddropButton1Scale;
	float originalDraganddropButton2Scale;
	float originalDraganddropButton3Scale;

	private void UpdateBeatSprites(double delta)
	{
		// update drag and drop button sprite scale
		if (draganddropButton0.Scale.X > originalDraganddropButton0Scale) draganddropButton0.Scale -= Vector2.One * (float)delta * 2;
		if (draganddropButton1.Scale.X > originalDraganddropButton1Scale) draganddropButton1.Scale -= Vector2.One * (float)delta * 2;
		if (draganddropButton2.Scale.X > originalDraganddropButton2Scale) draganddropButton2.Scale -= Vector2.One * (float)delta * 2;
		if (draganddropButton3.Scale.X > originalDraganddropButton3Scale) draganddropButton3.Scale -= Vector2.One * (float)delta * 2;

		// update beat sprites
		for (int beat = 0; beat < BpmManager.beatsAmount; beat++)
		{
			for (int ring = 0; ring < 4; ring++)
			{
				var sprite = beatSprites[ring, beat];
				var active = beatActives[ring, beat];

				sprite.Texture = active ? filled_beat_textures[ring] : outline_beat_textures[ring];

				var color = new Color(1, 1, 1, 1f);
				if (beat == BpmManager.instance.currentBeat && active) color = color.Lightened(0.75f);
				sprite.Modulate = color;

				float scale = 1;
				if (BpmManager.beatsAmount == 32) scale = beatScale32;
				if (BpmManager.beatsAmount == 16) scale = beatScale16;
				if (BpmManager.beatsAmount == 8) scale = beatScale8;
				if (sprite.Scale.X > scale * global_beat_sprite_scale_factor) sprite.Scale -= Vector2.One * (float)delta * 0.3f;
			}
		}

		// update template sprites
		for (int beat = 0; beat < BpmManager.beatsAmount; beat++)
		{
			for (int ring = 0; ring < 4; ring++)
			{
				var sprite = templateSprites[ring, beat];
				var active = TemplateManager.instance.GetCurrentActives()[ring, beat];
				sprite.Modulate = new Color(0, 0, 0, 0);
				if (active && showTemplate) sprite.Modulate = new Color(0, 0, 0, 1);
			}
		}
	}

	[Export] public Node2D BearRingPivotPoint;

	void SpritePlacement()
	{
		// spawn sprites
		beatSprites = new Sprite2D[4, BpmManager.beatsAmount];
		for (int ring = 0; ring < 4; ring++)
		{
			for (int beat = 0; beat < BpmManager.beatsAmount; beat++)
			{
				var sprite = CreateSprite(beat, ring);
				BearRingPivotPoint.AddChild(sprite);
				beatSprites[ring, beat] = sprite;
			}
		}

		// spawn template sprites
		templateSprites = new Sprite2D[4, BpmManager.beatsAmount];
		for (int ring = 0; ring < 4; ring++)
		{
			for (int beat = 0; beat < BpmManager.beatsAmount; beat++)
			{
				var sprite = CreateTemplateSprite(beat, ring);
				BearRingPivotPoint.AddChild(sprite);
				templateSprites[ring, beat] = sprite;
			}
		}
	}

	private Vector2 SpritePosition(int beat, int ring)
	{
		float angle = Mathf.Pi * 2 * beat / BpmManager.beatsAmount - Mathf.Pi / 2;

		float distance = 0;

		if (BpmManager.beatsAmount == 32) distance = (4 - ring) * 30 + 110;
		else if (BpmManager.beatsAmount == 16) distance = (4 - ring) * 45 + 56;
		else if (BpmManager.beatsAmount == 8) distance = (4 - ring) * 45 + 56;

		return new Vector2(Mathf.Cos(angle), Mathf.Sin(angle)) * distance;
	}

	private float SpriteRotation(int beat, int ring)
	{
		float angle = Mathf.Pi * 2 * beat / BpmManager.beatsAmount;
		return angle;
	}

	private Sprite2D CreateSprite(int beat, int ring)
	{
		var sprite = (Sprite2D)spritePrefab.Instantiate();
		sprite.Position = SpritePosition(beat, ring);
		sprite.Rotation = SpriteRotation(beat, ring);

		BeatSprite beatSprite = sprite as BeatSprite;
		beatSprite.spriteIndex = beat;
		beatSprite.ring = ring;

		float scale = 1;
		if (BpmManager.beatsAmount == 32) scale = beatScale32;
		if (BpmManager.beatsAmount == 16) scale = beatScale16;
		if (BpmManager.beatsAmount == 8) scale = beatScale8;
		sprite.Scale = Vector2.One * scale * global_beat_sprite_scale_factor;

		sprite.Texture = filled_beat_textures[ring];
		
		return sprite;
	}

	private Sprite2D CreateTemplateSprite(int beat, int ring)
	{
		var sprite = new Sprite2D();
		sprite.Position = SpritePosition(beat, ring);
		sprite.Rotation = SpriteRotation(beat, ring);
		sprite.Texture = dot_beat_texture;
		sprite.Modulate = new Color(0, 0, 0, 1);
		return sprite;
	}

	private void UpdateLayerSwitchButtonsColors()
	{
		for (int i = 0; i < LayerButtons.Count; i++)
		{
			LayerButtons[i].Modulate = new Color(1, 1, 1, 1);
			if (!LayerHasBeats(layersBeatActives[i])) LayerButtons[i].Modulate = LayerButtons[i].Modulate.Darkened(0.5f);
		}
	}
}