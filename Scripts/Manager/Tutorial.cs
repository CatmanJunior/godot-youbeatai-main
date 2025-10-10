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
    private static int _ringLeft = 4;
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
            manager.SetEntireInterfaceVisibility(false);
            manager.achievementspanel.Visible = true;
            manager.ContinueButton.Pressed += _tutorialContinue;
            manager.PianoArea.BodyEntered += _bodyContinue;
            manager.InBetweenArea.BodyEntered += _bodyContinue;

        }
        else // disable tutorial
        {
            tutorial_level = -1;
            manager.SetEntireInterfaceVisibility(true);
            manager.achievementspanel.Visible = false;
            if (DisplayServer.TtsIsSpeaking()) DisplayServer.TtsStop();
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

    private static bool _interactionDone()
    {
        return Input.IsActionJustPressed("Interaction");

    }

    public static void SetupTutorial()
    {
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
            "Zie je de rode circles, dat is de kick ring",
            "Via deze ring kun je een kick geluid toevoegen aan het liedje kijk maar!",
            "Ik heb er net drie ingevuld, druk nu op '▶️ Start' om de beat te horen",
            " Druk op ⏸️ om het op pauze te zetten ",
            "Nu jij, vul nog 2 circles door op de stippen te drukken",
            "Goed gedaan, nou wil ik wel eens horen wat je gedaan hebt! ▶️",
            "Stamp👞 eens mee op jouw beat!",
            "Wow super gedaan! tijd voor level 2!",

            // klap ring
            "Dit is de klap ring! Hiermee kun je een klap geluid toevoegen",
            "Ik heb zelf net 2 erin gezet, luister er maar eens naar▶️!",
            "Super gedaan!",//todo 
            //todo change text that you not only need to add x but also remove x into two steps instead of one
            "Probeer nu eens zelf 2 klap stippen er bij te zetten" ,
            "Haal nu ook een gevulde stip weg door er nog een keer op te klikken",
            "Ik ben benieuwd laat mij eens horen! ▶️",
            "Probeer mee te klappen op de beat!",
            "Super goed gedaan, nu wordt het echt leuk.",

            //groene laag
            "Zie je die groene ring om de stippen heen? Die vul je in door met je eigen microfoon iets op te nemen!",
            "Probeer het maar eens door op het microphone 🎙️icoontje te klikken",
            "Goed gedaan",
            "Laat eens horen!▶️",
            "Super gedaan, het klinkt heel leuk",
            
            // chaos pad
            "Ik denk dat we het nog leuker kunnen maken met de mixer!",
            "Deze driehoek dat is de mixer!",
            "Hiermee kun je jouw net opgenomen geluid veranderen",
            "Je kunt het geluid veranderen van Jouw stem 🎙️ en een Instrument geluid 🎹  en jouw stem met een effect 🤖",
            //todo add specific location to where you need to put the fingerprint button in this case the piano
            "probeer het maar eens door die witte knop te bewegen",
            "Moet je nu maar eens luisteren",
            "Dit geeft een hele andere sfeer aan je beat",
            //todo add specific location to where you need to put the fingerprint button
            "Zet hem maar  tussen twee zodat ze worden gemixt!",
            "Zo kun je stem met een beetje effect krijgen",
            
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
                GD.Print(manager.stompedAmount);
                return manager.stompedAmount >= _beatsActiveRedRing;
            }, // makes sure the amount you stomped is equal to the amount of beats active
            () =>  false, // need to make a check for button press or screen tap, 

            // oranje ring
            () => false, // need to make a check for button press or screen tap
            () => BpmManager.instance.playing
            , // This checks whether the song is playing
            () => false,

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
            {   GD.Print("clap "+ manager.clappedAmount);
                return manager.clappedAmount >= _beatsActiveOrangeRing;
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
                return   moved;
            },
            ()=> BpmManager.instance.playing,
            //todo Add that you need to put it on spefic location with particle effects
            ()=> false,
            ()=> false,
            ()=> false,
            
            // end of tutorial
           
            () => Input.IsActionJustPressed("Interaction") // need to make a check for button press or screen tap
            
        ];

        outcomes =
        [
            () =>
            {
                manager.SetRingVisibility(_indexRedRing, true);
                manager.cross.Visible = true;
                manager.PlayPauseButton.Visible = true;
                _active = true;
            },
            null,
            () =>
            {
                manager.beatActives[_indexRedRing, _ringTop] = true;
                manager.beatActives[_indexRedRing, _ringLeft] = true;
                manager.beatActives[_indexRedRing, _ringBottom] = true;

            },
            null,
            ()=> BpmManager.instance.playing = false,
            null,
            null,
            ()=> BpmManager.instance.playing = false,
            () => manager.SetRingVisibility(_indexOrangeRing, true),
            ()=>{
            manager.beatActives[_indexOrangeRing, _ringTop] = true;
            manager.beatActives[_indexOrangeRing, _ringBottom] = true;

            },
            null,
            ()=> BpmManager.instance.playing = false,
            null,
            null,
            null,
            ()=> BpmManager.instance.playing = false,
            () => { manager.SetGreenLayerVisibility(true); Manager.instance.SynthMixing_ChangeSynth(_greenLayerMicIndex);

            } ,
            null,
            null,
            null,
            null,
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
                manager.PianoArea.Monitoring = true; 
                manager.PianoMesh.Visible = true;
            },
            null,
            () =>
            {
                manager.PianoArea.Monitoring = false; 
                manager.PianoMesh.Visible = false;
                
            },
            null,
            null,
            null,
            // auto stop for tutorial
            () =>
            {
                tutorial_level = -2;
                manager.SetEntireInterfaceVisibility(true);
                manager.achievementspanel.Visible = false;
                manager.PlayExtraSFX(manager.achievement_sfx);
            }

        ];
    }

    private static void _tutorialContinue()
    {
        if(!_active) return;
        _nextLine();
    }

    private static void _bodyContinue(Node2D body)
    {
        if (body == manager.knob)
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

    public static void UpdateTutorial()
    {
        if (!manager.first_tts_done && useTutorial)
        {
            SpeakTutorialInstruction(tutorial_level);
            manager.first_tts_done = true;
        }
        void Speaking(){  SpeakTutorialInstruction(tutorial_level);}
        
        if (tutorial_level != -1 && useTutorial)
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
