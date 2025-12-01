using Godot;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;

public partial class MainMenu : Node
{
	[Export] public Button freeButton;
	[Export] public Button tutorialButton;
	[Export] public Button ProButton;
	[Export] public string TutorialExplanationString;


	public void OnTutorialExplanitionPressed()
	{
		//TODO Add the pop up and make the display server speak the sentence from the string TutorialExplanationString
		GD.Print("EXPLAINNNNNNNN");
	}

	public void OnMuziekExplanation()
	{
		GD.Print("EXPLAINNNNNNNN");
	}

	public void OnProExplanationa()
	{
		GD.Print("EXPLAINNNNNNNN");
	}
	
	public override void _Ready()
	{
		freeButton.Pressed += () =>
		{
			// load sound bank selection scene
			GetTree().ChangeSceneToFile("res://Scenes/soundbank.tscn");

			// remember if tutorial should be enabled or not
			{
				string path = Path.Combine(ProjectSettings.GlobalizePath("user://"), "use_achievements.txt");
				if (File.Exists(path)) File.Delete(path);
				File.WriteAllText(path, true.ToString());
			}
		};

		ProButton.Pressed += () =>
		{
			GetTree().ChangeSceneToFile("res://Scenes/soundbank.tscn");
			string path = Path.Combine(ProjectSettings.GlobalizePath("user://"), "use_achievements.txt");
			if (File.Exists(path)) File.Delete(path);
			File.WriteAllText(path, false.ToString());
		};

		tutorialButton.Pressed += () =>
		{
			// remember if tutorial should be enabled or not
			{
				string path = Path.Combine(ProjectSettings.GlobalizePath("user://"), "use_tutorial.txt");
				if (File.Exists(path)) File.Delete(path);
				File.WriteAllText(path, true.ToString());
			}

			// remember audio bank to use
			{
				string json = @"
                {
				""name"": ""tutorial"",
				""themes"": [
					""💔""
                ],
				""emotions"": [
					""😁""
                ],
				""bpm"": 70,
				""swing"": 0,
				""electronic"": 50
				}";

				string path = Path.Combine(ProjectSettings.GlobalizePath("user://"), "chosen_soundbank.json");
				if (File.Exists(path)) File.Delete(path);
				File.WriteAllText(path, json);
			}

			// remember chosen emoticons
			{
				string path = Path.Combine(ProjectSettings.GlobalizePath("user://"), "chosen_emoticons.json");
				List<string> emoticons = ["😁", "💔"];
				var json = JsonSerializer.Serialize(emoticons);
				if (File.Exists(path)) File.Delete(path);
				File.WriteAllText(path, json);
			}

			// remember beat amount
			{
				string path = Path.Combine(ProjectSettings.GlobalizePath("user://"), "beats_amount.txt");
				if (File.Exists(path)) File.Delete(path);
				File.WriteAllText(path, "16");
			}

			// load main scene with tutorial enabled
			GetTree().ChangeSceneToFile("res://Scenes/loading.tscn");
		};
	}
}
