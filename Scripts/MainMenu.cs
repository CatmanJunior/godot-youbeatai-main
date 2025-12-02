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
	[Export] private Node2D KlappyResponse;
	private gameTypes gameType;

	enum gameTypes
	{
		Tutorial,
		Free,
		Pro
	}

	// public void OnTutorialExplanitionPressed()
	// {
	// 	//TODO Add the pop up and make the display server speak the sentence from the string TutorialExplanationString
	// 	GD.Print("EXPLAINNNNNNNN");
	// }
	//
	// public void OnMuziekExplanation()
	// {
	// 	GD.Print("EXPLAINNNNNNNN");
	// }
	//
	// public void OnProExplanationa()
	// {
	// 	GD.Print("EXPLAINNNNNNNN");
	// }

	public void _on_klappy_respons_bubble_continue_pressed()
	{
		string path = "";
		DisplayServer.TtsStop();
		switch (gameType)
		{
			case gameTypes.Tutorial:
				doTutorial();
				break;
			case gameTypes.Free:
				GetTree().ChangeSceneToFile("res://Scenes/soundbank.tscn");
				path = Path.Combine(ProjectSettings.GlobalizePath("user://"), "use_achievements.txt");
				if (File.Exists(path)) File.Delete(path);
				File.WriteAllText(path, true.ToString());
				break;
			case gameTypes.Pro:
				GetTree().ChangeSceneToFile("res://Scenes/soundbank.tscn");
				path = Path.Combine(ProjectSettings.GlobalizePath("user://"), "use_achievements.txt");
				if (File.Exists(path)) File.Delete(path);
				File.WriteAllText(path, false.ToString());
				break;
		}
	}

	public override void _Ready()
	{
		freeButton.Pressed += () =>
		{
			KlappySpeak("Dit is de standaard game modus, waarbij je een leuk liedje mag gaan maken en daarbij nog toffe dingen kan unlocken");
			// load sound bank selection scene
			gameType = gameTypes.Free;
		};

		ProButton.Pressed += () =>
		{
			KlappySpeak("Bij deze game modus word je helemaal vrij gelaten en mag je helemaal zelf aan de slag.");
			gameType = gameTypes.Pro;
		};

		tutorialButton.Pressed += () =>
		{
			KlappySpeak("Bij deze modus ga ik jouw uit leggen hoe deze game werkt, terwijl wij samen een liedje maken");
			gameType = gameTypes.Tutorial;
		};
	}

	private void doTutorial()
	{
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
	}

	private void KlappySpeak(string message)
	{
		var voices = DisplayServer.TtsGetVoicesForLanguage("nl");
		if (voices.Length == 0) voices = DisplayServer.TtsGetVoicesForLanguage("en");
		if (DisplayServer.TtsIsSpeaking()) DisplayServer.TtsStop();
		DisplayServer.TtsSpeak(message, voices[0]);
		KlappyResponse.Call("fill_response_label",message);
		KlappyResponse.Call("change_panel_visibility", true);
	}
}
