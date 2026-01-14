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
    static bool paused = true;
    static SceneTreeTimer timer;

    // nodes with blockers
    private static Node2D[] nodes => manager.NodesThatCanBeUnlocked;

    // achievements connected to each node
    private static (bool condition, string tooltip, float worth, Action result)[] achievements =>
    [
        Achievement(
            condition: ActiveBeatsPerRing(0) >= 4,
            tooltip: "Door 4 beats te plaatsen op de roze ring speel je deze Snare vrij.",
            result: () => { manager.SetRingVisibility(2, true); }
        ),
        Achievement(
            tooltip: "klap 👏 mee op de beat, verzamel 20 energie punten⚡voor een Hi-hat geluid.",
            worth: 20,
            result: () => { manager.SetRingVisibility(3, true); }
        ),
        Achievement(
            condition: manager.layerVoiceOver0.GetCurrentLayerVoiceOver() != null && pauseBetweenSynthUnlock(),
            tooltip: "Door de gele ring 🐻 op te nemen speel je de paarse drukke 🐦 Synth ring vrij.",
            result: () => { manager.layerVoiceOver1.bigLine.Visible = true; }
        ),
        Achievement(
            condition: manager.layerVoiceOver1.GetCurrentLayerVoiceOver() != null,
            tooltip: "Als je de paarse ring 🐦 op neemt kan je daarna hier nieuwe lagen toevoegen."
        ),
        Achievement(
            condition: manager.addedLayer,
            tooltip: "Als je een nieuwe laag toevoegt, kan je hier een heel liedje opnemen."
        ),
        Achievement(
            condition:manager.firstAudioPlayerRec.Stream != null, 
            tooltip: "Een kadotje van mij! neem met deze 🎤 microfoon een kort hard geluid op hem te gebruiken als instrument in de ring."
        ),
        Achievement(
            condition:manager.secondAudioPlayerRec.Stream != null, 
            tooltip: "Kan je hier voor mij een kort gek geluid opnemen?"
        )
        
    ];

    static void SetupDefaultUserInterfaceState()
    {
        manager.SetRingVisibility(2, false);
        manager.SetRingVisibility(3, false);
        manager.layerVoiceOver1.bigLine.Visible = false;
    }

    static bool pauseBetweenSynthUnlock()
    {
        if (manager.layerVoiceOver0.GetCurrentLayerVoiceOver() != null)
        {
            if (timer == null)
            {
                GD.Print("create timer pausing");
                timer = manager.GetTree().CreateTimer(3);
                timer.Timeout += onTimeOut;
            }
           
            if (!paused)
            {
                return true;
            }
            
        }
        return false;
    }

    static void onTimeOut()
    {
        paused = false;
    }

    // helper for default tuple values
    static (bool condition, string tooltip, float worth, Action result) Achievement(string tooltip, float worth = -1,
        bool condition = true, Action result = null) => (condition, tooltip, worth, result);

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
        if (!useAchievements) return;

        // node positions deltas why??
        //for (int i = 0; i < nodes.Length; i++) FindBlocker(nodes[i]).GlobalPosition = WorldToUI(nodes[i].GlobalPosition) - FindBlocker(nodes[i]).Size / 2 * FindBlocker(nodes[i]).Scale;

        // if node state is locked make node disabled and make node have a locked icon
        for (int i = 0; i < nodes.Length; i++)
        {
            var node = nodes[i];
            var condition = achievements[i].condition;
            var worth = achievements[i].worth;
            var result = achievements[i].result;
            var useworth = worth != -1 && worth > 0;
            var enoughworth = manager.progressBarValue > worth;
            var blocker = FindBlocker(node);
            if (blocker.Visible && condition)
            {
                if (!useworth)
                {
                    SetBlockerState(blocker, false);
                    manager.PlayExtraSFX(manager.achievement_sfx);
                    result?.Invoke();
                    manager.EmitSignal("OnAchievementDone", i);
                }
                else
                {
                    if (enoughworth && blocker.pressed)
                    {
                        SetBlockerState(blocker, false);
                        manager.progressBarValue -= worth;
                        if (manager.progressBarValue < 0) manager.progressBarValue = 0;
                        manager.PlayExtraSFX(manager.achievement_sfx);
                        result?.Invoke();
                        manager.EmitSignal("OnAchievementDone", i);
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
                         
                           if (!allowedToSpeak(blocker)) return;
                            if (manager.achievementspanel.Visible) CloseTooltip();

                            OpenTooltip(node);
                            StartLoopToCheckIfTooltipCanClose();
                        }
                    }
                };
            }

            // disable some uit elements by default
            SetupDefaultUserInterfaceState();
            GD.Print("done late ready true");
            doneLateReady = true;
        }
    }

    private static bool allowedToSpeak(Blocker _blocker)
    {
        for (int i = 0; i < nodes.Length; i++)
        {
           
            var node = nodes[i];
            var blocker = FindBlocker(node);
            var worth = achievements[i].worth;
            var useworth = worth != -1 && worth > 0;
            var enoughworth = manager.progressBarValue > worth;
            if (blocker == _blocker)
            {
                if (useworth && enoughworth)
                {
                    GD.Print(_blocker.Name);
                    GD.Print("Not allowed to speak");
                    return false;
                }
            }
        }

        return true;
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

    public static void unlockAchievement()
    {
        for (int i = 0; i < nodes.Length; i++)
        {
            SetBlockerState(FindBlocker(nodes[i]), false);
        }
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