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

    static Manager manager => Manager.instance;

    public static void Reset()
    {
        tutorial_level = 0;
        tutorialActivated = false;
    }

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

    public static void SetupTutorial()
    {
        var actives = (int ring) =>
        {
            int amount = 0;
            for (int beat = 0; beat < BpmManager.beatsAmount; beat++) if (manager.beatActives[ring, beat]) amount++;
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
            () => manager.clapped, // t key is debug only

            // rode ring
            () => actives(0) >= 4, // temp
            () => actives(0) >= 6, // temp
            () => BpmManager.instance.playing == true, // temp
            () => manager.stompedAmount > 4, // temp

            // oranje ring
            () => actives(1) >= 4, // temp
            () => BpmManager.instance.playing == true, // temp
            () => manager.clappedAmount > 4, // temp

            // gele ring
            () => actives(2) >= 2, // temp

            // blauwe ring
            () => actives(3) >= 2, // temp

            // alle ringen
            () => BpmManager.instance.playing == true, // temp

            // progressie bar
            () => manager.progressBar.Value > 50,

            // custom sample
            () => manager.recordSampleButton0.recordedAudio != null,
            () => true, // skip for now
            () => BpmManager.instance.playing == true, // temp

            // effects

            // layer voice over
            () => manager.layerVoiceOver0.finished || manager.layerVoiceOver1.finished,
            () => manager.layerLoopToggle.ButtonPressed,
            () => BpmManager.instance.playing == true,
            () => manager.savedToLaout == true && manager.loadedtemplate == true,

            // song voice over
            () => SongVoiceOver.instance.finished,
            () => manager.hassavedtofile == true,
            () => false
        ];

        outcomes =
        [
            () => { manager.SetRingVisibility(0, true); manager.cross.Visible = true; },
            null,
            () => manager.PlayPauseButton.Visible = true,
            () => manager.progressBar.Visible = true,
            () => manager.SetRingVisibility(1, true),
            null,
            null,
            () => manager.SetRingVisibility(2, true), // zet geel
            () => manager.SetRingVisibility(3, true), // zet blauw
            null, // druk play
            null, // geef energie
            () => { manager.SetRecordingButtonsVisibility(true); manager.SetDragAndDropButtonsVisibility(true); },
            null,
            null,
            () =>
            {
                ((Sprite2D)manager.layerVoiceOver0.recordLayerButton.GetParent()).Visible = true;
                manager.layerVoiceOver0.textureProgressBar.Visible = true;
            },

            // layer voice over
            () => { manager.SetLayerSwitchButtonsVisibility(true); manager.layerLoopToggle.Visible = true;}, // before doing liedje modus
            () => manager.SetMainButtonsVisibility(true), // before pressing play
            null, // before saving to layout
            () =>
            {
                SongVoiceOver.instance.recordSongButton.Visible = true;
                RealTimeAudioRecording.instance.recordSongButton.Visible = true;
                SongVoiceOver.instance.recordSongSprite.Visible = true;
                RealTimeAudioRecording.instance.recordSongSprite.Visible = true;
                SongVoiceOver.instance.progressbar.Visible = true;
            },

            // song voice over
            () => { manager.settingsButton.Visible = true; manager.settingsPanel.Visible = true; }, // before saving to file
            () => manager.SetEntireInterfaceVisibility(true), // enable all
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