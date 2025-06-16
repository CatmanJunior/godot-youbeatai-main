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

    public void CreateNewTemplate(string name, bool[,] actives)
    {
        string folderPath = "res://Resources/Templates/";
        string filePath = folderPath + name + ".txt";

        // Ensure the directory exists
        var dir = DirAccess.Open(folderPath);
        if (!dir.DirExists(folderPath))
        {
            GD.PrintErr("Directory does not exist: " + folderPath);
            return;
        }

        // Check if the file already exists and remove it
        if (dir.FileExists(filePath))
        {
            dir.Remove(filePath);
            GD.Print($"Deleted existing template file: {filePath}");
        }

        string[] rowLabels = { "a", "b", "c", "d" };
        string formattedContent = "";

        for (int i = 0; i < 4; i++)
        {
            formattedContent += rowLabels[i];
            for (int j = 0; j < BpmManager.beatsAmount; j++)
            {
                formattedContent += actives[i, j] ? "1" : "0";
            }
            formattedContent += "\n"; // Ensure each line ends with a newline
        }

        // Debugging: Print the formatted content before writing it to the file
        GD.Print("Formatted content to be written:");
        GD.Print(formattedContent);

        // Writing the file
        var file = FileAccess.Open(filePath, FileAccess.ModeFlags.Write);
        file.StoreString(formattedContent); // Write the formatted content
        file.Close(); // Ensure the file is closed properly
        GD.Print($"Template {name}.txt created at {filePath}");

        // Debugging: Read the file content immediately after writing
        var fileCheck = FileAccess.Open(filePath, FileAccess.ModeFlags.Read);
        string checkContent = fileCheck.GetAsText();
        GD.Print("Content of the newly created file:");
        GD.Print(checkContent);
        fileCheck.Close(); // Close the check file

        // Read templates after saving
        ReadTemplates();
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
            
            // Check if the current line has the expected length
            if (line.Length != BpmManager.beatsAmount + 1) // 1 for label + BpmManager.instance.beatsAmount for binary values
            {
                GD.PrintErr($"Invalid line length: {line.Length}. Expected BpmManager.instance.beatsAmount + 1 characters.");
                throw new FormatException("Line does not contain enough data.");
            }

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
