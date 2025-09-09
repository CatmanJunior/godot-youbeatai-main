using Godot;

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
        SetupTutorial();
        OnReadyMixing();
    }

    public override void _Process(double delta)
    {
        time += (float)delta;

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

        PlayPauseButton.Text = BpmManager.instance.playing ? "⏸️" : "▶️";

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

        OnUpdateMixing((float)delta);
    }
}