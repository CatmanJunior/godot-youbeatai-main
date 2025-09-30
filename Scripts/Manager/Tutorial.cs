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

    static Manager manager => Manager.instance;

    public static void TryActivateTutorial()
    {
        if (useTutorial) // enable tutorial
        {
            manager.SetEntireInterfaceVisibility(false);
            manager.achievementspanel.Visible = true;
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
    public static bool useTutorial = ReadUseTutorial();

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
            //Todo 
            
            // intro
            "Hoi! Mijn naam is Klappy en wij gaan samen een beat maken!",

            // kick ring
            "Zie je de rode bollen, dat is de kick ring",
            "Via deze ring kun je een kick geluid toevoegen aan het liedje kijk maar!",
            "Ik heb er net drie op gezet, druk nu op '⏯ Start' om de beat te horen",
            "",//todo Change the text to not be a question but a statement
            "Probeer het zelf maar eens door er 2 op te zetten door op de bolletjes te klicken",
            "Goed gedaan, nou wil ik wel eens horen wat je gedaan hebt!",
            //todo add text that you need to stomp with the beat to continue the tutorial
            "Wou super gedaan!, nou ik denk dat we wel een stapje verder kunnen gaan",

            // klap ring
            "Dit is de klap ring! Hiermee kun je een klap geluid toevoegen",
            "Ik heb zelf net 2 er in gezet, luister er maar eens naar!",
            "",//todo Change the text to not be a question but a statement
            //todo add text that you not only need to add x but also remove x
            "Probeer het zelf maar eens door er 2 neer te zetten",
            //todo add text that you need to clap with the beat to continue the tutorial
            "Ik ben beniewed laat mij eens horen!",
            "Super goed gedaan, het gaat zo goed ik denk dat we er nog iets bij kunnen doen!",

            //groene laag
            "Zie je die groene ring om de beats heen? Die vul je in door met je eigen microphone iets op te nemen!",
            "Dat kun je doen door eerst op het knopje met de beer te duwen, heb ik nu voor jouw al gedaan :D", //Todo To be removed
            "Probeer het maar eens door op het microphone icoontje te clicken",
            "",//todo Change the text to not be a question but a statement
            "Laat eens horen!",
            "Super gedaan, het klinkt enorm leuk",
            
            // chaos pad
            //Todo Change reverb into galm and change chaos pad into mixer 
            "Ik denk dat we het nog leuker kunnen maken met de chaos pad!",
            "Wat is de chaos pad? Zie je die driehoek links?  Dat is de choas pad!",
            "Hiermee kun je jouw net opgenomen sample veranderen",
            "Je kunt het geluid veranderen naar Boven Jouw stem  Links onder een synth geluid en Rechts onder jouw stem met een revervb",
            //todo add spefic location to where you need to put the fingerprint button in this case the piano
            "probeer het maar eens door die witte button te bewegen",
            "Moet je nu maar eens luisteren",
            "Leuk toch, brengt een heel nieuwe kijk op het liedje",
            //todo add specfic location to where you need to put the fingerprint button
            "Het beste is nog als je hem ergens in het midden tussen twee zet wordt het gemixed!",
            "Zo kun je een synth geluid en reverb met stem krijgen",
            //End of tutorial
            "Het liedje is al goed op weg, je mag nu zelf volledig aan de slag! Veel plezier!"



        ];

        conditions =
        [
            
            // intro
            
            //todo Add the clap to continue back into the start of the tutorial
            () => Input.IsActionJustPressed("Interaction"), // need to make a check for button press or screen tap

            // rode ring
            () => Input.IsActionJustPressed("Interaction"), // need to make a check for button press or screen tap
            () => Input.IsActionJustPressed("Interaction"), // need to make a check for button press or screen tap
            () => BpmManager.instance.playing, // This checks whether the song is playing
            () => !BpmManager.instance.playing, // This checks whether the song is not playing 
            () => activeBeatsPerRing(_indexRedRing) >= _beatsActiveRedRing, // This checks whether the 5 beats are active
            //Todo add that you need to stomp with the beat to continue the tutorial
            () => BpmManager.instance.playing , // This checks whether the song is playing
            () => BpmManager.instance.playing ==false, 

            // oranje ring
            () => Input.IsActionJustPressed("Interaction"), // need to make a check for button press or screen tap
            () => BpmManager.instance.playing, // This checks whether the song is playing
            () => BpmManager.instance.playing== false,
            //Todo Add that you need to not only add x also remove x
            () => activeBeatsPerRing(_indexOrangeRing) >= _beatsActiveOrangeRing, // Again what is the 4, I assume checks if the 2 rings are active
            //Todo add that you need to clap with the beat to continue the tutorial
            () => BpmManager.instance.playing, // This checks whether the song is playing
            () => BpmManager.instance.playing ==false,  

            // layer voice over
            () => Input.IsActionJustPressed("Interaction"), // need to make a check for button press or screen tap
            () => Input.IsActionJustPressed("Interaction"),
            () => manager.layerVoiceOver0.finished,
            () => Input.IsActionJustPressed("Interaction"), // need to make a check for button press or screen tap
            () => BpmManager.instance.playing,
            () => BpmManager.instance.playing == false,
            
            // chaos pad
            ()=>
            {
                //todo make it so that you need to put it on spefic location instead of any
                _knobPos = manager.knob.GlobalPosition;
                return Input.IsActionJustPressed("Interaction");
            }, // need to make a check for button press or screen tap,
            ()=> Input.IsActionJustPressed("Interaction"),
            ()=> Input.IsActionJustPressed("Interaction"),
            ()=> Input.IsActionJustPressed("Interaction"),
            () =>
            {
                bool moved = _knobPos != manager.knob.GlobalPosition;
                return   moved;
            },
            ()=> BpmManager.instance.playing,
            //todo Add that you need to put it on spefic location with particle effects
            ()=> Input.IsActionJustPressed("Interaction"),
            ()=> Input.IsActionJustPressed("Interaction"),
            ()=> Input.IsActionJustPressed("Interaction"),
            
            // end of tutorial
           
            () => Input.IsActionJustPressed("Interaction") // need to make a check for button press or screen tap
            
        ];

        outcomes =
        [ // todo Setting 3 red beats active
            () =>
            {
                manager.SetRingVisibility(_indexRedRing, true);
                manager.cross.Visible = true;
                manager.PlayPauseButton.Visible = true;
            },
            null,
            () =>
            {
                manager.beatActives[_indexRedRing, _ringTop] = true;
                manager.beatActives[_indexRedRing, _ringLeft] = true;
                manager.beatActives[_indexRedRing, _ringBottom] = true;

            },
            null,
            null,
            null,
            null,
            //Todo setting 2 orange beats active
            () => manager.SetRingVisibility(_indexOrangeRing, true),
            ()=>{
            manager.beatActives[_indexOrangeRing, _ringTop] = true;
            manager.beatActives[_indexOrangeRing, _ringBottom] = true;

            }, 
            null,
            null, 
            null,
            null,
            () => { manager.SetGreenLayerVisibility(true); Manager.instance.SynthMixing_ChangeSynth(_greenLayerMicIndex);
                
            } ,
            null,
            null,
            null,
            null,
            null,
            null,
            //chaos pad
            //todo add particles effects for the specific location of the fingerprint button
            () =>
            {
                manager.chaosPadTriangleSprite.Visible = true;
            },
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            // todo Add autostop for tutorial 
            null
            
        ];
    }

    public static void UpdateTutorial()
        {
            void SpeakTutorialInstruction(int instruction)
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

            if (!manager.first_tts_done && useTutorial)
            {
                SpeakTutorialInstruction(0);
                manager.first_tts_done = true;
            }

            if (tutorial_level != -1 && useTutorial && tutorial_level < instructions.Length)
            {
                
                string instruction = instructions[tutorial_level];
                Func<bool> condition = conditions[tutorial_level];
                Action outcome = outcomes[tutorial_level];
                manager.InstructionLabel.Text = instruction;

                manager.f7_pressed_lastframe = manager.f7_pressed;
                manager.f7_pressed = Input.IsKeyPressed(Key.F7);
                bool skip = manager.f7_pressed && manager.f7_pressed != manager.f7_pressed_lastframe;

                if (condition() || skip)
                {
                    if (outcome != null) outcome();
                    tutorial_level++;
                    manager.EmitAchievementParticles();
                    manager.PlayExtraSFX(manager.achievement_sfx);
                    SpeakTutorialInstruction(tutorial_level);
                }
                
            }
        }
}
