using Godot;
using System.IO;
using System.Text.Json;
using System.Collections.Generic;

public partial class Manager : Node
{
    SoundBank chosenSoundBank = null;
    List<string> chosenEmoticons = null;

    private void ReadJsonFromPreviousSceneAndSetValues()
    {
        // deserialize chosen soundbank
        string chosen_soundbank_path = Path.Combine(ProjectSettings.GlobalizePath("user://"), "chosen_soundbank.json");
        string chosen_soundbank_json = File.ReadAllText(chosen_soundbank_path);
        chosenSoundBank = JsonSerializer.Deserialize<SoundBank>(chosen_soundbank_json);

        // deserialize chosen emoticons
        string chosen_emoticons_path = Path.Combine(ProjectSettings.GlobalizePath("user://"), "chosen_emoticons.json");
        string chosen_emoticons_json = File.ReadAllText(chosen_emoticons_path);
        chosenEmoticons = JsonSerializer.Deserialize<List<string>>(chosen_emoticons_json);
        foreach (var emoticon in chosenEmoticons) chosen_emoticons_label.Text += emoticon;

        // grab audio files -> res://Resources/Audio/SoundBanks/
        string soundbankname = chosenSoundBank.name;
        string baseDirPath = "res://Resources/Audio/SoundBanks/"; // should be a subfolder of "res://Resources/Audio/SoundBanks/" with the soundbankname in its name.
        DirAccess baseDir = DirAccess.Open(baseDirPath);
        baseDir.ListDirBegin();
        string folderName;
        while ((folderName = baseDir.GetNext()) != "")
        {
            if (baseDir.CurrentIsDir() && folderName.ToLower().Contains(soundbankname.ToLower()))
            {
                // main audio files
                {
                    string major_dir = baseDirPath + folderName + "/";
                    string[] major_files = ResourceLoader.ListDirectory(major_dir);
                    string file;
                    for (int i = 0; i < major_files.Length; ++i)
                    {
                        file = major_files[i];
                        if (file.EndsWith(".wav"))
                        {
                            string lower = file.ToLower();
                            string fullPath = major_dir + file;
                            if (lower.Contains("kick")) mainAudioFiles[0] = ResourceLoader.Load<AudioStream>(fullPath);
                            else if (lower.Contains("clap")) mainAudioFiles[1] = ResourceLoader.Load<AudioStream>(fullPath);
                            else if (lower.Contains("snare")) mainAudioFiles[2] = ResourceLoader.Load<AudioStream>(fullPath);
                            else if (lower.Contains("closed")) mainAudioFiles[3] = ResourceLoader.Load<AudioStream>(fullPath);
                        }
                    }
                }

                // alt audio files
                {
                    string minor_dir = baseDirPath + folderName + "/mineur/";
                    string[] major_files = ResourceLoader.ListDirectory(minor_dir);
                    string file;
                    for (int i = 0; i < major_files.Length; ++i)
                    {
                        file = major_files[i];
                        if (file.EndsWith(".wav"))
                        {
                            string lower = file.ToLower();
                            string fullPath = minor_dir + file;
                            if (lower.Contains("kick")) mainAudioFilesAlt[0] = ResourceLoader.Load<AudioStream>(fullPath);
                            else if (lower.Contains("clap")) mainAudioFilesAlt[1] = ResourceLoader.Load<AudioStream>(fullPath);
                            else if (lower.Contains("snare")) mainAudioFilesAlt[2] = ResourceLoader.Load<AudioStream>(fullPath);
                            else if (lower.Contains("closed")) mainAudioFilesAlt[3] = ResourceLoader.Load<AudioStream>(fullPath);
                        }
                    }
                }

                break;
            }
        }
        baseDir.ListDirEnd();

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

        // delete tmep json files
        File.Delete(chosen_emoticons_path);
        File.Delete(chosen_soundbank_path);
    }
}