using Godot;

using System.IO;
using System.Collections.Generic;
using System.Linq;

public static class Achievements
{
    static Manager manager => Manager.instance;

    public static bool achievementsModeIsActivated = false;

    // nodes that are locked by default but can be unlocked
    private static List<Node2D> nodes = manager.NodesThatCanBeUnlocked.ToList();

    private static List<bool> states;

    public static void Reset()
    {
        achievementsModeIsActivated = false;
        useAchievements = ReadUseAchievements();
    }

    public static void OnReady()
    {
        // init state to not unlocked
        states = new List<bool>(nodes.Count);
        for (int i = 0; i < states.Count; i++) states[i] = false;
    }

    public static void OnUpdate()
    {
        // if node state is locked make node disabled and make node have a locked icon
        for (int i = 0; i < nodes.Count; i++)
        {
            var node = nodes[i];
            var state = states[i];
            var blocker = FindBlocker(node);

            if (state == false) blocker.Visible = false;
            else blocker.Visible = true;
        }
    }

    public static Node2D FindBlocker(Node2D node)
    {
        var blocker = (Node2D)node.FindChild("Blocker", true);
        if (blocker != null) return blocker;
        else return null;
    }

    public static void UnlockNode(Node2D node)
    {
        // unlock node
        int index = nodes.IndexOf(node);
        states[index] = true;
    }

    public static void UnlockNode(int index)
    {
        // unlock node
        states[index] = true;
    }

    public static bool useAchievements;
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
}