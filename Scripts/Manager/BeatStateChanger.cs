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
                TooltipHelper.OpenTooltip("Speel nog wat muziek om me energie te geven!");
                TooltipHelper.StartLoopToCheckIfTooltipCanClose();
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