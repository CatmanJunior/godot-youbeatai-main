using Godot;

using System;
using System.IO;
using System.Text.RegularExpressions;
using System.Globalization;
using System.Reflection;
using Range = Godot.Range;

public static class Tutorial
{
    public static int tutorial_level = 0;
    public static bool tutorialActivated = false;

    private static int _beatsActiveRedRing = 5;
    private static int _beatsActiveOrangeRing = 4;
    private static readonly int _indexRedRing = 0;
    private static readonly int _indexOrangeRing = 1;
    private static readonly int _ringTop = 0;
    private static readonly int _ringBottom = 8;
    private static readonly int _ringRight = 4;
    private static readonly int _ringLeft = 12;
    private static readonly int _greenLayerMicIndex = 0;
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
    private static readonly int _fixedAmount = 5;
    private static int _previousClap = -1;
    private static int _previousStomp = -1;
    private static bool _stomping = false;
    private static bool _clapping = false;
    private static Timer timer;
    private static bool allowed = false;
    private static bool _textAllowed = true;
    private static DragAndDropButton _clapButton;
    private static DragAndDropButton _stompButton;
    private static bool _increasedSpeed = false;
    static Manager manager => Manager.instance;

    private static (string instruction, Func<bool> condition, Action outcome)[] tutorialSteps =>
    [
        // intro
        (
            instruction: "Hoi! Mijn naam is Klappy en wij gaan samen een Beat maken! Klap 👏in je handen om te beginnen",
            condition: () => manager.clapped,
            outcome: () =>
            {
                manager.pointer.Visible = true;
                manager.SetRingVisibility(_indexRedRing, true);
                manager.cross.Visible = true;
                manager.KlappyContinue.Visible = false;
                manager.settingsButton.Visible = true;
                manager.ContinueButton.EmitSignal("animation_play");
                manager.PlayExtraSFX(manager.achievement_sfx);
            }
        ),

        // kick ring
        (
            instruction:     "Deze rode cirkels vormen een kick-ring",
            condition: () => !DisplayServer.TtsIsSpeaking(),
            outcome: null
        ),
        (
            instruction: "Op deze ring kun je de kick plaatsen van je Beat",
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
            instruction: "Kijk, ik heb er net drie ingevuld. Druk nu op '▶️ Start' om de Beat te horen",
            condition: () => BpmManager.instance.playing,
            outcome: () => allowed = true
        ),
        (
            instruction: "Druk op ⏸️ om de Beat op pauze te zetten",
            condition: () => !BpmManager.instance.playing,
            outcome: () =>
            {
                manager.PlayExtraSFX(manager.achievement_sfx);
                SkipPlay();
            }),
        (
            instruction: "Nu jij!, vul nog 2 cirkels door er op te drukken",
            condition: () => ActiveBeatsPerRing(_indexRedRing) >= _beatsActiveRedRing,
            outcome: () =>
            {
                _textAllowed = true;
                allowed = true;
                manager.PlayExtraSFX(manager.achievement_sfx);
            }
        ),
        (
            instruction: "Goed gedaan! Nou wil ik wel eens horen hoe jij de Beat veranderd hebt ▶️",
            condition: () =>
            {
                _beatsActiveRedRing = ActiveBeatsPerRing(_indexRedRing);
                return BpmManager.instance.playing;
                
            },
            outcome: () =>
            {
                timer.Start(2);
            }
        ),
        (
            instruction: "",
            condition: () => timer.IsStopped()
            ,
            outcome: () =>
            {
                manager.AmountLeft.Text = $"Goed gestamped {manager.stompedOnBeatAmount} / 5";
                _stomping = true;
                manager.PlayExtraSFX(manager.achievement_sfx);
            }
        ),
        
        (
            instruction: "Stamp 👟 5 keer mee met de kick van je Beat!",
            condition: () => manager.stompedOnBeatAmount >= _fixedAmount,
            outcome: () =>
            {
                _stomping = false;
                manager.AmountLeft.Visible = false;
                manager.AmountLeft.Text = "";
                BpmManager.instance.playing = false;
                manager.PlayExtraSFX(manager.achievement_sfx);
            }
        ),
        (
            instruction: "Wow super gedaan!",
            condition: () => !DisplayServer.TtsIsSpeaking(),
            outcome: () => {}
        ),
        (
            instruction: "Op naar level 2!",
            condition: () => !DisplayServer.TtsIsSpeaking(),
            outcome: () => manager.SetRingVisibility(_indexOrangeRing, true)
        ),

        // klap ring
        (
            instruction: "Deze oranje ring is de clap-ring",
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
            instruction: "Ik heb er net 2 ingevuld. Luister maar eens naar de clap ▶️!",
            condition: () => BpmManager.instance.playing,
            outcome: () =>
            {
                _textAllowed = true;
                timer.Start(timer.WaitTime);
                manager.PlayExtraSFX(manager.achievement_sfx);
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
            instruction: "Jouw beurt! Vul nóg 2 oranje cirkels in door er op te drukken",
            condition: () => ActiveBeatsPerRing(_indexOrangeRing) >= _beatsActiveOrangeRing,
            outcome: ()=>  manager.PlayExtraSFX(manager.achievement_sfx)
        ),
        (
            instruction: "Haal nu ook 1 van de ingevulde cirkels weg door er op te drukken",
            condition: () => ActiveBeatsPerRing(_indexRedRing) < _beatsActiveRedRing || ActiveBeatsPerRing(_indexOrangeRing) < _beatsActiveOrangeRing,
            outcome: () =>
            {
                manager.PlayExtraSFX(manager.achievement_sfx);
                SkipPlay();
            }),
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
                manager.PlayExtraSFX(manager.achievement_sfx);
                _clapping = true;
                timer.Start(2);
            }
        ),
        (
            instruction: "",
            condition: () => timer.TimeLeft == 0,
            outcome: null
        ),
        (
            instruction: "Klap nu 5 keer mee met de claps van je Beat! Let dus op de oranje cirkels",
            condition: () => manager.clappedOnBeatAmount >= _fixedAmount,
            outcome: () =>
            {
                _clapping = false;
                manager.AmountLeft.Visible = false;
                BpmManager.instance.playing = false;
                manager.PlayExtraSFX(manager.achievement_sfx);
            }
        ),
        (
            instruction: "Super goed gedaan, je hebt talent!",
            condition: () => !DisplayServer.TtsIsSpeaking(),
            outcome: () =>
            {
                manager.SetGreenLayerVisibility(true);
               
            }
        ),

        // groene laag
        (
            instruction: "Dit is de groene bass-ring. Klik op de beer 🐻 om de groene laag te kiezen en een brommende melodie toe te voegen",
            condition: () => manager.chaosPadMode == Manager.ChaosPadMode.SynthMixing, //todo check index of choas pad,
            outcome: () =>
            {
                manager.SetMicRecorderVisibility(true);
                manager.knob.GlobalPosition = _top.GlobalPosition;
                allowed = true;
                manager.PlayExtraSFX(manager.achievement_sfx);
            }
        ),
        (
            instruction: "Deze bass-ring kun je invullen door met je microfoon een sample op te nemen!",
            condition: () =>
            {
                if (manager.greenLayerRecordButton.ButtonPressed)
                {
                    manager.PlayExtraSFX(manager.achievement_sfx);
                    tutorial_level += 5;
                    
                    DisplayServer.TtsStop();
                    return true;
                }
                return !DisplayServer.TtsIsSpeaking();
            },
            outcome: () =>
            {
                
            }
        ),
        (
            instruction: "Druk op de microfoon 🎙️en neem een baslijn op! Ik tel af van 4 naar 0",
            condition: () =>
            {

                return manager.greenLayerRecordButton.ButtonPressed;
            },
            outcome: () =>
            {
                manager.PlayExtraSFX(manager.achievement_sfx);
                _increasedSpeed = true;
                DisplayServer.TtsStop();
                
            }),
        (
            instruction: "4",
            condition: () =>  !DisplayServer.TtsIsSpeaking(),
            outcome: () =>
            {
               
            }),
        (
            instruction: "3",
            condition: () =>  !DisplayServer.TtsIsSpeaking(),
            outcome: () =>
            {
                
            }),
        (
            instruction: "2",
            condition: () =>  !DisplayServer.TtsIsSpeaking(),
            outcome: () =>
            {
               
            }
            ),
        (
            instruction: "1",
            condition: () =>  !DisplayServer.TtsIsSpeaking(),
            outcome: () =>
            {
                
               
            }),
        (
            instruction: "",
            condition: () =>  manager.layerVoiceOver0.finished,
            outcome: () =>
            {
                _increasedSpeed = false;
                timer.Start(3);
               
            }),
      //  (
         //   instruction: "Laat eens horen!▶️",
        //    condition: () => BpmManager.instance.playing,
          //  outcome: () =>
          //  { 
         //       manager.PlayExtraSFX(manager.achievement_sfx);
        //       timer.Start(3);
        //    }),
        (
            instruction:"",
            condition: () => timer.IsStopped(),
            outcome: null
        ),
        (
            instruction: "Super gedaan, het klinkt heel leuk",
            condition: () => !DisplayServer.TtsIsSpeaking(),
            outcome: () => BpmManager.instance.playing = false
        ),

        // chaos pad
        (
            instruction: "Laten we je sample bewerken!",
            condition: () =>
            {
                _knobPos = manager.knob.GlobalPosition;
                return !DisplayServer.TtsIsSpeaking();
            },
            outcome: () =>
            {
                //_active = true;
                manager.chaosPadTriangleSprite.Visible = true;
            }
        ),
        (
            instruction: "Deze driehoek is de mixer! Hiermee kun je het geluid van jouw net opgenomen sample veranderen",
            condition: () => !DisplayServer.TtsIsSpeaking(),
            outcome: null
        ),
        (
            instruction: "Je kunt jouw sample 🎙️ bijvoorbeeld veranderen in het geluid van een instrument 🎹 óf een effect 🤖aan je sample geven",
            condition: () => !DisplayServer.TtsIsSpeaking(),
            outcome: () =>
            {
                
                manager.PianoArea.Monitoring = true;
                manager.PianoMesh.Visible = true;
                manager.PianoArea.EmitSignal("animation_star_play");
            }
        ),
        (
            instruction: "Beweeg het grijze rondje met de vingerafdruk naar het 🌟 sterretje ",
            condition: () => false,
            outcome: () =>
            {
                manager.PlayExtraSFX(manager.achievement_sfx);
                SkipPlay();
            }),
        (
            instruction: "Luister maar eens!▶️",
            condition: () => BpmManager.instance.playing,
            outcome: () =>
            {
                _textAllowed = true;
                manager.PianoArea.SetDeferred("monitoring", false);
                manager.PianoMesh.Visible = false;
                manager.PianoArea.EmitSignal("animation_star_stop");
                manager.PlayExtraSFX(manager.achievement_sfx);
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
            instruction: "Beweeg het grijze rondje weer naar het 🌟 sterretje",
            condition: () => false,
            outcome: () =>
            {
                _active = true;
                manager.InBetweenArea.SetDeferred("monitoring", false);
                manager.InBetweenArea.EmitSignal("animation_star_stop");
                manager.PlayExtraSFX(manager.achievement_sfx);
                manager.InBetweenMesh.Visible = false;
            }
        ),
        (
            instruction: "Zo krijg je een mix tussen jouw sample en het instrument!",
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
            instruction: "Beweeg het grijze rondje nog 1 keer naar het 🌟 sterretje",
            condition: () => false,
            outcome: () =>
            {
                manager.OutSideArea.SetDeferred("monitoring", false);
                manager.OutSideArea.EmitSignal("animation_star_stop");
                manager.OutSideMesh.Visible = false;
                manager.PlayExtraSFX(manager.achievement_sfx);
                _active = true;
            }
        ),
        (
            instruction: "Zo maak je het geluid van je sample zachter. Als je hem helemaal buiten de driehoek zet hoor je niks meer",
            condition: () => false,
            outcome: null
        ),

        // End of tutorial
        (
            instruction: "Je bent klaar om nu zelf verder te werken aan je lied. Veel plezier!",
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
                DisplayServer.TtsStop();
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
            manager.pointer.Visible = false;
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
      
        SpeakTutorialInstruction(tutorial_level);
        UpdateLists();
    }

    private static void _correctStompPlaySFX()
    {
        if (_stomping)
        {
            if (manager.stompedOnBeatAmount > _previousStomp)
            {
                manager.PlayExtraSFX(manager.achievement_sfx);
                _previousStomp = manager.stompedOnBeatAmount;
                manager.AmountLeft.Text = $"Goed gestamped {manager.stompedOnBeatAmount} / 5";
            }
        }
    }

    private static void _correctClapPlaySFX()
    {
        if (_clapping)
        {
            if (manager.clappedOnBeatAmount > _previousClap)
            {
                manager.PlayExtraSFX(manager.achievement_sfx);
                _previousClap = manager.clappedOnBeatAmount;
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
        if (_increasedSpeed)
        {
            DisplayServer.TtsSpeak(without_emoticons(tutorialSteps[instructionIndex].instruction), voices[0], 100,1f, 1.5f);
        }
        else
        {
            DisplayServer.TtsSpeak(without_emoticons(tutorialSteps[instructionIndex].instruction), voices[0], 100);
        }
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