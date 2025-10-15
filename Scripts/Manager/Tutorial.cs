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

    static string[] instructions = null;
    static Func<bool>[] conditions = null;
    static Action[] outcomes = null;
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
    private static int _previousclap = 0;
    private static int _previousstomp = 0;
    private static bool _stomping = false;
    private static bool _clapping = false;
    private static Timer timer;
  
    static Manager manager => Manager.instance;

    public static void Reset()
    {
        tutorial_level = 0;
        tutorialActivated = false;
        useTutorial = ReadUseTutorial();
        instructions = null;
        conditions = null;
        outcomes = null;
        
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
            
            _top = manager.corners[1];

        }
        else // disable tutorial
        {
            tutorial_level = -1;
            manager.SetEntireInterfaceVisibility(true);
            manager.achievementspanel.Visible = false;
            if (DisplayServer.TtsIsSpeaking()) DisplayServer.TtsStop();
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

    // flag if tutorial mode should be enabled
    public static bool useTutorial;
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
        var activeBeatsPerRing = (int indexRing) =>
        {
            int amount = 0;
            for (int beat = 0; beat < BpmManager.beatsAmount; beat++)
                if (manager.beatActives[indexRing, beat])
                    amount++;
            return amount;
        };

        // setup achievements
        instructions =
        [
            // intro
            "Hoi! Mijn naam is Klappy en wij gaan samen een beat maken! Om te beginnen klap 👏in je handen.",

            // kick ring
            "deze rode cirkels vormen een beat ring",
            "Met deze ring kun je een kick plaatsen op jouw beat. Kijk maar!",
            "Ik heb er net drie ingevuld, druk nu op '▶️ Start' om de beat te horen",
            " Druk op ⏸️ om het op pauze te zetten ",
            "Nu jij, vul nog 2 cirkels door op de stippen te drukken",
            "Goed gedaan, nou wil ik wel eens horen wat je gedaan hebt! ▶️",
            "Stamp👞 eens 5 keer mee op jouw beat!",
            "Wow super gedaan! tijd voor level 2!",

            // klap ring
            "Dit is de klap ring! Hiermee kun je een klap geluid toevoegen",
            "Ik heb er zelf net 2 erin gezet, luister er maar eens naar▶️!",
            "",
            "Klinkt al leuk!",//todo 
            //todo change text that you not only need to add x but also remove x into two steps instead of one
            "Probeer nu eens zelf 2 klap stippen er bij te zetten" ,
            "Haal nu ook een gevulde stip weg door er nog een keer op te klikken",
            "Ik ben benieuwd laat mij eens horen! ▶️",
            "Probeer 5 keer mee te klappen op de beat!",
            "Super goed gedaan, je hebt talent!.",

            //groene laag
            "Zie je die groene ring om de stippen heen? Die vul je in door met je eigen microfoon iets op te nemen!",
            "Probeer het maar eens door op het microfoon 🎙️icoontje te klikken",
            "Goed gedaan",
            "Laat eens horen!▶️",
            "Super gedaan, het klinkt heel leuk",
            
            // chaos pad
            "Ik denk dat we het nog leuker kunnen maken met de mixer!",
            "Deze driehoek is de mixer!",
            "Hiermee kun je jouw net opgenomen geluid veranderen",
            "Je kunt  Jouw stem 🎙️ veranderen in het geluid van een Instrument 🎹  en jouw stem met een effect 🤖",
            //todo change '' to what the assest is later star Icon
            "probeer het maar eens door het grijze rondje te bewegen naar het 🌟 ",
            "Luister maar eens!",
            "Dit geeft een hele andere sfeer aan je beat",
            "Door het grijze rondje nu tussen twee icoontjes te plaatsen maak je een mix!",
            "Zo krijg je een mix tussen jou stem en het instrument!",
            //todo going outside the the mixer goes quieter
            
            //End of tutorial
            "Het liedje is al goed op weg, je mag nu zelf volledig aan de slag! Veel plezier!"






        ];

        conditions =
        [
            
            // intro
            
            () => manager.clapped, 

            // rode ring
            () => false, // need to make a check for button press or screen tap
            () => false, // need to make a check for button press or screen tap
            () => BpmManager.instance.playing, // This checks whether the song is playing
            () => !BpmManager.instance.playing,
            () => activeBeatsPerRing(_indexRedRing) >= _beatsActiveRedRing, // This checks whether the 5 beats are active
            () =>
            {
                _beatsActiveRedRing = activeBeatsPerRing(_indexRedRing);
                return BpmManager.instance.playing;
            }, // This checks whether the song is playing
            ()=>
            {
               
                return manager.stompedAmount >= _fixedAmount;
            }, // makes sure the amount you stomped is equal to the amount of beats active
            () =>  false, // need to make a check for button press or screen tap, 

            // oranje ring
            () => false, // need to make a check for button press or screen tap
            () => BpmManager.instance.playing
            , // This checks whether the song is playing
            () => timer.TimeLeft == 0,
            ()=> false,

            () =>
            {
                return activeBeatsPerRing(_indexOrangeRing) >= _beatsActiveOrangeRing;
            },
            () =>
            {
                return activeBeatsPerRing(_indexRedRing) < _beatsActiveRedRing || activeBeatsPerRing(_indexOrangeRing) < _beatsActiveOrangeRing;
            },

            () =>
            {   _beatsActiveOrangeRing = activeBeatsPerRing(_indexOrangeRing);
                return BpmManager.instance.playing;
            }, // This checks whether the song is playing
            ()=>
            {  
                return manager.clappedAmount >= _fixedAmount;
            }, // This checks whether the song is playing
            () =>false, // need to make a check for button press or screen tap,   

            // layer voice over
            () => false, // need to make a check for button press or screen tap
            () => manager.layerVoiceOver0.finished,
            () => false, // need to make a check for button press or screen tap
            () => BpmManager.instance.playing,
            () => false, // need to make a check for button press or screen tap 
            
            // chaos pad
            ()=>
            {
                //todo make it so that you need to put it on spefic location instead of any
                _knobPos = manager.knob.GlobalPosition;
                return false;
            }, // need to make a check for button press or screen tap,
            ()=> false,
            ()=> false,
            ()=> false,
            () =>
            {
              
                bool moved = _knobPos != manager.knob.GlobalPosition;
                return   false;
            },
            ()=> BpmManager.instance.playing,
            //todo Add that you need to put it on spefic location with particle effects
            ()=> false,
            ()=> false,
            ()=> false,
            
            // end of tutorial
           
            () =>false // need to make a check for button press or screen tap
            
        ];

        outcomes =
        [
            () =>
            {
                manager.SetRingVisibility(_indexRedRing, true);
                manager.cross.Visible = true;
                
                _active = true;
                manager.KlappyContinue.Visible = false;
                manager.settingsButton.Visible = true;
            },
            //stomp ring
            null,
            () =>
            {
                manager.beatActives[_indexRedRing, _ringTop] = true;
                manager.beatActives[_indexRedRing, _ringRight] = true;
                manager.beatActives[_indexRedRing, _ringBottom] = true;
                _active =false;
                manager.PlayPauseButton.Visible = true;
                manager.SetStompVisibility(true);

            },
            null,
            null,
            null,
            ()=>
            {
                manager.AmountLeft.Text = $"Goed gestamped {manager.stompedAmount} / 5";
                _stomping = true;
            },
            ()=>
            {
                _active =true;
                _stomping = false;
                manager.AmountLeft.Visible = false;
                manager.AmountLeft.Text = "";
                BpmManager.instance.playing = false;
            },
            () => manager.SetRingVisibility(_indexOrangeRing, true),
            //klap ring
            ()=>{
            manager.beatActives[_indexOrangeRing, _ringRight] = true;
            manager.beatActives[_indexOrangeRing, _ringLeft] = true;
            manager.SetClapVisibility(true);
            _active = false;
            },
            ()=>  timer.Start(timer.WaitTime),
            ()=> { _active =true;},
            ()=>
            {
                _active =false;
                BpmManager.instance.playing = false;
            },
            null,
            null,
            ()=>
            {
                manager.AmountLeft.Visible = true;
                manager.AmountLeft.Text = $"Goed geklapped {manager.clappedAmount} / 5";
                _clapping = true;
            },
            ()=>
            {
                _clapping = false;
                manager.AmountLeft.Visible = false;
                _active = true;
                BpmManager.instance.playing = false;
            },
            () => { manager.SetGreenLayerVisibility(true); Manager.instance.SynthMixing_ChangeSynth(_greenLayerMicIndex);

            } ,
            () =>
            {
                manager.SetMicRecorderVisibility(true);
                _active =false;
                manager.knob.GlobalPosition = _top.GlobalPosition;
              ;
            },
            ()=> {_active =true;},
            () => { _active =false;},
            () => { _active = true;},
            ()=> BpmManager.instance.playing = false,
            //chaos pad
            //todo add particles effects for the specific location of the fingerprint button
            () =>
            {
                SongVoiceOver.instance.recordSongButton.Visible = true;
                RealTimeAudioRecording.instance.recordSongButton.Visible = true;
                SongVoiceOver.instance.recordSongSprite.Visible = true;
                RealTimeAudioRecording.instance.recordSongSprite.Visible = true;
                SongVoiceOver.instance.progressbar.Visible = true;
                manager.chaosPadTriangleSprite.Visible = true;
            },
            null,
            null,
            () =>
            {
                _active = false;
                manager.PianoArea.Monitoring = true; 
                manager.PianoMesh.Visible = true;
            },
            null,
            () =>
            {
                manager.PianoArea.SetDeferred("monitoring",false);
                manager.PianoMesh.Visible = false;
                _active = true;
            },
            ()=>
            {
                _active = false;
                manager.InBetweenMesh.Visible = true;
                manager.InBetweenArea.SetDeferred("monitoring",true);
            },  
            ()=>
            {
                _active = true;
                manager.InBetweenArea.SetDeferred("monitoring",false);
                manager.InBetweenMesh.Visible = false;
            },
            null,
            // auto stop for tutorial
            () =>
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

        ];
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
        if(!_active) return;
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
        if (outcome != null) outcome();
        tutorial_level++;
        manager.PlayExtraSFX(manager.achievement_sfx);
        SpeakTutorialInstruction(tutorial_level);
        updateLists();
    }

    private static void _correctStompPlaySFX()
    {
        if(_stomping)
        {
            if (manager.stompedAmount > _previousstomp)
            {
                manager.PlayExtraSFX(manager.achievement_sfx);
                _previousstomp = manager.stompedAmount;
                manager.AmountLeft.Text = $"Goed gestamped {manager.stompedAmount} / 5";
            }
        }
    }
    
    private static void _correctClapPlaySFX()
    {
        if(_clapping)
        {
            if (manager.clappedAmount > _previousclap)
            {
                manager.PlayExtraSFX(manager.achievement_sfx);
                _previousclap = manager.clappedAmount;
                manager.AmountLeft.Text = $"Goed geklapped {manager.clappedAmount} / 5";
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
       

        void Speaking()
        {
            SpeakTutorialInstruction(tutorial_level);
          
        }
            _correctClapPlaySFX();
            _correctStompPlaySFX();


        if (tutorial_level != -1 && useTutorial && tutorial_level < instructions.Length)
        {
            updateLists();

            manager.f7_pressed_lastframe = manager.f7_pressed;
            manager.f7_pressed = Input.IsKeyPressed(Key.F7);
            bool skip = manager.f7_pressed && manager.f7_pressed != manager.f7_pressed_lastframe;

            if (condition())
            {
                _nextLine();
            }

            if (skip)
            {
                if (outcome != null) outcome();
                tutorial_level++;
                manager.PlayExtraSFX(manager.achievement_sfx);
                SpeakTutorialInstruction(tutorial_level);
                updateLists();
            }
            

        }
    }
    
    private static void SpeakTutorialInstruction(int instruction)
    {
        if (manager.muteSpeach.ButtonPressed) return;
        
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

    private static void updateLists()
    {
        instruction = instructions[tutorial_level];
        condition = conditions[tutorial_level];
        outcome = outcomes[tutorial_level];
        manager.InstructionLabel.Text = instruction;
   
    }
}
