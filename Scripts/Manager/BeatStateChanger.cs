using System;
using Godot;

public class BeatStateChanger
{
    private static Manager manager => Manager.instance;
    private static bool[,] actives => manager.beatActives;

    private static float energy
    {
        get => manager.progressBarValue;
        set => manager.progressBarValue = value;
    }

    private static float[] costs = 
    [
        2.0f,
        2.0f,
        3.0f,
        1.0f,
    ];

    static void OpenTooltip(string text)
    {
        manager.achievementspanel.Visible = true;
        manager.InstructionLabel.Text = text;
        SpeakTooltip(text);
    }

    static void SpeakTooltip(string text)
    {
        if (manager.muteSpeach.ButtonPressed) return;
        var voices = DisplayServer.TtsGetVoicesForLanguage("nl");
        if (voices.Length == 0) voices = DisplayServer.TtsGetVoicesForLanguage("en");
        if (DisplayServer.TtsIsSpeaking()) DisplayServer.TtsStop();
        DisplayServer.TtsSpeak(text, voices[0], 100);
    }

    static void StartLoopToCheckIfTooltipCanClose()
    {
        if (manager == null) return;
        manager.GetTree().CreateTimer(0.4).Timeout += () =>
        {
            if (DisplayServer.TtsIsSpeaking()) StartLoopToCheckIfTooltipCanClose();
            else CloseTooltip();
        };
    }

    static void CloseTooltip()
    {
        manager.InstructionLabel.Text = "";
        manager.achievementspanel.Visible = false;
        if (DisplayServer.TtsIsSpeaking()) DisplayServer.TtsStop();
    }

    public static void SetBeat(int ring, int beat, bool value)
    {
        // return if beat is already that state
        if (actives[ring, beat] == value) return;

        float cost = costs[ring];

        // if you want beat to become active
        if (value)
        {
            // if enough money
            if (energy >= cost)
            {
                // change
                actives[ring, beat] = value;

                // take energy
                energy -= cost;

                // clamp
                if (energy < 0) energy = 0;
            }
            else
            {
                OpenTooltip("Speel nog wat muziek om me energie te geven!");
                StartLoopToCheckIfTooltipCanClose();
                return;
            }
        }
        else // if you want beat to become off
        {
            // change
            actives[ring, beat] = value;

            // return energy
            energy += cost;

            // clamp
            if (energy > 100) energy = 100;
        }
    }

    public static void ToggleBeat(int ring, int beat)
    {
        bool current = actives[ring, beat];
        SetBeat(ring, beat, !current);
    }

    public static void SetBeatFree(int ring, int beat, bool value)
    {
        // return if beat is already that state
        if (actives[ring, beat] == value) return;

        // change
        actives[ring, beat] = value;
    }

    public static void ToggleBeatFree(int ring, int beat)
    {
        bool current = actives[ring, beat];
        SetBeatFree(ring, beat, !current);
    }
}