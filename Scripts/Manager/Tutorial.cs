using Godot;

using System;
using System.IO;
using System.Text.RegularExpressions;
using System.Globalization;
using Range = Godot.Range;

public static class Tutorial
{
    public static int tutorial_level = 0;
    public static bool tutorialActivated = false;

    private static int _beatsActiveRedRing = 5;
    private static int _beatsActiveOrangeRing = 4;
    private static int _indexRedRing = 0;
    private static int _indexOrangeRing = 1;
    private static int _ringTop = 0;
    private static int _ringBottom = 8;
    private static int _ringRight = 4;
    private static int _ringLeft = 12;
    private static int _greenLayerMicIndex = 0;
    private static Vector2 _knobPos;
    private static int _amountRedRing;
    private static bool _continued = false;
    private static string instruction = "";
    private static Func<bool> condition = null;
    private static Action outcome = null;
    private static bool _active = false;
    private static Area2D _pianoArea = null;
    private static Area2D _inBetweenArea = null;
    private static MeshInstance2D _pianoMesh = null;
    private static Node2D _top = null;
    private static int _fixedAmount = 5;
    private static int _previousclap = -1;
    private static int _previousstomp = -1;
    private static bool _stomping = false;
    private static bool _clapping = false;
    private static Timer timer;
    private static bool allowed = false;
    private static bool _textAllowed = true;
    private static DragAndDropButton _clapButton;
    private static DragAndDropButton _stompButton;
    static Manager manager => Manager.instance;

    private static (string instruction, Func<bool> condition, Action outcome)[] tutorialSteps =>
    [
        // intro
        (
            instruction: "Hoi! Mijn naam is Klappy en wij gaan samen een beat maken! Om te beginnen klap 👏in je handen",
            condition: () => manager.clapped,
            outcome: () =>
            {
                manager.SetRingVisibility(_indexRedRing, true);
                manager.cross.Visible = true;
                manager.KlappyContinue.Visible = false;
                manager.settingsButton.Visible = true;
                manager.ContinueButton.EmitSignal("animation_play");
            }
        ),

        // kick ring
        (
            instruction: "Deze rode cirkels vormen een beat ring",
            condition: () => !DisplayServer.TtsIsSpeaking(),
            outcome: null
        ),
        (
            instruction: "Met deze ring kun je een kick plaatsen op jouw beat. Kijk maar!",
            condition: () => !DisplayServer.TtsIsSpeaking(),
            outcome: () =>
            {
                manager.beatActives[_indexRedRing, _ringTop] = true;
                manager.beatActives[_indexRedRing, _ringRight] = true;
                manager.beatActives[_indexRedRing, _ringBottom] = true;
                manager.PlayPauseButton.Visible = true;
                manager.SetStompVisibility(true);
            }
        ),
        (
            instruction: "Ik heb er net drie ingevuld, druk nu op '▶️ Start' om de beat te horen",
            condition: () => BpmManager.instance.playing,
            outcome: () => allowed = true
        ),
        (
            instruction: "Druk op ⏸️ om het op pauze te zetten ",
            condition: () => !BpmManager.instance.playing,
            outcome: () => SkipPlay()
        ),
        (
            instruction: "Nu jij, vul nog 2 cirkels door op de stippen te drukken",
            condition: () => ActiveBeatsPerRing(_indexRedRing) >= _beatsActiveRedRing,
            outcome: () =>
            {
                _textAllowed = true;
                allowed = true;
            }
        ),
        (
            instruction: "Goed gedaan, nou wil ik wel eens horen wat je gedaan hebt! ▶️",
            condition: () =>
            {
                _beatsActiveRedRing = ActiveBeatsPerRing(_indexRedRing);
                return BpmManager.instance.playing;
            },
            outcome: () =>
            {
                manager.AmountLeft.Text = $"Goed gestamped {manager.stompedOnBeatAmount} / 5";
                _stomping = true;
            }
        ),
        (
            instruction: "Stamp👞 eens 5 keer mee op jouw beat!",
            condition: () => manager.stompedOnBeatAmount >= _fixedAmount,
            outcome: () =>
            {
                _stomping = false;
                manager.AmountLeft.Visible = false;
                manager.AmountLeft.Text = "";
                BpmManager.instance.playing = false;
            }
        ),
        (
            instruction: "Wow super gedaan! tijd voor level 2!",
            condition: () => !DisplayServer.TtsIsSpeaking(),
            outcome: () => manager.SetRingVisibility(_indexOrangeRing, true)
        ),

        // klap ring
        (
            instruction: "Dit is de klap ring! Hiermee kun je een klap geluid toevoegen",
            condition: () => !DisplayServer.TtsIsSpeaking(),
            outcome: () =>
            {
                manager.beatActives[_indexOrangeRing, _ringRight] = true;
                manager.beatActives[_indexOrangeRing, _ringLeft] = true;
                manager.SetClapVisibility(true);
                SkipPlay();
            }
        ),
        (
            instruction: "Ik heb er zelf net 2 erin gezet, luister er maar eens naar▶️!",
            condition: () => BpmManager.instance.playing,
            outcome: () =>
            {
                _textAllowed = true;
                timer.Start(timer.WaitTime);
            }
        ),
        (
            instruction: "",
            condition: () => timer.TimeLeft == 0,
            outcome: null
        ),
        (
            instruction: "Klinkt al leuk!",
            condition: () => !DisplayServer.TtsIsSpeaking(),
            outcome: () =>
            {
                BpmManager.instance.playing = false;
            }
        ),
        (
            instruction: "Probeer nu eens zelf, vul nog 2 oranje stippen in te vullen door op de stippen te drukken",
            condition: () => ActiveBeatsPerRing(_indexOrangeRing) >= _beatsActiveOrangeRing,
            outcome: null
        ),
        (
            instruction: "Haal nu ook een gevulde stip weg door er nog een keer op te klikken",
            condition: () => ActiveBeatsPerRing(_indexRedRing) < _beatsActiveRedRing || ActiveBeatsPerRing(_indexOrangeRing) < _beatsActiveOrangeRing,
            outcome: () => SkipPlay()
        ),
        (
            instruction: "Ik ben benieuwd laat mij eens horen! ▶️",
            condition: () =>
            {
                _beatsActiveOrangeRing = ActiveBeatsPerRing(_indexOrangeRing);
                return BpmManager.instance.playing;
            },
            outcome: () =>
            {
                _textAllowed = true;
                manager.AmountLeft.Visible = true;
                manager.AmountLeft.Text = $"Goed geklapped {manager.clappedOnBeatAmount} / 5";
                _clapping = true;
            }
        ),
        (
            instruction: "Probeer 5 keer mee te klappen op de beat!",
            condition: () => manager.clappedOnBeatAmount >= _fixedAmount,
            outcome: () =>
            {
                _clapping = false;
                manager.AmountLeft.Visible = false;
                BpmManager.instance.playing = false;
            }
        ),
        (
            instruction: "Super goed gedaan, je hebt talent!",
            condition: () => !DisplayServer.TtsIsSpeaking(),
            outcome: () =>
            {
                manager.SetGreenLayerVisibility(true);
                Manager.instance.SynthMixing_ChangeSynth(_greenLayerMicIndex);
            }
        ),

        // groene laag
        (
            instruction: "Hier is de groene ring. Die vul je in door met je eigen microfoon iets op te nemen!",
            condition: () => !DisplayServer.TtsIsSpeaking(),
            outcome: () =>
            {
                manager.SetMicRecorderVisibility(true);
                manager.knob.GlobalPosition = _top.GlobalPosition;
                allowed = true;
            }
        ),
        (
            instruction: "Probeer het maar eens door op het microfoon 🎙️icoontje te klikken",
            condition: () => manager.layerVoiceOver0.finished,
            outcome: () => SkipPlay()
        ),
        (
            instruction: "Laat eens horen!▶️",
            condition: () => BpmManager.instance.playing,
            outcome: () => _textAllowed = true
        ),
        (
            instruction: "Super gedaan, het klinkt heel leuk",
            condition: () => !DisplayServer.TtsIsSpeaking(),
            outcome: () => BpmManager.instance.playing = false
        ),

        // chaos pad
        (
            instruction: "Laten wij dit geluid mixen!",
            condition: () =>
            {
                _knobPos = manager.knob.GlobalPosition;
                return !DisplayServer.TtsIsSpeaking();
            },
            outcome: () =>
            {
                _active = true;
                manager.chaosPadTriangleSprite.Visible = true;
            }
        ),
        (
            instruction: "Deze driehoek is de mixer! Hiermee kun je jouw net opgenomen geluid veranderen",
            condition: () => !DisplayServer.TtsIsSpeaking(),
            outcome: null
        ),
        (
            instruction: "Je kunt jouw stem 🎙️ veranderen in het geluid van een Instrument 🎹  of jouw stem met een effect 🤖",
            condition: () => false,
            outcome: () =>
            {
                _active = false;
                manager.PianoArea.Monitoring = true;
                manager.PianoMesh.Visible = true;
                manager.PianoArea.EmitSignal("animation_star_play");
            }
        ),
        (
            instruction: "probeer het maar eens door het grijze rondje te bewegen naar het 🌟 sterretje ",
            condition: () => false,
            outcome: () => SkipPlay()
        ),
        (
            instruction: "Luister maar eens!▶️",
            condition: () => BpmManager.instance.playing,
            outcome: () =>
            {
                _textAllowed = true;
                manager.PianoArea.SetDeferred("monitoring", false);
                manager.PianoMesh.Visible = false;
                manager.PianoArea.EmitSignal("animation_star_stop");
                _active = true;
            }
        ),
        (
            instruction: "Dit geeft een hele andere sfeer aan je beat",
            condition: () => false,
            outcome: () =>
            {
                _active = false;
                manager.InBetweenMesh.Visible = true;
                manager.InBetweenArea.SetDeferred("monitoring", true);
                manager.InBetweenArea.EmitSignal("animation_star_play");
            }
        ),
        (
            instruction: "Door het grijze rondje nu tussen twee icoontjes bij het 🌟 sterretje te plaatsen maak je een mix!",
            condition: () => false,
            outcome: () =>
            {
                _active = true;
                manager.InBetweenArea.SetDeferred("monitoring", false);
                manager.InBetweenArea.EmitSignal("animation_star_stop");
                manager.InBetweenMesh.Visible = false;
            }
        ),
        (
            instruction: "Zo krijg je een mix tussen jou stem en het instrument!",
            condition: () => false,
            outcome: () =>
            {
                _active = false;
                manager.OutSideArea.SetDeferred("monitoring", true);
                manager.OutSideArea.EmitSignal("animation_star_play");
                manager.OutSideMesh.Visible = true;
            }
        ),
        (
            instruction: "Laten we het geluid iets zachter maken door de grijze stip een beetje buiten de driehoek bij het 🌟 sterretje` te plaatsen",
            condition: () => false,
            outcome: () =>
            {
                manager.OutSideArea.SetDeferred("monitoring", false);
                manager.OutSideArea.EmitSignal("animation_star_stop");
                manager.OutSideMesh.Visible = false;
                _active = true;
            }
        ),

        // End of tutorial
        (
            instruction: "Het liedje is al goed op weg, je mag nu zelf volledig aan de slag! Veel plezier!",
            condition: () => false,
            outcome: () =>
            {
                tutorial_level = -2;
                manager.SetEntireInterfaceVisibility(true);
                manager.achievementspanel.Visible = false;
                manager.PlayExtraSFX(manager.achievement_sfx);
                manager.ContinueButton.Pressed -= _tutorialContinue;
                manager.PianoArea.AreaEntered -= _bodyContinue;
                manager.InBetweenArea.AreaEntered -= _bodyContinue;
                manager.KlappyContinue.Pressed -= KlappyContinue;
            }
        )
    ];

    // flag if tutorial mode should be enabled
    public static bool useTutorial;

    public static void Reset()
    {
        tutorial_level = 0;
        tutorialActivated = false;
        useTutorial = ReadUseTutorial();
        timer?.QueueFree();
        timer = null;
    }

    public static void CheckIfTutorialWasChosen()
    {
        useTutorial = ReadUseTutorial();
    }

    public static void TryActivateTutorial()
    {
        if (useTutorial) // enable tutorial
        {
            BpmManager.instance.bpm = 60;
            manager.SetEntireInterfaceVisibility(false);
            manager.achievementspanel.Visible = true;
            manager.ContinueButton.Pressed += _tutorialContinue;
            manager.PianoArea.AreaEntered += _bodyContinue;
            manager.InBetweenArea.AreaEntered += _bodyContinue;
            manager.KlappyContinue.Pressed += KlappyContinue;
            manager.OutSideArea.AreaEntered += _bodyContinue;
            manager.add_beats.SetPressed(true);
            _top = manager.corners[1];
            _clapButton = (DragAndDropButton)manager.draganddropButton1;
            _stompButton = (DragAndDropButton)manager.draganddropButton0;
            _clapButton.OnPressed += manager.OnClap;
            _stompButton.OnPressed += manager.OnStomp;
        }
    }

    private static void timerSetUp()
    {
        if (timer is null)
        {
            timer = new Timer();
            timer.WaitTime = 3;
            timer.OneShot = true;
            manager.achievementspanel.AddChild(timer);
        }
    }

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

    public static void SetupTutorial()
    {
        timerSetUp();
        // Tutorial steps are now defined as a property above
        // No need to initialize separate arrays here
    }

    private static int ActiveBeatsPerRing(int indexRing)
    {
        int amount = 0;
        for (int beat = 0; beat < BpmManager.beatsAmount; beat++)
            if (manager.beatActives[indexRing, beat])
                amount++;
        return amount;
    }

    private static void KlappyContinue()
    {
        manager.Klappy.Call("on_clap");
        _nextLine();
    }

    private static void ButtonState()
    {
        manager.ContinueButton.Visible = _active;
    }

    private static void _tutorialContinue()
    {
        if (!_active) return;
        _nextLine();
    }

    private static void _bodyContinue(Area2D body)
    {
        GD.Print("body continue" + body);
        if (body == manager.KnobArea)
        {
            _nextLine();
        }
    }

    private static void _nextLine()
    {
        outcome?.Invoke();
        if (tutorial_level >= tutorialSteps.Length) return;
        tutorial_level++;
        manager.PlayExtraSFX(manager.achievement_sfx);
        SpeakTutorialInstruction(tutorial_level);
        UpdateLists();
    }

    private static void _correctStompPlaySFX()
    {
        if (_stomping)
        {
            if (manager.stompedOnBeatAmount > _previousstomp)
            {
                manager.PlayExtraSFX(manager.achievement_sfx);
                _previousstomp = manager.stompedOnBeatAmount;
                manager.AmountLeft.Text = $"Goed gestamped {manager.stompedOnBeatAmount} / 5";
            }
        }
    }

    private static void _correctClapPlaySFX()
    {
        if (_clapping)
        {
            if (manager.clappedOnBeatAmount > _previousclap)
            {
                manager.PlayExtraSFX(manager.achievement_sfx);
                _previousclap = manager.clappedOnBeatAmount;
                manager.AmountLeft.Text = $"Goed geklapped {manager.clappedOnBeatAmount} / 5";
            }
        }
    }

    public static void UpdateTutorial()
    {
        ButtonState();

        if (!manager.first_tts_done && useTutorial)
        {
            SpeakTutorialInstruction(tutorial_level);
            manager.first_tts_done = true;
        }

        _correctClapPlaySFX();
        _correctStompPlaySFX();

        if (tutorial_level != -1 && useTutorial && tutorial_level < tutorialSteps.Length)
        {
            UpdateLists();

            manager.f7_pressed_lastframe = manager.f7_pressed;
            manager.f7_pressed = Input.IsKeyPressed(Key.F7);
            bool skip = manager.f7_pressed && manager.f7_pressed != manager.f7_pressed_lastframe;

            if (condition())
            {
                _nextLine();
            }
            if (skip)
            {
                _nextLine();
            }
        }
    }

    private static void SpeakTutorialInstruction(int instructionIndex)
    {
        if (!_textAllowed) return;
        if (manager.muteSpeach.ButtonPressed) return;

        if (instructionIndex < 0 || instructionIndex >= tutorialSteps.Length) return;

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
        DisplayServer.TtsSpeak(without_emoticons(tutorialSteps[instructionIndex].instruction), voices[0], 100);
    }

    private static bool SkipPlay()
    {
        if (BpmManager.instance.playing)
        {
            _textAllowed = false;
            return true;
        }
        else
        {
            return BpmManager.instance.playing;
        }
    }

    private static void UpdateLists()
    {
        if (tutorial_level >= 0 && tutorial_level < tutorialSteps.Length)
        {
            var currentStep = tutorialSteps[tutorial_level];
            instruction = currentStep.instruction;
            condition = currentStep.condition;
            outcome = currentStep.outcome;
            manager.InstructionLabel.Text = instruction;
        }
    }
}