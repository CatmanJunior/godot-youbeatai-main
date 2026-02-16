using System;
using Godot;

public static class TooltipHelper
{
    static Manager manager => Manager.instance;

    public static void OpenTooltip(string text)
    {
        manager.achievementspanel.Visible = true;
        manager.InstructionLabel.Text = text;
        SpeakTooltip(text);
    }

    public static void SpeakTooltip(string text)
    {
        if (manager.muteSpeach.ButtonPressed) return;
        var voices = DisplayServer.TtsGetVoicesForLanguage("nl");
        if (voices.Length == 0) voices = DisplayServer.TtsGetVoicesForLanguage("en");
        if (DisplayServer.TtsIsSpeaking()) DisplayServer.TtsStop();
        DisplayServer.TtsSpeak(text, voices[0], 100);
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

    public static void CloseTooltip()
    {
        manager.InstructionLabel.Text = "";
        manager.achievementspanel.Visible = false;
        if (DisplayServer.TtsIsSpeaking()) DisplayServer.TtsStop();
    }
}