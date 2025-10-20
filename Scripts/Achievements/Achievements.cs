using Godot;

using System.IO;
using System.Collections.Generic;
using System.Linq;
using System;
using System.Globalization;
using System.Text.RegularExpressions;

public static class Achievements
{
    static Manager manager => Manager.instance;
    public static bool useAchievements;
    private static bool doneLateReady = false;

    // nodes with blockers
    private static Node2D[] nodes => manager.NodesThatCanBeUnlocked;

    // conditions for each node
    private static bool[] conditions =>
    [
        BpmManager.instance.currentBeat == BpmManager.beatsAmount - 4,
    ];

    private static string[] tooltips =>
    [
        "do a for b"
    ];

    public static void OnReady()
    {
        // hide blockers if tutorial, show if achievements
        foreach (var node in nodes)
        {
            var blocker = FindBlocker(node);
            blocker.Visible = useAchievements;
        }
    }

    public static void OnUpdate()
    {
        // if node state is locked make node disabled and make node have a locked icon
        for (int i = 0; i < nodes.Length; i++)
        {
            var node = nodes[i];
            var condition = conditions[i];
            var blocker = FindBlocker(node);
            if (blocker.Visible && condition) blocker.Visible = false;
        }

        if (!doneLateReady)
        {
            // init tooltip actions
            for (int i = 0; i < nodes.Length; i++)
            {
                var node = nodes[i];
                var blocker = FindBlocker(node);
                blocker.MouseEntered += () => OpenTooltip(i-1);
                blocker.MouseExited += () => CloseTooltip();
            }

            doneLateReady = true;
        }
    }

    public static Blocker FindBlocker(Node2D node)
    {
        var blocker = (Blocker)node.FindChild("Blocker", true);
        return blocker ?? null;
    }

    public static void OpenTooltip(int index)
    {
        manager.achievementspanel.Visible = true;
        manager.InstructionLabel.Text = tooltips[index];
        SpeakTooltip(index);
    }

    public static void CloseTooltip()
    {
        manager.InstructionLabel.Text = "";
        manager.achievementspanel.Visible = false;
        if (DisplayServer.TtsIsSpeaking()) DisplayServer.TtsStop();
    }

    private static void SpeakTooltip(int index)
    {
        if (manager.muteSpeach.ButtonPressed) return;
        var voices = DisplayServer.TtsGetVoicesForLanguage("nl");
        if (voices.Length == 0) voices = DisplayServer.TtsGetVoicesForLanguage("en");
        if (DisplayServer.TtsIsSpeaking()) DisplayServer.TtsStop();
        DisplayServer.TtsSpeak(ExtractEmoticons(tooltips[index]), voices[0], 100);
    }

    private static string ExtractEmoticons(string input)
    {
        var output = "";
        var stringInfo = new StringInfo(input);
        for (int i = 0; i < stringInfo.LengthInTextElements; i++)
        {
            string element = stringInfo.SubstringByTextElements(i, 1);
            if (!Regex.IsMatch(element, @"\p{Cs}|\p{So}|\p{Sk}|\p{Mn}|\u200D")) output += element;
        }
        return output;
    }

    private static bool ReadUseAchievements()
    {
        bool use;
        try
        {
            string path = Path.Combine(ProjectSettings.GlobalizePath("user://"), "use_achievements.txt");
            string content = File.ReadAllText(path);
            use = bool.Parse(content);
            if (File.Exists(path)) File.Delete(path);
        }
        catch
        {
            use = false;
        }

        GD.Print("use achievements: " + use.ToString());
        
        return use;
    }

    public static void CheckIfAchievementsModeShouldBeActive()
    {
        useAchievements = ReadUseAchievements();
    }

    public static void Reset()
    {
        CheckIfAchievementsModeShouldBeActive();
    }
}