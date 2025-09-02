using Godot;

using System;
using System.IO;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Globalization;
using System.Threading.Tasks;
using System.Collections.Generic;

using NAudio.Wave;
using NAudio.Lame;
using NAudio.Wave.SampleProviders;

public partial class Manager : Node
{
    public static Manager instance = null;

    #region Ready

    public override void _Ready()
    {
        instance ??= this;
        BpmManager.instance.OnBeatEvent += OnBeat;
        ReadJsonFromPreviousSceneAndSetValues();
        InitAllAudioPlayers();
        SetupAllMixers();
        InitButtonActions();
        SpritePlacement();
        SetupTutorial();
    }
    
    #endregion

    #region Process

    public override void _Process(double delta)
    {
        time += (float)delta;

        UpdateAllMixerVolumes();

        if (emailPromptOpen && Input.IsKeyPressed(Key.Enter)) AllLayersToMp3();

        HandleCopyPasting();

        UpdateAchievementsVisibility();

        UpdateLayerOutlineSpriteRotation();

        if (Input.IsKeyPressed(Key.F6) && BpmManager.instance.bpm != 900) BpmManager.instance.bpm = 900;

        if (!tutorialActivated)
        {
            TryActivateTutorial();
            tutorialActivated = true;
        }

        if (savingLabelActive && savingLabelTimer < 4) savingLabelTimer += (float)delta;
        else savingLabelActive = false;
        SavingLabel.Visible = savingLabelActive;

        UpdateLayerSwitchButtonsColors();

        var lightvalue = MicrophoneCapture.instance.volume * 8;
        if (lightvalue > 1) lightvalue = 1;
        if (lightvalue < 0.05f) lightvalue = 0;
        robotlight.Energy = lightvalue;

        micmeter.Value = MicrophoneCapture.instance.volume;

        metronome_sfx_enabled = metronome_toggle.ButtonPressed;

        UpdateTutorial();

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
        if (enterdown && enterdownlastframe == false && !emailPromptOpen) { /* do something with enter */ }
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
    }

    #endregion

    #region BeatActives

    public bool[,] beatActives = new bool[4, BpmManager.beatsAmount];

    #endregion

    #region Events
    [Signal] public delegate void OnSwitchLayerEventHandler(int layer);
    [Signal] public delegate void OnShouldClapEventEventHandler();
    [Signal] public delegate void OnShouldStompEventEventHandler();
    #endregion

    #region VoiceOver
    [Export] public LayerVoiceOver layerVoiceOver0;
    [Export] public LayerVoiceOver layerVoiceOver1;
    #endregion

    #region AudioPlayers
    public AudioStreamPlayer2D firstAudioPlayer;
    public AudioStreamPlayer2D secondAudioPlayer;
    public AudioStreamPlayer2D thirdAudioPlayer;
    public AudioStreamPlayer2D fourthAudioPlayer;
    public AudioStreamPlayer2D firstAudioPlayerAlt;
    public AudioStreamPlayer2D secondAudioPlayerAlt;
    public AudioStreamPlayer2D thirdAudioPlayerAlt;
    public AudioStreamPlayer2D fourthAudioPlayerAlt;
    public AudioStreamPlayer2D firstAudioPlayerRec;
    public AudioStreamPlayer2D secondAudioPlayerRec;
    public AudioStreamPlayer2D thirdAudioPlayerRec;
    public AudioStreamPlayer2D fourthAudioPlayerRec;
    public AudioStreamPlayer2D sfxAudioPlayer;

    private void InitAllAudioPlayers()
    {
        // init audioplayers
        sfxAudioPlayer = new AudioStreamPlayer2D();
        AddChild(sfxAudioPlayer);
        firstAudioPlayer = new AudioStreamPlayer2D();
        secondAudioPlayer = new AudioStreamPlayer2D();
        thirdAudioPlayer = new AudioStreamPlayer2D();
        fourthAudioPlayer = new AudioStreamPlayer2D();
        AddChild(firstAudioPlayer);
        AddChild(secondAudioPlayer);
        AddChild(thirdAudioPlayer);
        AddChild(fourthAudioPlayer);
        firstAudioPlayerAlt = new AudioStreamPlayer2D();
        secondAudioPlayerAlt = new AudioStreamPlayer2D();
        thirdAudioPlayerAlt = new AudioStreamPlayer2D();
        fourthAudioPlayerAlt = new AudioStreamPlayer2D();
        AddChild(firstAudioPlayerAlt);
        AddChild(secondAudioPlayerAlt);
        AddChild(thirdAudioPlayerAlt);
        AddChild(fourthAudioPlayerAlt);
        firstAudioPlayerRec = new AudioStreamPlayer2D();
        secondAudioPlayerRec = new AudioStreamPlayer2D();
        thirdAudioPlayerRec = new AudioStreamPlayer2D();
        fourthAudioPlayerRec = new AudioStreamPlayer2D();
        AddChild(firstAudioPlayerRec);
        AddChild(secondAudioPlayerRec);
        AddChild(thirdAudioPlayerRec);
        AddChild(fourthAudioPlayerRec);
        firstAudioPlayer.Stream = mainAudioFiles[0];
        secondAudioPlayer.Stream = mainAudioFiles[1];
        thirdAudioPlayer.Stream = mainAudioFiles[2];
        fourthAudioPlayer.Stream = mainAudioFiles[3];
        firstAudioPlayerAlt.Stream = mainAudioFilesAlt[0];
        secondAudioPlayerAlt.Stream = mainAudioFilesAlt[1];
        thirdAudioPlayerAlt.Stream = mainAudioFilesAlt[2];
        fourthAudioPlayerAlt.Stream = mainAudioFilesAlt[3];
    }

    #endregion

    #region AudioFiles
    [Export] public AudioStream[] mainAudioFiles;
    [Export] public AudioStream[] mainAudioFilesAlt;
    [Export] public AudioStream metronome_sfx;
    [Export] AudioStream metronomealt_sfx;
    [Export] AudioStream achievement_sfx;
    #endregion

    #region Particles
    [Export] public CpuParticles2D beat_particles;
    private Vector2 beat_particles_position;
    private float beat_particles_time;
    private float beat_particles_curtime;
    private Color beat_particles_color;
    private bool beat_particles_emitting = false;
    [Export] public CpuParticles2D pbar_particles;
    private float pbar_particles_time;
    private float pbar_particles_curtime;
    private bool pbar_particles_emitting = false;
    [Export] public CpuParticles2D achievement_particles;
    private float achievement_particles_time;
    private float achievement_particles_curtime;
    private bool achievement_particles_emitting = false;

    private void HandleParticles(double delta)
    {
        // deal with beat particles
        if (beat_particles_emitting && beat_particles_curtime < beat_particles_time)
        {
            beat_particles.Color = beat_particles_color;
            beat_particles.Position = beat_particles_position;
            beat_particles.Emitting = true;
            beat_particles_curtime += (float)delta;
        }
        else
        {
            beat_particles.Emitting = false;
            beat_particles_emitting = false;
        }

        // deal with progress bar particles
        if (pbar_particles_emitting && pbar_particles_curtime < pbar_particles_time)
        {
            pbar_particles.Emitting = true;
            pbar_particles_curtime += (float)delta;
        }
        else
        {
            pbar_particles.Emitting = false;
            pbar_particles_emitting = false;
        }

        // deal with progress bar particles
        if (achievement_particles_emitting && achievement_particles_curtime < achievement_particles_time)
        {
            achievement_particles.Emitting = true;
            achievement_particles_curtime += (float)delta;
        }
        else
        {
            achievement_particles.Emitting = false;
            achievement_particles_emitting = false;
        }
    }

    public void EmitBeatParticles(Vector2 position, Color color)
    {
        beat_particles_curtime = 0;
        beat_particles_time = 0.05f;
        beat_particles_position = position;
        beat_particles_color = color.Lightened(0.25f);
        beat_particles_emitting = true;
    }

    public void EmitProgressBarParticles()
    {
        pbar_particles_curtime = 0;
        pbar_particles_time = 0.4f;
        pbar_particles_emitting = true;
    }

    public void EmitAchievementParticles()
    {
        achievement_particles_curtime = 0;
        achievement_particles_time = 0.5f;
        achievement_particles_emitting = true;
    }
    #endregion

    #region UserInterface

    // switch layer buttons
    [Export] Button layerButton1;
    [Export] Button layerButton2;
    [Export] Button layerButton3;
    [Export] Button layerButton4;
    [Export] Button layerButton5;
    [Export] Button layerButton6;
    [Export] Button layerButton7;
    [Export] Button layerButton8;
    [Export] Button layerButton9;
    [Export] Button layerButton10;

    // left buttons
    [Export] Button SaveLayoutButton;
    [Export] Button LoadLayoutButton;
    [Export] Button ClearLayoutButton;
    [Export] public Button PlayPauseButton;
    [Export] Button BpmUpButton;
    [Export] Button BpmDownButton;

    // sample buttons
    [Export] public Sprite2D draganddropButton0;
    [Export] public Sprite2D draganddropButton1;
    [Export] public Sprite2D draganddropButton2;
    [Export] public Sprite2D draganddropButton3;
    [Export] public RecordSampleButton recordSampleButton0;
    [Export] public RecordSampleButton recordSampleButton1;
    [Export] public RecordSampleButton recordSampleButton2;
    [Export] public RecordSampleButton recordSampleButton3;

    // other interface
    [Export] public Label[] Unlockables;
    [Export] public Label[] UnlockablesQuestion;
    [Export] public Button restartButton;
    [Export] public Panel songModeBackPanel;
    [Export] public CheckButton muteSpeach;
    [Export] Button saveToWavButton;
    [Export] public Node2D cross;
    [Export] Label chosen_emoticons_label;
    [Export] public CheckButton metronome_toggle;
    [Export] ProgressBar micmeter;
    [Export] CheckButton add_beats;
    [Export] public CheckButton button_is_clap;
    [Export] Slider volume_treshold;
    [Export] Panel settingsPanel;
    [Export] Button settingsButton;
    [Export] Button settingsBackButton;
    [Export] Button skiptutorialbutton;
    [Export] ProgressBar progressBar;
    float progressBarValue = 0;
    [Export] Sprite2D pointer;
    [Export] public Sprite2D metronome;
    [Export] public Sprite2D metronomebg;
    [Export] Label bpmLabel;
    [Export] Sprite2D draganddropthing;
    public bool dragginganddropping = false;
    public int holdingforring;
    [Export] Slider swingslider;
    [Export] Label swinglabel;
    [Export] Slider ClapBiasSlider;
    [Export] Panel achievementspanel;
    [Export] public CheckButton layerLoopToggle;
    [Export] Label SavingLabel;
    bool savingLabelActive = false;
    float savingLabelTimer = 0;
    [Export] Label InstructionLabel;
    [Export] Button allLayersToMp3;
    [Export] Sprite2D layerOutline;
    [Export] Node2D layerOutlineHolder;
    float beatScale32 = 1;
    float beatScale16 = 1.6f;
    float beatScale8 = 1.6f;
    [Export] PackedScene spritePrefab;
    [Export] Texture2D texture;
    [Export] Texture2D outline;
    Sprite2D[,] beatOutlines;
    public Sprite2D[,] beatSprites;
    Sprite2D[,] templateSprites;
    [Export] public Color[] colors;
    [Export] PointLight2D robotlight;

    private void InitButtonActions()
    {
        layerButton1.Pressed += () => { SwitchLayer(1); UpdateSongVoiceOverPlayBackPosition(); };
        layerButton2.Pressed += () => { SwitchLayer(2); UpdateSongVoiceOverPlayBackPosition(); };
        layerButton3.Pressed += () => { SwitchLayer(3); UpdateSongVoiceOverPlayBackPosition(); };
        layerButton4.Pressed += () => { SwitchLayer(4); UpdateSongVoiceOverPlayBackPosition(); };
        layerButton5.Pressed += () => { SwitchLayer(5); UpdateSongVoiceOverPlayBackPosition(); };
        layerButton6.Pressed += () => { SwitchLayer(6); UpdateSongVoiceOverPlayBackPosition(); };
        layerButton7.Pressed += () => { SwitchLayer(7); UpdateSongVoiceOverPlayBackPosition(); };
        layerButton8.Pressed += () => { SwitchLayer(8); UpdateSongVoiceOverPlayBackPosition(); };
        layerButton9.Pressed += () => { SwitchLayer(9); UpdateSongVoiceOverPlayBackPosition(); };
        layerButton10.Pressed += () => { SwitchLayer(10); UpdateSongVoiceOverPlayBackPosition(); };
        allLayersToMp3.Pressed += () => { OpenEmailPrompt(); settingsPanel.Visible = false; };
        emailEnter.Pressed += AllLayersToMp3;
        muteSpeach.Pressed += DisplayServer.TtsStop;
        SaveLayoutButton.Pressed += CopyLayer;
        LoadLayoutButton.Pressed += PasteLayer;
        ClearLayoutButton.Pressed += ClearLayer;
        restartButton.Pressed += () =>
        {
            if (Engine.IsEditorHint()) GetTree().ChangeSceneToFile("res://Scenes/main_menu.tscn");
            else
            {
                OS.Execute(OS.GetExecutablePath(), []);
                GetTree().Quit();
            }
        };
        PlayPauseButton.Pressed += OnPlayPauseButton;
        BpmUpButton.Pressed += OnBpmUpButton;
        BpmDownButton.Pressed += OnBpmDownButton;
        saveToWavButton.Pressed += () => SaveBeatAsFile(beatActives);
        skiptutorialbutton.Pressed += () =>
        {
            tutorial_level = -1;
            SetEntireInterfaceVisibility(true);
            achievementspanel.Visible = false;
            if (DisplayServer.TtsIsSpeaking()) DisplayServer.TtsStop();
        };
        settingsButton.Pressed += () => settingsPanel.Visible = !settingsPanel.Visible;
        settingsBackButton.Pressed += () => settingsPanel.Visible = !settingsPanel.Visible;
        var label1 = layerLoopToggle.GetChild(0) as Label;
        label1.GuiInput += args =>
        {
            if (args is InputEventMouseButton mouseEvent && mouseEvent.Pressed && mouseEvent.ButtonIndex == MouseButton.Left)
            {
                layerLoopToggle.ButtonPressed = !layerLoopToggle.ButtonPressed;
            }
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

    private void UpdateBeatSprites(double delta)
    {
        // update drag and drop button sprite scale
        if (draganddropButton0.Scale.X > 2) draganddropButton0.Scale -= Vector2.One * (float)delta * 2;
        if (draganddropButton1.Scale.X > 2) draganddropButton1.Scale -= Vector2.One * (float)delta * 2;
        if (draganddropButton2.Scale.X > 2) draganddropButton2.Scale -= Vector2.One * (float)delta * 2;
        if (draganddropButton3.Scale.X > 2) draganddropButton3.Scale -= Vector2.One * (float)delta * 2;

        // update beat sprites
        for (int beat = 0; beat < BpmManager.beatsAmount; beat++)
        {
            for (int ring = 0; ring < 4; ring++)
            {
                var sprite = beatSprites[ring, beat];
                var active = beatActives[ring, beat];

                var color = colors[ring];

                if (beat == BpmManager.instance.currentBeat)
                {
                    if (active) color = color.Lightened(0.75f);
                    else color = new(1, 1, 1, 0.5f);
                }
                else if (!active) color.A = 0.2f;

                sprite.Modulate = color;

                float scale = 1;
                if (BpmManager.beatsAmount == 32) scale = beatScale32;
                if (BpmManager.beatsAmount == 16) scale = beatScale16;
                if (BpmManager.beatsAmount == 8) scale = beatScale8;

                if (sprite.Scale.X > scale) sprite.Scale -= Vector2.One * (float)delta * 0.3f;
            }
        }

        // update beat outline sprites
        for (int beat = 0; beat < BpmManager.beatsAmount; beat++)
        {
            for (int ring = 0; ring < 4; ring++)
            {
                var outline = beatOutlines[ring, beat];
                outline.Modulate = colors[ring];
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

    void SpritePlacement()
    {
        // spawn sprites
        beatSprites = new Sprite2D[4, BpmManager.beatsAmount];
        for (int ring = 0; ring < 4; ring++)
        {
            for (int beat = 0; beat < BpmManager.beatsAmount; beat++)
            {
                var sprite = CreateSprite(beat, ring);
                AddChild(sprite);
                beatSprites[ring, beat] = sprite;
            }
        }

        // spawn outlines
        beatOutlines = new Sprite2D[4, BpmManager.beatsAmount];
        for (int ring = 0; ring < 4; ring++)
        {
            for (int beat = 0; beat < BpmManager.beatsAmount; beat++)
            {
                var outline = CreateOutline(beat, ring);
                AddChild(outline);
                beatOutlines[ring, beat] = outline;
            }
        }

        // spawn template sprites
        templateSprites = new Sprite2D[4, BpmManager.beatsAmount];
        for (int ring = 0; ring < 4; ring++)
        {
            for (int beat = 0; beat < BpmManager.beatsAmount; beat++)
            {
                var sprite = CreateTemplateSprite(beat, ring);
                AddChild(sprite);
                templateSprites[ring, beat] = sprite;
            }
        }
    }
    private Sprite2D CreateOutline(int beat, int ring)
    {
        var sprite = new Sprite2D();
        sprite.Position = SpritePosition(beat, ring);

        float scale = 1;
        if (BpmManager.beatsAmount == 32) scale = beatScale32;
        if (BpmManager.beatsAmount == 16) scale = beatScale16;
        if (BpmManager.beatsAmount == 8) scale = beatScale8;
        sprite.Scale = Vector2.One * scale;

        sprite.Texture = outline;
        return sprite;
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

    private Sprite2D CreateSprite(int beat, int ring)
    {
        var sprite = (Sprite2D)spritePrefab.Instantiate();
        sprite.Position = SpritePosition(beat, ring);

        BeatSprite beatSprite = sprite as BeatSprite;
        beatSprite.spriteIndex = beat;
        beatSprite.ring = ring;

        float scale = 1;
        if (BpmManager.beatsAmount == 32) scale = beatScale32;
        if (BpmManager.beatsAmount == 16) scale = beatScale16;
        if (BpmManager.beatsAmount == 8) scale = beatScale8;
        sprite.Scale = Vector2.One * scale;

        sprite.Texture = texture;
        
        return sprite;
    }

    private Sprite2D CreateTemplateSprite(int beat, int ring)
    {
        var sprite = new Sprite2D();
        sprite.Position = SpritePosition(beat, ring);
        sprite.Texture = texture;
        sprite.Modulate = new Color(0, 0, 0, 1);
        sprite.Scale = Vector2.One * 0.2f;
        return sprite;
    }

    private void UpdateLayerSwitchButtonsColors()
    {
        layerButton1.Modulate = new Color(1, 1, 1, 1);
        layerButton2.Modulate = new Color(1, 1, 1, 1);
        layerButton3.Modulate = new Color(1, 1, 1, 1);
        layerButton4.Modulate = new Color(1, 1, 1, 1);
        layerButton5.Modulate = new Color(1, 1, 1, 1);
        layerButton6.Modulate = new Color(1, 1, 1, 1);
        layerButton7.Modulate = new Color(1, 1, 1, 1);
        layerButton8.Modulate = new Color(1, 1, 1, 1);
        layerButton9.Modulate = new Color(1, 1, 1, 1);
        layerButton10.Modulate = new Color(1, 1, 1, 1);
        if (!LayerHasBeats(layers[0])) layerButton1.Modulate = layerButton1.Modulate.Darkened(0.5f);
        if (!LayerHasBeats(layers[1])) layerButton2.Modulate = layerButton2.Modulate.Darkened(0.5f);
        if (!LayerHasBeats(layers[2])) layerButton3.Modulate = layerButton3.Modulate.Darkened(0.5f);
        if (!LayerHasBeats(layers[3])) layerButton4.Modulate = layerButton4.Modulate.Darkened(0.5f);
        if (!LayerHasBeats(layers[4])) layerButton5.Modulate = layerButton5.Modulate.Darkened(0.5f);
        if (!LayerHasBeats(layers[5])) layerButton6.Modulate = layerButton6.Modulate.Darkened(0.5f);
        if (!LayerHasBeats(layers[6])) layerButton7.Modulate = layerButton7.Modulate.Darkened(0.5f);
        if (!LayerHasBeats(layers[7])) layerButton8.Modulate = layerButton8.Modulate.Darkened(0.5f);
        if (!LayerHasBeats(layers[8])) layerButton9.Modulate = layerButton9.Modulate.Darkened(0.5f);
        if (!LayerHasBeats(layers[9])) layerButton10.Modulate = layerButton10.Modulate.Darkened(0.5f);
    }

    #endregion

    #region Layers

    public int currentLayerIndex = 0;

    public List<bool[,]> layers = new()
    {
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount]
    };

    public bool[,] GetCurrentLayer() => layers[currentLayerIndex];
    public bool[,] SetCurrentLayer(bool[,] value) => layers[currentLayerIndex] = value;
    public void NextLayer()
    {
        if (currentLayerIndex == 9) SwitchLayer(1);
        else SwitchLayer(currentLayerIndex + 2);
    }
    public void PreviousLayer()
    {
        if (currentLayerIndex == 0) SwitchLayer(10);
        else SwitchLayer(currentLayerIndex);
    }

    public void SwitchLayer(int layerToUse)
    {
        RememberAllPivotRotationsForCurrentLayer();
        SetCurrentLayer(beatActives);
        currentLayerIndex = layerToUse - 1;
        beatActives = GetCurrentLayer();
        layerOutlineHolder.Position = (layerButton1.Position + layerButton1.Size / 2 + new Vector2(1, 0)) + new Vector2(1, 0) * (71f * currentLayerIndex);
        EmitSignal(SignalName.OnSwitchLayer, currentLayerIndex);
        layerVoiceOver0.SetSmallVolumeline();
        layerVoiceOver1.SetSmallVolumeline();
        layerVoiceOver0.SetBigVolumeline();
        layerVoiceOver1.SetBigVolumeline();
        ReApplyAllPivotRotationsForCurrentLayer();
    }

    public void UpdateSongVoiceOverPlayBackPosition()
    {
        if (SongVoiceOver.instance.voiceOver == null) return;
        if (SongVoiceOver.instance.audioPlayer.Playing == false) SongVoiceOver.instance.audioPlayer.Play();
        var timeperlayer = SongVoiceOver.instance.recordingLength / 10;
        var fixedcurrentbeat = BpmManager.instance.currentBeat;
        if (fixedcurrentbeat >= BpmManager.beatsAmount - 1) fixedcurrentbeat = 0;
        var timeperbeat = timeperlayer / BpmManager.beatsAmount;
        var beattimeoffset = timeperbeat * fixedcurrentbeat;
        var seekpos = currentLayerIndex * timeperlayer + beattimeoffset;
        SongVoiceOver.instance.audioPlayer.Seek(seekpos);
        GD.Print("seek song position to new position");
    }

    public bool LayerHasBeats(bool[,] layer)
    {
        for (int ring = 0; ring < 4; ring++)
        {
            for (int beat = 0; beat < BpmManager.beatsAmount; beat++)
            {
                bool active = layer[ring, beat];
                if (active) return true;
            }
        }
        return false;
    }

    #endregion

    #region AudioBankJson

    SoundBank chosenSoundBank = null;
    List<string> chosenEmoticons = null;

    private void ReadJsonFromPreviousSceneAndSetValues()
    {
        // deserialize chosen soundbank
        string chosen_soundbank_path = Path.Combine(ProjectSettings.GlobalizePath("user://"), "chosen_soundbank.json");
        string chosen_soundbank_json = File.ReadAllText(chosen_soundbank_path);
        chosenSoundBank = JsonSerializer.Deserialize<SoundBank>(chosen_soundbank_json);

        // deserialize chosen emoticons
        string chosen_emoticons_path = Path.Combine(ProjectSettings.GlobalizePath("user://"), "chosen_emoticons.json");
        string chosen_emoticons_json = File.ReadAllText(chosen_emoticons_path);
        chosenEmoticons = JsonSerializer.Deserialize<List<string>>(chosen_emoticons_json);
        foreach (var emoticon in chosenEmoticons) chosen_emoticons_label.Text += emoticon;

        // grab audio files -> res://Resources/Audio/SoundBanks/
        string soundbankname = chosenSoundBank.name;
        string baseDirPath = "res://Resources/Audio/SoundBanks/"; // should be a subfolder of "res://Resources/Audio/SoundBanks/" with the soundbankname in its name.
        DirAccess baseDir = DirAccess.Open(baseDirPath);
        baseDir.ListDirBegin();
        string folderName;
        while ((folderName = baseDir.GetNext()) != "")
        {
            if (baseDir.CurrentIsDir() && folderName.ToLower().Contains(soundbankname.ToLower()))
            {
                // main audio files
                {
                    string major_dir = baseDirPath + folderName + "/";
                    string[] major_files = ResourceLoader.ListDirectory(major_dir);
                    string file;
                    for (int i = 0; i < major_files.Length; ++i)
                    {
                        file = major_files[i];
                        if (file.EndsWith(".wav"))
                        {
                            string lower = file.ToLower();
                            string fullPath = major_dir + file;
                            if (lower.Contains("kick")) mainAudioFiles[0] = ResourceLoader.Load<AudioStream>(fullPath);
                            else if (lower.Contains("clap")) mainAudioFiles[1] = ResourceLoader.Load<AudioStream>(fullPath);
                            else if (lower.Contains("snare")) mainAudioFiles[2] = ResourceLoader.Load<AudioStream>(fullPath);
                            else if (lower.Contains("closed")) mainAudioFiles[3] = ResourceLoader.Load<AudioStream>(fullPath);
                        }
                    }
                }

                // alt audio files
                {
                    string minor_dir = baseDirPath + folderName + "/mineur/";
                    string[] major_files = ResourceLoader.ListDirectory(minor_dir);
                    string file;
                    for (int i = 0; i < major_files.Length; ++i)
                    {
                        file = major_files[i];
                        if (file.EndsWith(".wav"))
                        {
                            string lower = file.ToLower();
                            string fullPath = minor_dir + file;
                            if (lower.Contains("kick")) mainAudioFilesAlt[0] = ResourceLoader.Load<AudioStream>(fullPath);
                            else if (lower.Contains("clap")) mainAudioFilesAlt[1] = ResourceLoader.Load<AudioStream>(fullPath);
                            else if (lower.Contains("snare")) mainAudioFilesAlt[2] = ResourceLoader.Load<AudioStream>(fullPath);
                            else if (lower.Contains("closed")) mainAudioFilesAlt[3] = ResourceLoader.Load<AudioStream>(fullPath);
                        }
                    }
                }

                break;
            }
        }
        baseDir.ListDirEnd();

        // set swing
        float chosenswing = chosenSoundBank.swing / 100f * 0.4f;
        BpmManager.instance.swing = chosenswing;
        startswing = chosenswing;
        swingslider.Value = chosenswing;

        // set bpm offset
        if (!useTutorial)
        {
            int offset = 0;
            string path = "res://Resources/SoundBankMatrix/bpmoffset.json";
            string offsetjson = Godot.FileAccess.Open(path, Godot.FileAccess.ModeFlags.Read).GetAsText();
            Dictionary<string, string> offsetLookup = JsonSerializer.Deserialize<Dictionary<string, string>>(offsetjson);
            foreach (string theme in chosenSoundBank.themes)
            {
                offset += int.Parse(offsetLookup[theme]);
                GD.Print("add: " + offsetLookup[theme] + " / total: " + offset);
            }
            BpmManager.instance.bpm = chosenSoundBank.bpm + offset;
        }
        else
        {
            BpmManager.instance.bpm = chosenSoundBank.bpm;
        }

        // delete tmep json files
        File.Delete(chosen_emoticons_path);
        File.Delete(chosen_soundbank_path);
    }

    #endregion

    #region Email
    [Export] public Panel emailPrompt;
    [Export] public TextEdit emailInput;
    [Export] public Button emailEnter;
    public bool emailPromptOpen = false;
    public void OpenEmailPrompt()
    {
        // show email prompt
        emailPrompt.Position = new Vector2(-128, emailPrompt.Position.Y);
        emailPromptOpen = true;
    }
    public void CloseEmailPrompt()
    {
        // set aside email prompt
        emailPrompt.Position = new Vector2(-2000, emailPrompt.Position.Y);
        emailPromptOpen = false;
    }
    #endregion

    #region AudioSaving

    public void AllLayersToMp3()
    {
        SetCurrentLayer(beatActives);
        SaveSongAsFile(layers);
        CloseEmailPrompt();
    }

    private void ConvertWavToMp3(string filename)
    {
        var reader = new AudioFileReader(filename + ".wav");
        var writer = new LameMP3FileWriter(filename + ".mp3", reader.WaveFormat, LAMEPreset.STANDARD);
        reader.CopyTo(writer);
        reader.Close();
        writer.Close();
        File.Delete(filename + ".wav");
    }

    public static AudioStreamWav ChangeSampleRate(AudioStreamWav audioStream, int newSampleRate)
    {
        // get original audio data
        var originalData = audioStream.Data;
        var originalSampleRate = audioStream.MixRate;
        var stereo = audioStream.Stereo;
        var originalFormat = audioStream.Format;

        // no resampling or conversion needed
        if (originalSampleRate == newSampleRate && !stereo) return audioStream; 

        // convert data to float for processing
        var sampleCount = originalData.Length / sizeof(float);
        var originalSamples = new float[sampleCount];
        Buffer.BlockCopy(originalData, 0, originalSamples, 0, originalData.Length);

        // if stereo convert to mono
        float[] monoSamples;
        if (stereo)
        {
            monoSamples = new float[sampleCount / 2];
            for (int i = 0; i < monoSamples.Length; i++) monoSamples[i] = (originalSamples[i * 2] + originalSamples[i * 2 + 1]) / 2.0f;
        }
        else monoSamples = originalSamples;

        // calc ratio
        float ratio = (float)newSampleRate / originalSampleRate;

        // create buffer
        int newSampleCount = (int)(monoSamples.Length * ratio);
        var resampledSamples = new float[newSampleCount];

        // linear interpolation to resample
        for (int i = 0; i < newSampleCount; i++)
        {
            float originalPosition = i / ratio;
            int originalIndex = (int)Math.Floor(originalPosition);
            float frac = originalPosition - originalIndex;

            if (originalIndex < monoSamples.Length - 1) resampledSamples[i] = monoSamples[originalIndex] * (1 - frac) + monoSamples[originalIndex + 1] * frac;
            else resampledSamples[i] = monoSamples[originalIndex];
        }

        // resampled data back to byte array
        var newData = new byte[resampledSamples.Length * sizeof(float)];
        Buffer.BlockCopy(resampledSamples, 0, newData, 0, newData.Length);

        // create new audiostreamwav with updated sample rate
        var newAudioStream = new AudioStreamWav
        {
            Data = newData,
            MixRate = newSampleRate,
            Format = originalFormat,
            Stereo = false
        };

        return newAudioStream;
    }

    public void ConvertAudioStreamWavToWav(AudioStreamWav audioStreamWav, string filePath)
    {
        if (audioStreamWav.Stereo) audioStreamWav = ConvertStereoToMono(audioStreamWav);
        byte[] pcmData = audioStreamWav.Data;
        using (var waveFile = new WaveFileWriter(filePath, new WaveFormat(audioStreamWav.MixRate, 16, audioStreamWav.Stereo ? 2 : 1))) waveFile.Write(pcmData, 0, pcmData.Length);
        GD.Print($"WAV file successfully created at: {filePath}");
    }

    public AudioStreamWav ConvertStereoToMono(AudioStreamWav stereoStream)
    {
        AudioStreamWav monoStream = (AudioStreamWav)stereoStream.Duplicate();
        var audioData = stereoStream.Data;
        int bytesPerSample = stereoStream.Format == AudioStreamWav.FormatEnum.Format8Bits ? 1 : 2;
        byte[] monoData = new byte[audioData.Length / 2];

        for (int i = 0; i < audioData.Length; i += bytesPerSample * (stereoStream.Stereo ? 2 : 1))
        {
            // get left and right samples
            float leftSample = 0, rightSample = 0;
            if (stereoStream.Format == AudioStreamWav.FormatEnum.Format16Bits)
            {
                leftSample = BitConverter.ToInt16(audioData, i) / 32768f;
                rightSample = BitConverter.ToInt16(audioData, i + bytesPerSample) / 32768f;
            }
            else if (stereoStream.Format == AudioStreamWav.FormatEnum.Format8Bits)
            {
                leftSample = (audioData[i] - 128) / 128f;
                rightSample = (audioData[i + bytesPerSample] - 128) / 128f;
            }

            // write to averages mono sample
            float monoSample = (leftSample + rightSample) / 2.0f;
            if (stereoStream.Format == AudioStreamWav.FormatEnum.Format16Bits)
            {
                short monoShort = (short)(monoSample * 32768);
                byte[] monoBytes = BitConverter.GetBytes(monoShort);
                Array.Copy(monoBytes, 0, monoData, (i / 2), bytesPerSample);
            }
            else if (stereoStream.Format == AudioStreamWav.FormatEnum.Format8Bits)
            {
                byte monoByte = (byte)((monoSample * 128) + 128);
                monoData[i / 2] = monoByte;
            }
        }

        monoStream.Data = monoData;
        monoStream.Stereo = false;
        return monoStream;
    }

    public void MixAudioFiles(string file1, string file2, string outputFile)
    {
        using (var reader1 = new AudioFileReader(file1))
        {
            using (var reader2 = new AudioFileReader(file2))
            {
                // Use the format of the input files
                var outputFormat = reader1.WaveFormat;

                // Create a MixingSampleProvider for the two input files
                var mixer = new MixingSampleProvider([reader1.ToSampleProvider(), reader2.ToSampleProvider()]);

                // Write the mixed audio to the output file in chunks
                using (var writer = new WaveFileWriter(outputFile, outputFormat))
                {
                    const int bufferSize = 4096; // Process audio in chunks
                    float[] buffer = new float[bufferSize];

                    while (true)
                    {
                        // Read samples from the mixer
                        int samplesRead = mixer.Read(buffer, 0, bufferSize);

                        // Exit the loop if no more samples are available
                        if (samplesRead == 0) break;

                        // Write the samples to the output file
                        writer.WriteSamples(buffer, 0, samplesRead);
                    }

                    writer.Close();
                }
                reader2.Close();
            }
            reader1.Close();
        }
    }

    public void SaveBeatAsFile(bool[,] loop)
    {
        string sanitizedTime = Time.GetTimeStringFromSystem().Replace(":", "_");
        string filename = "beat_" + BpmManager.instance.bpm.ToString() + "bpm_" + sanitizedTime;

        int sampleRate = 48000;
        float secondsPerBeat = BpmManager.instance.baseTimePerBeat * 2;
        int beatsPerLoop = BpmManager.beatsAmount;
        int totalBeats = beatsPerLoop;
        int totalSamples = (int)(totalBeats * secondsPerBeat * sampleRate);
        float[] audioData = new float[totalSamples];
        bool[,] currentLoop = loop;

        // for each ring
        for (int ring = 0; ring < currentLoop.GetLength(0); ring++)
        {
            // for each beat
            for (int beat = 0; beat < currentLoop.GetLength(1); beat++)
            {
                // if beat active
                if (currentLoop[ring, beat])
                {
                    // get audio sample of beat
                    AudioStreamWav audioStreamWav = (AudioStreamWav)mainAudioFiles[ring];
                    var audioBytes = audioStreamWav.GetData();

                    // Convert byte[] to float[] (each pcm sample is a 16 bit integer also known as a short)
                    float[] samples = new float[audioBytes.Length / 2];
                    for (int i = 0; i < samples.Length; i++) samples[i] = BitConverter.ToInt16(audioBytes, i * 2) / 32768f;

                    // write audiodata at position
                    for (int i = 0; i < samples.Length; i++)
                    {
                        int position = (int)((beat) * secondsPerBeat * sampleRate) + i;
                        if (position < totalSamples) audioData[position] += samples[i];
                    }
                }
            }
        }

        // normalize
        float max = 0;
        foreach (var sample in audioData) if (Math.Abs(sample) > max) max = Math.Abs(sample);
        if (max > 1.0f) for (int i = 0; i < audioData.Length; i++) audioData[i] /= max;

        // write file
        using (var writer = new WaveFileWriter(filename + ".wav", new WaveFormat(sampleRate, 1)))
        {
            foreach (var sample in audioData) writer.WriteSample(sample);
            writer.Close();
        }

        ChangePitch(filename + ".wav", 2f);

        // convert and finish
        ConvertWavToMp3(filename);
        ShowSavingLabel(filename);
        hassavedtofile = true;
    }

    public void SaveSongAsFile(List<bool[,]> loops)
    {
        string sanitizedTime = Time.GetTimeStringFromSystem().Replace(":", "_");

        var user = (string name) => Path.Combine(ProjectSettings.GlobalizePath("user://"), name);

        string final_name = user("export_" + BpmManager.instance.bpm.ToString() + "bpm_" + sanitizedTime);
        string beats_name = user("beats");
        string song_name = user("song");
        string layers0_name = user("layers0");
        string layers1_name = user("layers1");
        string layers_combined_name = user("layers_combined");
        string beats_with_song_name = user("beats_with_song");

        int sampleRate = 48000;
        float secondsPerBeat = BpmManager.instance.baseTimePerBeat * 2;
        int beatsPerLoop = BpmManager.beatsAmount;
        int totalBeats = beatsPerLoop * loops.Count;
        int totalSamples = (int)(totalBeats * secondsPerBeat * sampleRate);
        float[] audioData = new float[totalSamples];

        // process each loop
        for (int loopIndex = 0; loopIndex < loops.Count; loopIndex++)
        {
            bool[,] currentLoop = loops[loopIndex];

            // for each ring
            for (int ring = 0; ring < currentLoop.GetLength(0); ring++)
            {
                // for each beat
                for (int beat = 0; beat < currentLoop.GetLength(1); beat++)
                {
                    // if beat active
                    if (currentLoop[ring, beat])
                    {
                        // get audio sample of beat
                        AudioStreamWav audioStreamWav = (AudioStreamWav)mainAudioFiles[ring];
                        var audioBytes = audioStreamWav.GetData();

                        // Convert byte[] to float[] (each pcm sample is a 16 bit integer also known as a short)
                        float[] samples = new float[audioBytes.Length / 2];
                        for (int i = 0; i < samples.Length; i++) samples[i] = BitConverter.ToInt16(audioBytes, i * 2) / 32768f;

                        // write audiodata at position
                        for (int i = 0; i < samples.Length; i++)
                        {
                            int position = (int)((loopIndex * beatsPerLoop + beat) * secondsPerBeat * sampleRate) + i;
                            if (position < totalSamples) audioData[position] += samples[i];
                        }
                    }
                }
            }
        }

        // normalize
        float max = 0;
        foreach (var sample in audioData) if (Math.Abs(sample) > max) max = Math.Abs(sample);
        if (max > 1.0f) for (int i = 0; i < audioData.Length; i++) audioData[i] /= max;

        // write file
        using (var writer = new WaveFileWriter(beats_name + ".wav", new WaveFormat(sampleRate, 1)))
        {
            foreach (var sample in audioData) writer.WriteSample(sample);
            writer.Close();
        }

        ChangePitch(beats_name + ".wav", 2f);

        // export layersvoiceovers0 as single wav
        AudioStream[] voiceovers0 = layerVoiceOver0.voiceOvers;
        for (int i = 0; i < 10; i++)
        {
            string name = user("layer" + i.ToString() + "a.wav");
            AudioStreamWav audioStreamWav = (AudioStreamWav)voiceovers0[i];
            if (audioStreamWav != null)
            {
                // voice wav
                ConvertAudioStreamWavToWav(audioStreamWav, name);
            }
            else
            {
                // empty wav
                float timepb = BpmManager.instance.baseTimePerBeat * 2;
                float time = timepb * BpmManager.beatsAmount;
                int rate = 48000;
                int channels = 1;
                int bits = 16;
                int total = (int)(time * rate * channels);
                byte[] silence = new byte[total * (bits / 8)];
                var waveFormat = new WaveFormat(sampleRate, bits, channels);
                using (var writer = new WaveFileWriter(name, waveFormat))
                {
                    writer.Write(silence, 0, silence.Length);
                    writer.Close();
                }
            }
        }
        List<string> layer0_inputs =
        [
            user("layer0a.wav"),
            user("layer1a.wav"),
            user("layer2a.wav"),
            user("layer3a.wav"),
            user("layer4a.wav"),
            user("layer5a.wav"),
            user("layer6a.wav"),
            user("layer7a.wav"),
            user("layer8a.wav"),
            user("layer9a.wav")
        ];
        using (var firstReader = new WaveFileReader(layer0_inputs[0]))
        {
            var waveFormat = firstReader.WaveFormat;
            using (var writer = new WaveFileWriter(layers0_name + ".wav", waveFormat))
            {
                firstReader.CopyTo(writer);
                for (int i = 1; i < layer0_inputs.Count; i++) using (var reader = new WaveFileReader(layer0_inputs[i])) reader.CopyTo(writer);
            }
        }
        for (int i = 0; i < layer0_inputs.Count; i++) File.Delete(layer0_inputs[i]);

        // export layersvoiceovers1 as single wav
        AudioStream[] voiceovers1 = layerVoiceOver1.voiceOvers;
        for (int i = 0; i < 10; i++)
        {
            string name = user("layer" + i.ToString() + "b.wav");
            AudioStreamWav audioStreamWav = (AudioStreamWav)voiceovers1[i];
            if (audioStreamWav != null)
            {
                // voice wav
                ConvertAudioStreamWavToWav(audioStreamWav, name);
            }
            else
            {
                // empty wav
                float timepb = BpmManager.instance.baseTimePerBeat;
                float time = timepb * BpmManager.beatsAmount;
                int rate = 48000;
                int channels = 1;
                int bits = 16;
                int total = (int)(time * rate * channels);
                byte[] silence = new byte[total * (bits / 8)];
                var waveFormat = new WaveFormat(sampleRate, bits, channels);
                using (var writer = new WaveFileWriter(name, waveFormat))
                {
                    writer.Write(silence, 0, silence.Length);
                    writer.Close();
                }
            }
        }
        List<string> layer1_inputs =
        [
            user("layer0b.wav"),
            user("layer1b.wav"),
            user("layer2b.wav"),
            user("layer3b.wav"),
            user("layer4b.wav"),
            user("layer5b.wav"),
            user("layer6b.wav"),
            user("layer7b.wav"),
            user("layer8b.wav"),
            user("layer9b.wav")
        ];
        using (var firstReader = new WaveFileReader(layer1_inputs[0]))
        {
            var waveFormat = firstReader.WaveFormat;
            using (var writer = new WaveFileWriter(layers1_name + ".wav", waveFormat))
            {
                firstReader.CopyTo(writer);
                for (int i = 1; i < layer1_inputs.Count; i++) using (var reader = new WaveFileReader(layer1_inputs[i])) reader.CopyTo(writer);
            }
        }
        for (int i = 0; i < layer1_inputs.Count; i++) File.Delete(layer1_inputs[i]);

        // mixing
        var song = (AudioStreamWav)SongVoiceOver.instance.voiceOver;
        if (song != null)
        {
            ConvertAudioStreamWavToWav(song, song_name + ".wav");
            MixAudioFiles(beats_name + ".wav", song_name + ".wav", beats_with_song_name + ".wav");
        }
        else
        {
            File.Move(beats_name + ".wav", beats_with_song_name + ".wav");
        }
        MixAudioFiles(layers0_name + ".wav", layers1_name + ".wav", layers_combined_name + ".wav");
        MixAudioFiles(beats_with_song_name + ".wav", layers_combined_name + ".wav", final_name + ".wav");

        // delete temps
        File.Delete(beats_name + ".wav");
        File.Delete(layers0_name + ".wav");
        File.Delete(layers1_name + ".wav");
        File.Delete(layers_combined_name + ".wav");
        if (song != null) File.Delete(song_name + ".wav");
        File.Delete(beats_with_song_name + ".wav");

        ShowSavingLabel(final_name);
        hassavedtofile = true;
        
        if (OS.GetName() == "Windows") // convert to mp3 with naudio
        {
            // convert
            ConvertWavToMp3(final_name);

            // send to email
            if (emailInput.Text != "") SendToEmail(final_name + ".mp3", emailInput.Text);
        }
        if (OS.GetName() == "Android") // avoid naudio, send plain wav file
        {
            // send to email
            if (emailInput.Text != "") SendToEmail(final_name + ".wav", emailInput.Text);
        }
    }

    async void SendToEmail(string final_name, string to)
    {
        Action task = () => EmailSender.SendWav(ProjectSettings.GlobalizePath(final_name), to);
        await Task.Run(task);
    }

    public void ChangePitch(string filePath, float pitchFactor)
    {
        List<float> outputBuffer = new List<float>();
        WaveFormat waveFormat;

        // read and process
        using (var reader = new AudioFileReader(filePath))
        {
            waveFormat = reader.WaveFormat;
            var sampleRate = waveFormat.SampleRate;
            var channels = waveFormat.Channels;

            var buffer = new float[sampleRate * channels];
            int bytesRead;

            while ((bytesRead = reader.Read(buffer, 0, buffer.Length)) > 0)
            {
                int newSampleCount = (int)(bytesRead / pitchFactor);
                var resampled = new float[newSampleCount];

                for (int i = 0; i < newSampleCount; i++)
                {
                    float sourceIndex = i * pitchFactor;
                    int index = (int)sourceIndex;
                    float frac = sourceIndex - index;

                    if (index + 1 < bytesRead) resampled[i] = buffer[index] * (1 - frac) + buffer[index + 1] * frac;
                    else resampled[i] = buffer[index];
                }

                outputBuffer.AddRange(resampled);
            }
        }

        // overwrite
        using (var writer = new WaveFileWriter(filePath, waveFormat)) writer.WriteSamples(outputBuffer.ToArray(), 0, outputBuffer.Count);
    }

    #endregion

    #region Mixing

    LayerPivotRotations[] rememberedPivotRotationsPerLayer = new LayerPivotRotations[10];

    LayerPivotRotations clipboardPivotRotations = new LayerPivotRotations();

    struct LayerPivotRotations
    {
        public float[] rotations = [0f, 0f, 0f, 0f];

        public LayerPivotRotations(float[] rotations)
        {
            this.rotations = rotations;
        }
    }

    // call before layer change
    public void RememberAllPivotRotationsForCurrentLayer()
    {
        // gather pivots
        Node2D[] pivots = new Node2D[4];
        for (int i = 0; i < 4; i++) pivots[i] = GetPivotForRing(i);

        // gather current rotations
        float[] current_rotations = new float[4];
        for (int i = 0; i < 4; i++) current_rotations[i] = pivots[i].RotationDegrees;

        // save rotations for current layer
        rememberedPivotRotationsPerLayer[currentLayerIndex] = new LayerPivotRotations(current_rotations);
    }

    // call after layer change
    public void ReApplyAllPivotRotationsForCurrentLayer()
    {
        // gather pivots
        Node2D[] pivots = new Node2D[4];
        for (int i = 0; i < 4; i++) pivots[i] = GetPivotForRing(i);

        // gather remembered rotations
        float[] remembered_rotations = rememberedPivotRotationsPerLayer[currentLayerIndex].rotations;
        remembered_rotations ??= [0, 0, 0, 0];

        // set remembered pivot rotations
        for (int i = 0; i < 4; i++) SetPivotRotationAbsolute(remembered_rotations[i], pivots[i], i);
    }

    public void CopyPivotRotationsForCurrentLayerToClipboard()
    {
        // gather pivots
        Node2D[] pivots = new Node2D[4];
        for (int i = 0; i < 4; i++) pivots[i] = GetPivotForRing(i);

        // gather current rotations
        float[] current_rotations = new float[4];
        for (int i = 0; i < 4; i++) current_rotations[i] = pivots[i].RotationDegrees;

        // save rotations for current layer to clipboard
        clipboardPivotRotations = new LayerPivotRotations(current_rotations);
    }

    public void PastePivotRotationsForCurrentLayerFromClipboard()
    {
        // gather pivots
        Node2D[] pivots = new Node2D[4];
        for (int i = 0; i < 4; i++) pivots[i] = GetPivotForRing(i);

        // gather remembered rotations
        float[] copied_rotations = clipboardPivotRotations.rotations;
        copied_rotations ??= [0, 0, 0, 0];

        // set remembered pivot rotations
        for (int i = 0; i < 4; i++) SetPivotRotationAbsolute(copied_rotations[i], pivots[i], i);
    }

    public void ClearPivotRotationsForCurrentLayer()
    {
        // gather pivots
        Node2D[] pivots = new Node2D[4];
        for (int i = 0; i < 4; i++) pivots[i] = GetPivotForRing(i);

        // reset rotations
        for (int i = 0; i < 4; i++) SetPivotRotationAbsolute(0, pivots[i], i);
    }

    public void SetPivotRotationOffset(float rotation, Node2D pivot, int ring)
    {
        pivot.RotationDegrees += rotation;
        var volumes = UpdateMixerVolumes(ring);
        UpdateMixerIcons(pivot, volumes);
    }

    public void SetPivotRotationAbsolute(float rotation, Node2D pivot, int ring)
    {
        pivot.RotationDegrees = rotation;
        var volumes = UpdateMixerVolumes(ring);
        UpdateMixerIcons(pivot, volumes);
    }

    private static void UpdateMixerIcons(Node2D pivot, (float main, float alt, float rec) volumes)
    {
        var icon0 = pivot.GetChild(0) as Label;
        var icon1 = pivot.GetChild(1) as Label;
        var icon2 = pivot.GetChild(2) as Label;
        icon0.Modulate = new Color(1, 1, 1, volumes.main);
        icon1.Modulate = new Color(1, 1, 1, volumes.alt);
        icon2.Modulate = new Color(1, 1, 1, volumes.rec);
    }

    [Export] public Node2D sampleMixer0;
    [Export] public Node2D sampleMixer1;
    [Export] public Node2D sampleMixer2;
    [Export] public Node2D sampleMixer3;

    public bool[] isMixerLocked = [false, false, false, false];
    
    public bool IsAnyMixerLocked()
    {
        foreach (bool locked in isMixerLocked) if (locked) return true;
        return false;
    }

    public void SetAllMixerVolumesOnly(float volume)
    {
        firstAudioPlayer.VolumeDb = Mathf.LinearToDb(volume);
        firstAudioPlayerAlt.VolumeDb = Mathf.LinearToDb(volume);
        firstAudioPlayerRec.VolumeDb = Mathf.LinearToDb(volume);
        secondAudioPlayer.VolumeDb = Mathf.LinearToDb(volume);
        secondAudioPlayerAlt.VolumeDb = Mathf.LinearToDb(volume);
        secondAudioPlayerRec.VolumeDb = Mathf.LinearToDb(volume);
        thirdAudioPlayer.VolumeDb = Mathf.LinearToDb(volume);
        thirdAudioPlayerAlt.VolumeDb = Mathf.LinearToDb(volume);
        thirdAudioPlayerRec.VolumeDb = Mathf.LinearToDb(volume);
        fourthAudioPlayer.VolumeDb = Mathf.LinearToDb(volume);
        fourthAudioPlayerAlt.VolumeDb = Mathf.LinearToDb(volume);
        fourthAudioPlayerRec.VolumeDb = Mathf.LinearToDb(volume);
    }

    private void UpdateAllMixerVolumes(bool log = false)
    {
        // temporarily lower mixer volumes during voice record
        bool anyrecord = layerVoiceOver0.recording || layerVoiceOver1.recording;
        bool anyfake = layerVoiceOver0.shouldUpdateProgressBar || layerVoiceOver1.shouldUpdateProgressBar;
        if (anyrecord || anyfake)
        {
            SetAllMixerVolumesOnly(0.1f);
            return;
        }

        var v0 = UpdateMixerVolumes(0);
        var v1 = UpdateMixerVolumes(1);
        var v2 = UpdateMixerVolumes(2);
        var v3 = UpdateMixerVolumes(3);

        if (log)
        {
            GD.Print("");
            GD.Print("---------- changing mix volumes ---------");
            GD.Print("0: " + v0.main.ToString("0.0") + "/" + v0.alt.ToString("0.0") + "/" + v0.rec.ToString("0.0"));
            GD.Print("1: " + v1.main.ToString("0.0") + "/" + v1.alt.ToString("0.0") + "/" + v1.rec.ToString("0.0"));
            GD.Print("2: " + v2.main.ToString("0.0") + "/" + v2.alt.ToString("0.0") + "/" + v2.rec.ToString("0.0"));
            GD.Print("3: " + v3.main.ToString("0.0") + "/" + v3.alt.ToString("0.0") + "/" + v3.rec.ToString("0.0"));
            GD.Print("-----------------------------------------");
            GD.Print("");
        }
    }

    private (float main, float alt, float rec) UpdateMixerVolumes(int ring)
    {
        float fullrotation = Mathf.PosMod(GetPivotForRing(ring).RotationDegrees, 360f) / 360f;

        float GetCrossfadeVolume(float sectionCenter)
        {
            float distance = Mathf.Abs(fullrotation - sectionCenter);
            if (distance > 0.5f) distance = 1f - distance;
            float maxDistance = 1f / 3f;
            return distance <= maxDistance ? 1f - (distance / maxDistance) : 0f;
        }

        float mainvolume = GetCrossfadeVolume(0f);      // peak at 0°
        float altvolume = GetCrossfadeVolume(1f / 3f);  // peak at 120°
        float recvolume = GetCrossfadeVolume(2f / 3f);  // peak at 240°

        if (ring == 0)
        {
            firstAudioPlayer.VolumeDb = Mathf.LinearToDb(mainvolume);
            firstAudioPlayerAlt.VolumeDb = Mathf.LinearToDb(altvolume);
            firstAudioPlayerRec.VolumeDb = Mathf.LinearToDb(recvolume);
        }
        else if (ring == 1)
        {
            secondAudioPlayer.VolumeDb = Mathf.LinearToDb(mainvolume);
            secondAudioPlayerAlt.VolumeDb = Mathf.LinearToDb(altvolume);
            secondAudioPlayerRec.VolumeDb = Mathf.LinearToDb(recvolume);
        }
        else if (ring == 2)
        {
            thirdAudioPlayer.VolumeDb = Mathf.LinearToDb(mainvolume);
            thirdAudioPlayerAlt.VolumeDb = Mathf.LinearToDb(altvolume);
            thirdAudioPlayerRec.VolumeDb = Mathf.LinearToDb(recvolume);
        }
        else if (ring == 3)
        {
            fourthAudioPlayer.VolumeDb = Mathf.LinearToDb(mainvolume);
            fourthAudioPlayerAlt.VolumeDb = Mathf.LinearToDb(altvolume);
            fourthAudioPlayerRec.VolumeDb = Mathf.LinearToDb(recvolume);
        }

        return (mainvolume, altvolume, recvolume);
    }

    private void SetupAllMixers()
    {
        SetupMixer(sampleMixer0, 0);
        SetupMixer(sampleMixer1, 1);
        SetupMixer(sampleMixer2, 2);
        SetupMixer(sampleMixer3, 3);
    }

    private Node2D GetMixerForRing(int ring)
    {
        if (ring == 0) return sampleMixer0;
        else if (ring == 1) return sampleMixer1;
        else if (ring == 2) return sampleMixer2;
        else if (ring == 3) return sampleMixer3;
        else return null;
    }

    private Node2D GetPivotForRing(int ring)
    {
        var mixer = GetMixerForRing(ring);
        return (Node2D)mixer.FindChild("Pivot");
    }

    void SetupMixer(Node2D mixer, int ring)
    {
        var increase = mixer.FindChild("IncreaseButton") as Button;
        var decrease = mixer.FindChild("DecreaseButton") as Button;
        var pivot = mixer.FindChild("Pivot") as Node2D;

        var timerInc = new Timer
        {
            WaitTime = 0.05,
            OneShot = false,
            Autostart = false
        };
        AddChild(timerInc);

        var timerDec = new Timer
        {
            WaitTime = 0.05,
            OneShot = false,
            Autostart = false
        };
        AddChild(timerDec);

        timerInc.Timeout += () => SetPivotRotationOffset(5, pivot, ring);
        timerDec.Timeout += () => SetPivotRotationOffset(-5, pivot, ring);

        increase.ButtonDown += () => timerInc.Start();
        increase.ButtonUp += () => timerInc.Stop();

        decrease.ButtonDown += () => timerDec.Start();
        decrease.ButtonUp += () => timerDec.Stop();
        
        SetPivotRotationOffset(0, pivot, ring);
    }
    #endregion

    #region Tutorial

    int tutorial_level = 0;
    bool tutorialActivated = false;

    string[] instructions = null;
    Func<bool>[] conditions = null;
    Action[] outcomes = null;

    void TryActivateTutorial()
    {
        if (useTutorial) // enable tutorial
        {
            SetEntireInterfaceVisibility(false);
            achievementspanel.Visible = true;
        }
        else // disable tutorial
        {
            tutorial_level = -1;
            SetEntireInterfaceVisibility(true);
            achievementspanel.Visible = false;
            if (DisplayServer.TtsIsSpeaking()) DisplayServer.TtsStop();
        }
    }

    // flag if tutorial mode should be enabled
    public bool useTutorial = ReadUseTutorial();
    private static bool ReadUseTutorial()
    {
        bool use;
        try
        {
            string path = Path.Combine(ProjectSettings.GlobalizePath("user://"), "use_tutorial.txt");
            string content = File.ReadAllText(path);
            use = bool.Parse(content);
            if (File.Exists(path)) File.Delete(path);
        }
        catch
        {
            use = true;
        }

        GD.Print("use tutorial: " + use.ToString());
        
        return use;
    }
    private void SetupTutorial()
    {
        var actives = (int ring) =>
        {
            int amount = 0;
            for (int beat = 0; beat < BpmManager.beatsAmount; beat++) if (instance.beatActives[ring, beat]) amount++;
            return amount;
        };

        // setup achievements
        instructions =
        [
            // intro
			"Hoi ik ben Klappy!, we gaan een beat maken en ik ga je daarbij helpen. klap 👏 in je handen om verder te gaan",
			
			// rode ring
			"Dit is een 🔴 beat ring, plaats nu 4 beats op de witte streepjes",
            "Helemaal goed! zet nog 2 🔴 beats op een plek die jij wil",
            "Druk nu op '⏯ Start' om je beat te horen",
            "Als je stompt 👞 met je voet op de grond precies wanneer er een rode beat is krijg ik energie ⚡",

			// oranje ring
			"Dit is nog een 🟠 beat ring, plaats nu 4 beats in het midden van de rode beats",
            "Druk nu op '⏯ Start' om je beat te horen",
            "Als je klapt 👏 met je handen wanneer er een oranje 🟠 beat klinkt krijgen ik energie ⚡",

			// gele ring
			"Dit is nog een 🟡 beat ring, plaats nu 2 harde beats waar je wilt op deze ring",

			// blauwe ring
			"Dit is nog een 🔵 beat ring, plaats nu 2 beats waar je wilt op deze ring",

			// alle ringen
			"Druk nog een keer op '⏯ Start', luister naar alle beats bij elkaar!",
			
			// progressiebar
			"Klap 👏 en stamp 👞 op het goede moment! Geef me 50% energie ⚡ om naar de volgende stap te gaan!",
			
			// custom sample
			"Je hebt het ritme te pakken! Nu gaan we onze eigen geluid maken, druk op het het microfoon 🎤 icoontje, en spreek iets in je microfoon",
            "Draai nu de schijf van geluidjes naar de microfoon 🎤 icoontje om het opgenomen geluid te activeren",
            "Druk op '⏯ Start' om te horen hoe je eigen geluidje klinkt",

			// effects

            // layer voice over
            "door op de groene microfoon '🎙️' knop te drukken, kan je jou stem over de beat opnemen. hij begint met opnemen als die beat ovenaan is.",
            "Links boven in het scherm kan je '🔁 Liedje Modus' aanzetten zodat de Beats achter elkaar afgespeeld worden",
            "Druk op '⏯ Start' om te horen hoe je eigen beats achter elkaar klinken",
            "Druk '💾 Kopieer Beat' en dan daarna '♻️ Plak Beat' op een andere laag",

            // song voice over
            "Laten we nu het hele liedje opnemen door op de '🎙️ Liedje Opnemen' links bovenin het scherm te drukken. Dan begin hij met opnemen als hij bij de eerste beat op de eerst laag is",
            "Als je tevreden bent dan kan je ook echt je '🎼 Liedje naar mp3'",
            "Druk op de '🚫 Stop' knop om de tutorial te eindigen",
        ];

        conditions =
        [
            // intro
            () => clapped, // t key is debug only

            // rode ring
            () => actives(0) >= 4, // temp
            () => actives(0) >= 6, // temp
            () => BpmManager.instance.playing == true, // temp
            () => stompedAmount > 4, // temp

            // oranje ring
            () => actives(1) >= 4, // temp
            () => BpmManager.instance.playing == true, // temp
            () => clappedAmount > 4, // temp

            // gele ring
            () => actives(2) >= 2, // temp

            // blauwe ring
            () => actives(3) >= 2, // temp

            // alle ringen
            () => BpmManager.instance.playing == true, // temp

            // progressie bar
            () => progressBar.Value > 50,

            // custom sample
            () => recordSampleButton0.recordedAudio != null,
            () => true, // skip for now
            () => BpmManager.instance.playing == true, // temp

            // effects

            // layer voice over
            () => layerVoiceOver0.finished || layerVoiceOver1.finished,
            () => layerLoopToggle.ButtonPressed,
            () => BpmManager.instance.playing == true,
            () => savedToLaout == true && loadedtemplate == true,

            // song voice over
            () => SongVoiceOver.instance.finished,
            () => hassavedtofile == true,
            () => false
        ];

        outcomes =
        [
            () => { SetRingVisibility(0, true); cross.Visible = true; },
            null,
            () => PlayPauseButton.Visible = true,
            () => progressBar.Visible = true,
            () => SetRingVisibility(1, true),
            null,
            null,
            () => SetRingVisibility(2, true), // zet geel
            () => SetRingVisibility(3, true), // zet blauw
            null, // druk play
            null, // geef energie
            () => { SetRecordingButtonsVisibility(true); SetDragAndDropButtonsVisibility(true); SetSampleMixersVisibility(true); },
            null,
            null,
            () =>
            {
                ((Sprite2D)layerVoiceOver0.recordLayerButton.GetParent()).Visible = true;
                layerVoiceOver0.textureProgressBar.Visible = true;
            },

            // layer voice over
            () => { SetLayerSwitchButtonsVisibility(true); layerLoopToggle.Visible = true;}, // before doing liedje modus
            () => SetMainButtonsVisibility(true), // before pressing play
            null, // before saving to layout
            () =>
            {
                SongVoiceOver.instance.recordSongButton.Visible = true;
                SongVoiceOver.instance.recordSongSprite.Visible = true;
                SongVoiceOver.instance.progressbar.Visible = true;
            },

            // song voice over
            () => { settingsButton.Visible = true; settingsPanel.Visible = true; }, // before saving to file
            () => SetEntireInterfaceVisibility(true), // enable all
            null
        ];
    }

    private void UpdateTutorial()
    {
        void SpeakTutorialInstruction(int instruction)
        {
            if (muteSpeach.ButtonPressed) return;

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

            var voices = DisplayServer.TtsGetVoicesForLanguage("nl");
            if (voices.Length == 0) voices = DisplayServer.TtsGetVoicesForLanguage("en");
            if (DisplayServer.TtsIsSpeaking()) DisplayServer.TtsStop();
            DisplayServer.TtsSpeak(without_emoticons(instructions[instruction]), voices[0], 100);
        }

        if (!first_tts_done && useTutorial)
        {
            SpeakTutorialInstruction(0);
            first_tts_done = true;
        }

        if (tutorial_level != -1 && useTutorial)
        {
            string instruction = instructions[tutorial_level];
            Func<bool> condition = conditions[tutorial_level];
            Action outcome = outcomes[tutorial_level];
            InstructionLabel.Text = instruction;

            f7_pressed_lastframe = f7_pressed;
            f7_pressed = Input.IsKeyPressed(Key.F7);
            bool skip = f7_pressed && f7_pressed != f7_pressed_lastframe;

            if (condition() || skip)
            {
                if (outcome != null) outcome();
                tutorial_level++;
                EmitAchievementParticles();
                PlayExtraSFX(achievement_sfx);
                SpeakTutorialInstruction(tutorial_level);
            }
        }
    }

    #endregion

    #region ClapStompBeat

    bool stomped = false;
    bool clapped = false;
    int clappedAmount = 0;
    int stompedAmount = 0;

    private void CheckIfClappingOrStomping()
    {
        // check clap and stomp
        var volume = MicrophoneCapture.instance.volume;
        var frequency = MicrophoneCapture.instance.frequency;

        var treshold = volume_treshold.Value;
        var shouldclap = volume > treshold && frequency > ClapBiasSlider.Value;
        if (shouldclap || Input.IsKeyPressed(Key.N))
        {
            if (!clapped)
            {
                if (!emailPromptOpen) OnClap();
                clapped = true;
            }
        }

        bool shouldstomp = volume > treshold && frequency < ClapBiasSlider.Value;
        if (shouldstomp || Input.IsKeyPressed(Key.M))
        {
            if (!stomped)
            {
                if (!emailPromptOpen) OnStomp();
                stomped = true;
            }
        }
    }

    public void OnClap()
    {
        if (timeafterplay < 0.2f) return;
        int ring = 1;
        bool active = beatActives[ring, BpmManager.instance.currentBeat];
        var sprite = beatSprites[ring, BpmManager.instance.currentBeat];
        if (active)
        {
            sprite.Scale += Vector2.One;
            progressBarValue += 1f / BpmManager.beatsAmount * 100f;
            EmitProgressBarParticles();
            EmitBeatParticles(beatSprites[ring, BpmManager.instance.currentBeat].Position, colors[ring]);
        }
        clappedAmount++;
        draganddropButton1.Scale += Vector2.One / 2;

        if (add_beats.ButtonPressed) ((DragAndDropButton)draganddropButton1).ActivateBeat();
    }

    public void OnStomp()
    {
        if (timeafterplay < 0.2f) return;
        int ring = 0;
        bool active = beatActives[ring, BpmManager.instance.currentBeat];
        var sprite = beatSprites[ring, BpmManager.instance.currentBeat];
        if (active)
        {
            sprite.Scale += Vector2.One;
            progressBarValue += 1f / BpmManager.beatsAmount * 100f;
            EmitProgressBarParticles();
            EmitBeatParticles(beatSprites[ring, BpmManager.instance.currentBeat].Position, colors[ring]);
        }
        stompedAmount++;
        draganddropButton0.Scale += Vector2.One / 2;

        if (add_beats.ButtonPressed) ((DragAndDropButton)draganddropButton0).ActivateBeat();

    }

    public void OnBeat()
    {
        if (metronome_sfx_enabled)
        {
            int beatsPerQuarter = BpmManager.beatsAmount / 4;
            if (BpmManager.instance.currentBeat % beatsPerQuarter == 0) PlayExtraSFX(metronome_sfx);
        }

        if (beatActives[0, BpmManager.instance.currentBeat]) firstAudioPlayer.Play();
        if (beatActives[1, BpmManager.instance.currentBeat]) secondAudioPlayer.Play();
        if (beatActives[2, BpmManager.instance.currentBeat]) thirdAudioPlayer.Play();
        if (beatActives[3, BpmManager.instance.currentBeat]) fourthAudioPlayer.Play();

        if (beatActives[0, BpmManager.instance.currentBeat]) firstAudioPlayerAlt.Play();
        if (beatActives[1, BpmManager.instance.currentBeat]) secondAudioPlayerAlt.Play();
        if (beatActives[2, BpmManager.instance.currentBeat]) thirdAudioPlayerAlt.Play();
        if (beatActives[3, BpmManager.instance.currentBeat]) fourthAudioPlayerAlt.Play();

        if (beatActives[0, BpmManager.instance.currentBeat] && firstAudioPlayerRec.Stream != null) firstAudioPlayerRec.Play();
        if (beatActives[1, BpmManager.instance.currentBeat] && secondAudioPlayerRec.Stream != null) secondAudioPlayerRec.Play();
        if (beatActives[2, BpmManager.instance.currentBeat] && thirdAudioPlayerRec.Stream != null) thirdAudioPlayerRec.Play();
        if (beatActives[3, BpmManager.instance.currentBeat] && fourthAudioPlayerRec.Stream != null) fourthAudioPlayerRec.Play();

        clapped = false;
        stomped = false;

        if (BpmManager.instance.currentBeat == 1) if (progressBarValue > 10) progressBarValue -= 5;

        if (layerLoopToggle.ButtonPressed || SongVoiceOver.instance.recording) if (BpmManager.instance.currentBeat == BpmManager.beatsAmount - 1) NextLayer();

        if (BpmManager.instance.currentBeat == 0 && currentLayerIndex == 0)
        {
            layerVoiceOver0.OnTop();
            layerVoiceOver1.OnTop();
            SongVoiceOver.instance.OnTop();
        }

        int nextbeat = BpmManager.instance.currentBeat + 1;
        if (nextbeat == BpmManager.beatsAmount) nextbeat = 0;

        bool clap_active = beatActives[1, nextbeat];
        if (clap_active) EmitSignal(SignalName.OnShouldClapEvent);

        bool stomp_active = beatActives[0, nextbeat];
        if (stomp_active) EmitSignal(SignalName.OnShouldStompEvent);

        float strength = 0.5f;
        float scale = 1f + ((Random.Shared.NextSingle() - 0.5f) * strength);
        fourthAudioPlayer.PitchScale = scale;
        fourthAudioPlayerAlt.PitchScale = scale;
        fourthAudioPlayerRec.PitchScale = scale;
    }
    #endregion

    #region Visibility
    
    public void SetEntireInterfaceVisibility(bool visible)
    {
        SetRingVisibility(0, visible);
        SetRingVisibility(1, visible);
        SetRingVisibility(2, visible);
        SetRingVisibility(3, visible);
        SetSampleMixersVisibility(visible);
        progressBar.Visible = visible;
        PlayPauseButton.Visible = visible;
        SetMainButtonsVisibility(visible);
        SetRecordingButtonsVisibility(visible);
        SetDragAndDropButtonsVisibility(visible);
        SetLayerSwitchButtonsVisibility(visible);
        settingsButton.Visible = visible;
        layerLoopToggle.Visible = visible;
        muteSpeach.Visible = visible;
        cross.Visible = visible;
        bpmLabel.Visible = visible;
        metronome.Visible = visible;
        metronomebg.Visible = visible;
        chosen_emoticons_label.Visible = visible;
        achievementspanel.Visible = visible;
        SongVoiceOver.instance.recordSongButton.Visible = visible;
        SongVoiceOver.instance.recordSongSprite.Visible = visible;
        SongVoiceOver.instance.progressbar.Visible = visible;
        ((Sprite2D)layerVoiceOver0.recordLayerButton.GetParent()).Visible = visible;
        ((Sprite2D)layerVoiceOver1.recordLayerButton.GetParent()).Visible = visible;
        layerVoiceOver0.textureProgressBar.Visible = visible;
        layerVoiceOver1.textureProgressBar.Visible = visible;
    }

    void SetRingVisibility(int ring, bool visible)
    {
        for (int beat = 0; beat < BpmManager.beatsAmount; beat++) beatSprites[ring, beat].Visible = visible;
        for (int beat = 0; beat < BpmManager.beatsAmount; beat++) beatOutlines[ring, beat].Visible = visible;
        for (int beat = 0; beat < BpmManager.beatsAmount; beat++) templateSprites[ring, beat].Visible = visible;
    }

    void SetMainButtonsVisibility(bool visible)
    {
        SaveLayoutButton.Visible = visible;
        LoadLayoutButton.Visible = visible;
        ClearLayoutButton.Visible = visible;
    }

    void SetEffectButtonsVisibility(bool visible)
    {
        BpmUpButton.Visible = visible;
        BpmDownButton.Visible = visible;
        bpmLabel.Visible = visible;
        swingslider.Visible = visible;
        swinglabel.Visible = visible;
        metronome.Visible = visible;
        metronomebg.Visible = visible;
        ReverbDelayManager.instance.reverbSlider.Visible = visible;
        ReverbDelayManager.instance.delaySlider.Visible = visible;
    }

    void SetRecordingButtonsVisibility(bool visible)
    {
        recordSampleButton0.Visible = visible;
        recordSampleButton1.Visible = visible;
        recordSampleButton2.Visible = visible;
        recordSampleButton3.Visible = visible;
    }

    void SetDragAndDropButtonsVisibility(bool visible)
    {
        draganddropButton0.Visible = visible;
        draganddropButton1.Visible = visible;
        draganddropButton2.Visible = visible;
        draganddropButton3.Visible = visible;
    }

    public void SetLayerSwitchButtonsVisibility(bool visible)
    {
        layerButton1.Visible = visible;
        layerButton2.Visible = visible;
        layerButton3.Visible = visible;
        layerButton4.Visible = visible;
        layerButton5.Visible = visible;
        layerButton6.Visible = visible;
        layerButton7.Visible = visible;
        layerButton8.Visible = visible;
        layerButton9.Visible = visible;
        layerButton10.Visible = visible;
        layerOutline.Visible = visible;
    }

    public void SetLayerSwitchButtonsEnabled(bool enabled)
    {
        layerButton1.Disabled = !enabled;
        layerButton2.Disabled = !enabled;
        layerButton3.Disabled = !enabled;
        layerButton4.Disabled = !enabled;
        layerButton5.Disabled = !enabled;
        layerButton6.Disabled = !enabled;
        layerButton7.Disabled = !enabled;
        layerButton8.Disabled = !enabled;
        layerButton9.Disabled = !enabled;
        layerButton10.Disabled = !enabled;
    }

    public void SetSampleMixersVisibility(bool visible)
    {
        sampleMixer0.Visible = visible;
        sampleMixer1.Visible = visible;
        sampleMixer2.Visible = visible;
        sampleMixer3.Visible = visible;
    }

    private void UpdateAchievementsVisibility()
    {
        for (int i = 0; i < 6; i++)
        {
            float tresh = ((float)i + 1f) / 6f * 100f;
            if (progressBarValue > tresh - 10)
            {
                Unlockables[i].Visible = true;
                UnlockablesQuestion[i].Visible = false;
            }
            else
            {
                Unlockables[i].Visible = false;
                UnlockablesQuestion[i].Visible = true;
            }
        }
    }

    #endregion

    #region Other

    bool loadedtemplate = false;
    bool hassavedtofile = false;
    bool metronome_sfx_enabled = false;
    bool up_pressed = false;
	bool up_pressed_lastframe = false;
    bool dn_pressed = false;
	bool dn_pressed_lastframe = false;
    bool lf_pressed = false;
	bool lf_pressed_lastframe = false;
    bool rt_pressed = false;
	bool rt_pressed_lastframe = false;
    bool f7_pressed = false;
	bool f7_pressed_lastframe = false;
    float time = 0;
    float slowBeatTimer = 0;
    bool first_tts_done = false;
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
    bool savedToLaout = false;
    private float startswing;

    AudioStream clipboardLayerVoice0;
    AudioStream clipboardLayerVoice1;

    public void CopyLayer()
    {
        CopyBeatLayoutToClipboard();
        CopyPivotRotationsForCurrentLayerToClipboard();
        CopyLayerVoiceToClipBoard();
    }

    public void PasteLayer()
    {
        PasteBeatLayoutFromClipboard();
        PastePivotRotationsForCurrentLayerFromClipboard();
        PasteLayerVoiceFromClipBoard();
    }

    public void ClearLayer()
    {
        ClearLayout();
        ClearPivotRotationsForCurrentLayer();
        ClearLayerVoiceOver();
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

        // pause layer voice over
        if (layerVoiceOver0.voiceOvers[layerVoiceOver0.currentLayer] != null)
        {
            if (layerVoiceOver0.audioPlayer.Playing) layerVoiceOver0.audioPlayer.StreamPaused = true;
            else layerVoiceOver0.audioPlayer.StreamPaused = false;
        }
        if (layerVoiceOver1.voiceOvers[layerVoiceOver1.currentLayer] != null)
        {
            if (layerVoiceOver1.audioPlayer.Playing) layerVoiceOver1.audioPlayer.StreamPaused = true;
            else layerVoiceOver1.audioPlayer.StreamPaused = false;
        }

        // pause song voice over
        if (SongVoiceOver.instance.voiceOver != null)
        {
            if (SongVoiceOver.instance.audioPlayer.Playing) SongVoiceOver.instance.audioPlayer.StreamPaused = true;
            else SongVoiceOver.instance.audioPlayer.StreamPaused = false;
        }
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
    
    #endregion
}