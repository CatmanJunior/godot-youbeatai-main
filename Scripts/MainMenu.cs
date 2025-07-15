using Godot;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;

public partial class MainMenu : Node
{
    [Export] public Button freeButton;
    [Export] public Button tutorialButton;

    public override void _Ready()
    {

        freeButton.Pressed += () =>
        {
            // load sound bank selection scene
            GetTree().ChangeSceneToFile("res://Scenes/soundbank.tscn");
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