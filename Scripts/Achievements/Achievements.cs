using Godot;

using System.IO;
using System.Collections.Generic;
using System.Linq;
using System;

public static class Achievements
{
    static Manager manager => Manager.instance;
    public static bool useAchievements;
    public static bool achievementsModeIsActivated = false;

    // nodes with blockers
    private static List<Node2D> nodes => manager.NodesThatCanBeUnlocked.ToList();

    // conditions for each node
    private static List<bool> conditions =>
    [
        BpmManager.instance.currentBeat == BpmManager.beatsAmount - 4,
    ];

    public static void OnReady()
    {
        // not used right now
    }

    public static void OnUpdate()
    {
        // if node state is locked make node disabled and make node have a locked icon
        for (int i = 0; i < nodes.Count; i++)
        {
            var node = nodes[i];
            var condition = conditions[i];
            var blocker = FindBlocker(node);
            if (blocker.Visible && condition) blocker.Visible = false;
        }
    }

    public static Blocker FindBlocker(Node2D node)
    {
        var blocker = (Blocker)node.FindChild("Blocker", true);
        return blocker ?? null;
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
        achievementsModeIsActivated = false;
        useAchievements = ReadUseAchievements();
    }
}