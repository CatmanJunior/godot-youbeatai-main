using Godot;
using System.IO;
using System.Text.Json;
using System.Collections.Generic;
using System.Linq;

public partial class Manager : Node
{
    SoundBank chosenSoundBank = null;
    List<string> chosenEmoticons = null;

    public static AudioBank bank;

    private void ReadJsonFromPreviousSceneAndSetValues()
    {
        if (SoundBankSelectionMenu.chosenSoundBank == null)
            return;
            
        chosenSoundBank = SoundBankSelectionMenu.chosenSoundBank;
        foreach (var emoticon in SoundBankSelectionMenu.chosenEmotions) chosen_emoticons_label.Text += emoticon;
        foreach (var emoticon in SoundBankSelectionMenu.chosenThemes) chosen_emoticons_label.Text += emoticon;

        GD.Print(chosen_emoticons_label.Text);

        // grab audio files -> res://Resources/Audio/SoundBanks/
        string baseDirPath = "res://Resources/Audio/SoundBanks/" + chosenSoundBank.name;
        bank = ResourceLoader.Load<AudioBank>(baseDirPath + "/" + chosenSoundBank.name + ".tres");
        mainAudioFiles[0] = bank.kick;
        mainAudioFiles[1] = bank.clap;
        mainAudioFiles[2] = bank.snare;
        mainAudioFiles[3] = bank.closed;

        mainAudioFilesAlt[0] = bank.kick_alt;
        mainAudioFilesAlt[1] = bank.clap_alt;
        mainAudioFilesAlt[2] = bank.snare_alt;
        mainAudioFilesAlt[3] = bank.closed_alt;

        // var green_alt = AudioServer.GetBusIndex("Green_alt");
        // bank.effectProfile.Apply(green_alt);
        
        var green = AudioServer.GetBusIndex("Green");
        bank.effectProfile.Apply(green);
        
        var purple = AudioServer.GetBusIndex("Purple");
        bank.effectProfile.Apply(purple);
        
        // var purple_alt = AudioServer.GetBusIndex("Purple_alt");
        // bank.effectProfile.Apply(purple_alt);

        // set swing
        float chosenswing = chosenSoundBank.swing / 100f * 0.4f;
        BpmManager.instance.swing = chosenswing;
        startswing = chosenswing;
        swingslider.Value = chosenswing;

        // set bpm offset
        if (!Tutorial.useTutorial)
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
    }
}