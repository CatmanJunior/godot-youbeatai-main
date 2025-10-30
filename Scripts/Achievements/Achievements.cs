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

    // achievements connected to each node
    private static (bool condition, string tooltip, float worth)[] achievements =>
    [
        (
            condition: ActiveBeatsPerRing(0) >= 4, 
            tooltip: "Deze achievement kan je unlocken door 4 beats te plaatsen op de rode ring.",
            worth: -1 // if worth is -1, the achievement doesnt cost energy points
        ),
        (
            condition: true, // ignore condition, only check if enough energy exists
            tooltip: "Deze achievement kan je unlocken voor 20 energy punten.",
            worth: 20
        ),
        (
            condition: manager.layerVoiceOver0.GetCurrentLayerVoiceOver() != null, 
            tooltip: "Deze achievement kan je unlocken door de groene ring op te nemen.",
            worth: -1
        ),
        (
            condition: manager.layerVoiceOver1.GetCurrentLayerVoiceOver() != null, 
            tooltip: "Deze achievement kan je unlocken door de paarse ring op te nemen.",
            worth: -1
        ),
        (
            condition: manager.addedLayer, 
            tooltip: "Deze achievement kan je unlocken door een nieuwe laag toe te voegen.",
            worth: -1
        ),
    ];

    public static void OnReady()
    {
        // hide blockers if tutorial, show if achievements
        foreach (var node in nodes)
        {
            var blocker = FindBlocker(node);
            SetBlockerState(blocker, useAchievements);
        }
    }

    public static Vector2 WorldToUI(Vector2 worldPos)
    {
        return manager.GetViewport().GetCamera2D().GetCanvasTransform() * worldPos - new Vector2(1280 / 2, 720 / 2);
    }

    public static Vector2 UIToWorld(Vector2 uiPos)
    {
        return manager.GetViewport().GetCamera2D().GetCanvasTransform().AffineInverse() * uiPos;
    }

    public static void OnUpdate()
    {
        // node positions deltas
        for (int i = 0; i < nodes.Length; i++) FindBlocker(nodes[i]).GlobalPosition = WorldToUI(nodes[i].GlobalPosition) - FindBlocker(nodes[i]).Size / 2 * FindBlocker(nodes[i]).Scale;

        // if node state is locked make node disabled and make node have a locked icon
        for (int i = 0; i < nodes.Length; i++)
        {
            var node = nodes[i];
            var condition = achievements[i].condition;
            var worth = achievements[i].worth;
            var useworth = worth != -1 && worth > 0;
            var enoughworth = manager.progressBarValue > worth;
            var blocker = FindBlocker(node);
            if (blocker.Visible && condition)
            {
                if (!useworth)
                {
                    SetBlockerState(blocker, false);
                }
                else
                {
                    if (enoughworth)
                    {
                        SetBlockerState(blocker, false);

                        if (worth != -1 && worth > 0)
                        {
                            manager.progressBarValue -= worth;
                            if (manager.progressBarValue < 0) manager.progressBarValue = 0;
                        }
                    }
                }
            }
        }

        if (!doneLateReady)
        {
            // init tooltip actions
            for (int i = 0; i < nodes.Length; i++)
            {
                var node = nodes[i];
                var blocker = FindBlocker(node);

                blocker.GuiInput += (inputEvent) =>
                {
                    if (inputEvent is InputEventMouseButton mouseEvent)
                    {
                        if (mouseEvent.Pressed && mouseEvent.ButtonIndex == MouseButton.Left)
                        {
                            if (manager.achievementspanel.Visible) CloseTooltip();

                            OpenTooltip(node);
                            StartLoopToCheckIfTooltipCanClose();
                        }
                    }
                };
            }

            doneLateReady = true;
        }
    }

    public static void StartLoopToCheckIfTooltipCanClose()
    {
        if (manager == null) return;
        manager.GetTree().CreateTimer(0.4).Timeout += () =>
        {
            if (DisplayServer.TtsIsSpeaking()) StartLoopToCheckIfTooltipCanClose();
            else CloseTooltip();
        };
    }

    public static void SetBlockerState(Blocker blocker, bool enabled)
    {
        blocker.Visible = enabled;
        blocker.MouseFilter = enabled ? Control.MouseFilterEnum.Stop : Control.MouseFilterEnum.Ignore;
    }

    public static Blocker FindBlocker(Node node)
    {
        var blocker = (Blocker)node.FindChild("Blocker", true);
        return blocker ?? null;
    }

    public static void OpenTooltip(Node2D node)
    {
        var index = nodes.ToList().IndexOf(node);
        manager.achievementspanel.Visible = true;
        manager.InstructionLabel.Text = achievements[index].tooltip;
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
        DisplayServer.TtsSpeak(ExtractEmoticons(achievements[index].tooltip), voices[0], 100);
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
        doneLateReady = false;
    }

    private static int ActiveBeatsPerRing(int indexRing)
    {
        int amount = 0;
        for (int beat = 0; beat < BpmManager.beatsAmount; beat++)
            if (manager.beatActives[indexRing, beat])
                amount++;
        return amount;
    }
}