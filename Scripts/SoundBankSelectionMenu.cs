using Godot;
using System;
using System.Collections.Generic;
using System.Text.Json;

public partial class SoundBankSelectionMenu : Panel
{
    public int chosenElectronicFactor;
    public List<string> chosenThemes = [];
    public List<string> chosenEmotions = [];

    [Export] Slider accousticSlider;
    [Export] CheckButton[] emotionToggles;
    [Export] CheckButton[] themeToggles;

    [Export] Button zoekButton;
    [Export] Button gebruikButton;
    [Export] Label gevondenSoundBankLabel;

    private SoundBank chosenSoundBank = null;

    public override void _Ready()
    {
        foreach (var emotionToggle in emotionToggles)
        {
            var label = (Label)emotionToggle.GetParent();
            emotionToggle.Pressed += () => 
            {
                if (emotionToggle.ButtonPressed) chosenEmotions.Add(label.Text);
                if (!emotionToggle.ButtonPressed) chosenEmotions.Remove(label.Text);
            };
        }

        foreach (var themeToggle in themeToggles)
        {
            var label = (Label)themeToggle.GetParent();
            themeToggle.Pressed += () => 
            {
                if (themeToggle.ButtonPressed) chosenThemes.Add(label.Text);
                if (!themeToggle.ButtonPressed) chosenThemes.Remove(label.Text);
            };
        }

        zoekButton.Pressed += () => chosenSoundBank = ChooseSoundBank();
        gebruikButton.Pressed += () => 
        {
            // remember audio bank to use
            string path = "temp.txt";
            if (System.IO.File.Exists(path)) System.IO.File.Delete(path);
            System.IO.File.WriteAllText(path, chosenSoundBank.name);

            // load main scene
            GetTree().ChangeSceneToFile("res://Scenes/main.tscn");
        };
    }

    public override void _Process(double delta)
    {
        chosenElectronicFactor = (int)(accousticSlider.Value * 100);
        gebruikButton.Disabled = chosenSoundBank == null;
        gevondenSoundBankLabel.Text = chosenSoundBank?.name;
    }

    public SoundBank ChooseSoundBank()
    {
        var soundbanks = LoadSoundBanks();

        SoundBank bestMatch = null;
        float bestScore = float.MinValue;

        foreach (var bank in soundbanks)
        {
            // check theme matches
            int themeMatches = 0;
            foreach (var theme in chosenThemes) if (bank.themes.Contains(theme)) themeMatches++;

            // check emotion matches
            int emotionMatches = 0;
            foreach (var emotion in chosenEmotions) if (bank.emotions.Contains(emotion)) emotionMatches++;

            // if no matches ignore soundbank
            if (themeMatches == 0 && emotionMatches == 0) continue;

            // normalized scores (0–1)
            float themeScore = (float)themeMatches / (float)chosenThemes.Count;
            float emotionScore = (float)emotionMatches / (float)chosenEmotions.Count;
            float electronicScore = 1.0f - (Math.Abs(bank.electronic - chosenElectronicFactor) / 100.0f);

            // weighted score
            float totalScore = (themeScore * 0.5f) + (emotionScore * 0.3f) + (electronicScore * 0.2f);

            // if score is better overwrite best match
            if (totalScore > bestScore)
            {
                bestScore = totalScore;
                bestMatch = bank;
            }
        }

        return bestMatch;
    }

    public List<SoundBank> LoadSoundBanks()
    {
        string path = "res://Resources/SoundBankMatrix/soundbanks.json";
        if (!FileAccess.FileExists(path))
        {
            GD.Print("json file not found");
            return null;
        }

        var file = FileAccess.Open(path, FileAccess.ModeFlags.Read);
        string jsonText = file.GetAsText();

        var soundbanks = JsonSerializer.Deserialize<List<SoundBank>>(jsonText);

        return soundbanks;
    }
}

public class SoundBank
{
    public string name { get; set; }
    public List<string> themes { get; set; }
    public List<string> emotions { get; set; }
    public int bpm { get; set; }
    public int swing { get; set; }
    public int electronic { get; set; }
}