using Godot;
using System;
using System.Collections.Generic;
using System.Text.Json;
using System.IO;

public partial class SoundBankSelectionMenu : Panel
{
	public int chosenElectronicFactorSoundBank;
	public int chosenElectronicFactorThemes = -1;

	public static List<string> chosenThemes { get; private set; }
	public static List<string> chosenEmotions { get; private set; }

	[Export] CheckButton[] emotionToggles;
	[Export] CheckButton[] themeToggles;

	[Export] Button gebruikButton;
	[Export] Label gevondenSoundBankLabel;

	public List<SoundBank> soundbanks;

	public static SoundBank chosenSoundBank { get; private set; }

	// other settings to remember
	[Export] OptionButton hoeveelBeats;
	
	// setting files
	Dictionary<string, string> offsetLookup = JsonSerializer.Deserialize<Dictionary<string, string>>(Godot.FileAccess.Open("res://Resources/SoundBankMatrix/bpmoffset.json", Godot.FileAccess.ModeFlags.Read).GetAsText());
	Dictionary<string, string> lookup = JsonSerializer.Deserialize<Dictionary<string, string>>(Godot.FileAccess.Open("res://Resources/SoundBankMatrix/elec.json", Godot.FileAccess.ModeFlags.Read).GetAsText());

	public override void _Ready()
	{
		chosenEmotions = new List<string>();
		chosenThemes = new List<string>();
		foreach (var emotionToggle in emotionToggles)
		{
			var label = (Label)emotionToggle.GetParent();
			emotionToggle.Pressed += () =>
			{
				if (emotionToggle.ButtonPressed) chosenEmotions.Add(label.Text);
				if (!emotionToggle.ButtonPressed) chosenEmotions.Remove(label.Text);
			};

			var icon = emotionToggle.GetParent() as Label;
			icon.GuiInput += (InputEvent args) =>
			{
				if (args is InputEventMouseButton mouseEvent && mouseEvent.Pressed && mouseEvent.ButtonIndex == MouseButton.Left)
				{
					emotionToggle.ButtonPressed = !emotionToggle.ButtonPressed;
					if (emotionToggle.ButtonPressed) chosenEmotions.Add(label.Text);
					if (!emotionToggle.ButtonPressed) chosenEmotions.Remove(label.Text);
				}
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

			var icon = themeToggle.GetParent() as Label;
			icon.GuiInput += (InputEvent args) =>
			{
				if (args is InputEventMouseButton mouseEvent && mouseEvent.Pressed && mouseEvent.ButtonIndex == MouseButton.Left)
				{
					themeToggle.ButtonPressed = !themeToggle.ButtonPressed;
					if (themeToggle.ButtonPressed) chosenThemes.Add(label.Text);
					if (!themeToggle.ButtonPressed) chosenThemes.Remove(label.Text);
				}
			};

			soundbanks = LoadSoundBanks();
		}

		gebruikButton.Pressed += () =>
		{
			// remember beat amount
			{
				string path = Path.Combine(ProjectSettings.GlobalizePath("user://"), "beats_amount.txt");
				if (File.Exists(path)) File.Delete(path);
				File.WriteAllText(path, hoeveelBeats.Text);

				BpmManager.beatsAmount = int.Parse(hoeveelBeats.Text);
			}

			// remember if tutorial should be enabled or not
			{
				string path = Path.Combine(ProjectSettings.GlobalizePath("user://"), "use_tutorial.txt");
				if (File.Exists(path)) File.Delete(path);
				File.WriteAllText(path, false.ToString());
			}

			// load main scene
			GetTree().ChangeSceneToFile("res://Scenes/loading.tscn");
		};
	}

	private int GetOffset()
	{
		int offset = 0;
		foreach (string theme in chosenThemes) if (offsetLookup.ContainsKey(theme)) offset += int.Parse(offsetLookup[theme]);
		return offset;
	}

	public override void _Process(double delta)
	{
		int a = 0, b = 0, c = 0;
		if (chosenThemes.Count > 0)
		{
			foreach (string theme in chosenThemes)
			{
				int e = int.Parse(lookup[theme]);
				if (e == 0) a++;
				if (e == 1) b++;
				if (e == 2) c++;
			}
		}

		string elecStr = "none";
		if (a > 0 || b > 0 || c > 0)
		{
			int largestvalue = Math.Max(a, Math.Max(b, c));
			if (largestvalue == a) chosenElectronicFactorThemes = 0;
			if (largestvalue == b) chosenElectronicFactorThemes = 1;
			if (largestvalue == c) chosenElectronicFactorThemes = 2;
			if (chosenElectronicFactorThemes == 0) elecStr = "accoustisch";
			if (chosenElectronicFactorThemes == 1) elecStr = "normaal";
			if (chosenElectronicFactorThemes == 2) elecStr = "electrisch";
		}
		

		gevondenSoundBankLabel.Text = chosenSoundBank == null ? "..." : chosenSoundBank.name + " (bpm: " + chosenSoundBank?.bpm + ", swing: " + chosenSoundBank?.swing + "%, bpm-offset: " + GetOffset().ToString() + ") " + "(" + elecStr + ")";

		gebruikButton.Disabled = chosenSoundBank == null;

		string emoticons = "";
		foreach (var emoticon in chosenEmotions) emoticons += emoticon;

		string themes = "";
		foreach (var theme in chosenThemes) themes += theme;

		chosenSoundBank = ChooseSoundBank();
	}

	public SoundBank ChooseSoundBank()
	{
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

			// weighted score
			float totalScore = (themeScore * 0.5f) + (emotionScore * 0.3f);

			// if 2 banks allign, use electronic factor to decide
			if (bestScore == totalScore)
			{
				if (chosenElectronicFactorThemes == bank.electronic) totalScore += 0.01f;
				if (chosenElectronicFactorThemes != bank.electronic) totalScore -= 0.01f;
			}

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
		if (!Godot.FileAccess.FileExists(path))
		{
			GD.Print("json file not found");
			return null;
		}

		var file = Godot.FileAccess.Open(path, Godot.FileAccess.ModeFlags.Read);
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
