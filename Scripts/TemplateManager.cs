using Godot;
using System;
using System.Collections.Generic;

public partial class TemplateManager : Node
{
    [Export] public Button templateButton;
    [Export] public Button leftTemplateButton;
    [Export] public Button rightTemplateButton;
    [Export] public Button showTemplateButton;
    [Export] public Button setTemplateButton;

    public static TemplateManager instance = null;

    public override void _ExitTree()
    {
        if (instance == this) instance = null;
    }

    public List<string> names = new List<string>();
    public List<string> contents = new List<string>();
    public List<bool[,]> actives = new List<bool[,]>();

    public int currentTemplate = 4;

    public override void _Ready()
    {
        instance ??= this;

        leftTemplateButton.Pressed += PreviousTemplate;
        rightTemplateButton.Pressed += NextTemplate;
        showTemplateButton.Pressed += ToggleShowTemplate;
        setTemplateButton.Pressed += SetTemplate;

        ReadTemplates();
    }

    public override void _Process(double delta)
    {
        if (currentTemplate >= 0 && currentTemplate < names.Count)
        {
            string name = names[currentTemplate];
            string modified = name[..^4];
            templateButton.Text = modified;
        }
    }

    public void ReadTemplates()
    {
        var tuple = LoadTextFilesInDirectory("Resources/Templates");
        names = tuple.names;
        contents = tuple.contents;
        actives = tuple.actives;
    }

    (List<string> names, List<string> contents, List<bool[,]> actives) LoadTextFilesInDirectory(string folder)
    {
        string folderPath = $"res://{folder}/";
        using var dir = DirAccess.Open(folderPath);

        List<string> tempNames = new();
        List<string> tempContents = new();
        List<bool[,]> tempActives = new();

        dir.ListDirBegin();
        string fileName = dir.GetNext();

        while (!string.IsNullOrEmpty(fileName)) // Ensure to read all files
        {
            if (fileName.EndsWith(".txt"))
            {
                string filePath = folderPath + fileName;
                try
                {
                    var file = FileAccess.Open(filePath, FileAccess.ModeFlags.Read);
                    tempNames.Add(fileName);
                    string content = file.GetAsText();
                    tempContents.Add(content);
                    tempActives.Add(ToActives(content));
                    file.Close(); // Make sure to close the file
                }
                catch (Exception ex)
                {
                    GD.PrintErr($"Error reading file {filePath}: {ex.Message}");
                }
            }
            fileName = dir.GetNext();
        }
        dir.ListDirEnd();

        return (tempNames, tempContents, tempActives);
    }

    private bool[,] ToActives(string content)
    {
        string[] lines = content.Trim().Split('\n');

        // Check if we received the expected number of lines

        if (lines.Length != 4)
        {
            GD.PrintErr($"Invalid number of lines: {lines.Length}. Expected 4 lines.");
            throw new FormatException("Expected 4 lines for the active states.");
        }

        bool[,] boolArray = new bool[4, BpmManager.beatsAmount];

        for (int i = 0; i < 4; i++)
        {
            string line = lines[i].Trim();

            for (int j = 0; j < BpmManager.beatsAmount; j++)
            {
                boolArray[i, j] = line[j + 1] == '1'; // Skip the first character which is the label
            }
        }

        return boolArray;
    }

    void PreviousTemplate()
    {
        currentTemplate--;
        if (currentTemplate < 0) currentTemplate = names.Count - 1;
    }

    void NextTemplate()
    {
        currentTemplate++;
        if (currentTemplate >= names.Count) currentTemplate = 0;
    }

    void SetTemplate()
    {
        Manager.instance.beatActives = GetCurrentActives();
        Manager.instance.selectedTemplate = true;
    }

    void ToggleShowTemplate() => Manager.instance.showTemplate = !Manager.instance.showTemplate;

    public bool[,] GetCurrentActives() => actives[currentTemplate];
}