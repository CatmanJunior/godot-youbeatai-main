using Godot;

using System;
using System.IO;
using System.Text.RegularExpressions;
using System.Globalization;

public partial class Manager : Node
{
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
            () => { SetRecordingButtonsVisibility(true); SetDragAndDropButtonsVisibility(true); },
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
}