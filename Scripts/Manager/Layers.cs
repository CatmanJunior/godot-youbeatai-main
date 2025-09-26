using Godot;
using System.Collections.Generic;

public partial class Manager : Node
{
    public int currentLayerIndex = 0;

    public List<bool[,]> layers = new()
    {
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount]
    };

    public bool[,] GetCurrentLayer() => layers[currentLayerIndex];
    public bool[,] SetCurrentLayer(bool[,] value) => layers[currentLayerIndex] = value;
    public void NextLayer()
    {
        if (currentLayerIndex == 9) SwitchLayer(1);
        else SwitchLayer(currentLayerIndex + 2);
    }
    public void PreviousLayer()
    {
        if (currentLayerIndex == 0) SwitchLayer(10);
        else SwitchLayer(currentLayerIndex);
    }

    public void SwitchLayer(int layerToUse)
    {
        SamplesMixing_RememberKnobsForLayer();
        SetCurrentLayer(beatActives);
        currentLayerIndex = layerToUse - 1;
        beatActives = GetCurrentLayer();
        layerOutlineHolder.Position = (layerButton1.Position + layerButton1.Size / 2 + new Vector2(1, 0)) + new Vector2(1, 0) * (71f * currentLayerIndex);
        EmitSignal(SignalName.OnSwitchLayer, currentLayerIndex);
        layerVoiceOver0.SetSmallVolumeline();
        layerVoiceOver1.SetSmallVolumeline();
        layerVoiceOver0.SetBigVolumeline();
        layerVoiceOver1.SetBigVolumeline();
        SamplesMixing_ReApplyKnobsForLayer();
    }

    public void UpdateSongVoiceOverPlayBackPosition()
    {
        if (SongVoiceOver.instance.voiceOver == null) return;
        if (SongVoiceOver.instance.audioPlayer.Playing == false) SongVoiceOver.instance.audioPlayer.Play();
        var timeperlayer = SongVoiceOver.instance.recordingLength / 10;
        var fixedcurrentbeat = BpmManager.instance.currentBeat;
        if (fixedcurrentbeat >= BpmManager.beatsAmount - 1) fixedcurrentbeat = 0;
        var timeperbeat = timeperlayer / BpmManager.beatsAmount;
        var beattimeoffset = timeperbeat * fixedcurrentbeat;
        var seekpos = currentLayerIndex * timeperlayer + beattimeoffset;
        SongVoiceOver.instance.audioPlayer.Seek(seekpos);
        GD.Print("seek song position to new position");
    }

    public bool LayerHasBeats(bool[,] layer)
    {
        for (int ring = 0; ring < 4; ring++)
        {
            for (int beat = 0; beat < BpmManager.beatsAmount; beat++)
            {
                bool active = layer[ring, beat];
                if (active) return true;
            }
        }
        return false;
    }
}