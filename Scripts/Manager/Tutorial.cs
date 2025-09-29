using Godot;

using System;
using System.IO;
using System.Text.RegularExpressions;
using System.Globalization;

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
            //Todo looking into what is the better version of these text to keep kids entertained and not feeling bored
            // intro
            "Hoi! Mijn naam is Klappy en wij gaan samen een beat maken!",

            // kick ring
            "Zie je de rode bollen, dat is de kick ring",
            "Via deze ring kun je een kick geluid toevoegen aan het liedje kijk maar!",
            "Ik heb er net drie op gezet, druk nu op '⏯ Start' om de beat te horen",
            "Gewledige beat toch?",
            "Probeer het zelf maar eens door er 2 op te zetten door op de bolletjes te klicken",
            "Goed gedaan, nou wil ik wel eens horen wat je gedaan hebt!",
            "Wou super gedaan!, nou ik denk dat we wel een stapje verder kunnen gaan",

            // klap ring
            "Dit is de klap ring! Hiermee kun je een klap geluid toevoegen",
            "Ik heb zelf net 2 er in gezet, luister er maar eens naar!",
            "Leuk toch!",
            "Probeer het zelf maar eens door er 2 neer te zetten",
            "Super goed gedaan, het gaat zo goed ik denk dat we er nog iets bij kunnen doen!",

            //groene laag
            "Zie je die groene ring om de beats heen? Die vul je in door met je eigen microphone iets op te nemen!",
            "Probeer het maar eens door op het microphone icoontje te clicken",
            "Laat eens horen!",
            "Super gedaan, het klinkt enorm leuk",

            //End of tutorial
            "Het liedje is al goed op weg, je mag nu zelf volledig aan de slag! Veel plezier!",



        ];

        conditions =
        [
            // intro
            () => Input.IsActionJustPressed("Interaction"), // need to make a check for button press or screen tap

            // rode ring
            () => Input.IsActionJustPressed("Interaction"), // need to make a check for button press or screen tap
            () => Input.IsActionJustPressed("Interaction"), // need to make a check for button press or screen tap
            () => BpmManager.instance.playing == true, // This checks whether the song is playing
            () => !BpmManager.instance.playing, // This checks whether the song is not playing 
            () => activeBeatsPerRing(_indexRedRing) >= _beatsActiveRedRing, // This checks whether the 5 beats are active
            () => BpmManager.instance.playing == true, // This checks whether the song is playing
            () =>!BpmManager.instance.playing, 

            // oranje ring
            () => Input.IsActionJustPressed("Interaction"), // need to make a check for button press or screen tap
            () => BpmManager.instance.playing == true, // This checks whether the song is playing
            () => !BpmManager.instance.playing, 
            () => activeBeatsPerRing(_indexOrangeRing) >= _beatsActiveOrangeRing, // Again what is the 4, I assume checks if the 2 rings are active
            () => BpmManager.instance.playing == true, // This checks whether the song is playing
            () => !BpmManager.instance.playing,  

            // layer voice over
            () => Input.IsActionJustPressed("Interaction"), // need to make a check for button press or screen tap
            () => manager.layerVoiceOver0.finished,
            () => Input.IsActionJustPressed("Interaction"), // need to make a check for button press or screen tap
            () => BpmManager.instance.playing == true
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
            null, // druk play
            null, // geef energie
            () =>
            {
              //todo Green layer 
            },

            null,
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

            if (tutorial_level != -1 && useTutorial)
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
