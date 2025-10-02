using Godot;
using System.Collections.Generic;

public partial class Manager : Node
{
    public int layersAmount = 0;
    public const int layersAmountMax = 10;
    public const int layersAmountInitial = 3;
    public const int layersButtonsSize = 72;
    public int currentLayerIndex = 0;

    public List<bool[,]> layersBeatActives = [];

    public void SpawnInitialLayerButtons()
    {
        for (int i = 0; i < layersAmountInitial; i++) AddLayer();
        layerOutlineHolder.GlobalPosition = LayerButtons[currentLayerIndex].GlobalPosition + LayerButtons[currentLayerIndex].Size / 2 + new Vector2(1, 0);
    }

    public void AddLayer()
    {
        if (layersAmount == layersAmountMax) return;
        layersAmount++;
        NewLayerButton();
        layersBeatActives.Add(new bool[4, BpmManager.beatsAmount]);

        // transform container
        layerButtonsContainer.Size = new Vector2(layerButtonsContainer.GetChildCount() * layersButtonsSize, layersButtonsSize);
        layerButtonsContainer.GlobalPosition = new Vector2(-layerButtonsContainer.Size.X / 2, layerButtonsContainer.GlobalPosition.Y);

        // transform addlayerbutton
        addLayerButton.Size = layersButtonsSize * Vector2.One;
        if (layersAmount < layersAmountMax) addLayerButton.GlobalPosition = new (layerButtonsContainer.Size.X / 2 + 4, layerButtonsContainer.GlobalPosition.Y);
        else addLayerButton.GlobalPosition = new Vector2(9999, 9999);

        // transform outlineholder
        layerOutlineHolder.GlobalPosition = LayerButtons[currentLayerIndex].GlobalPosition + LayerButtons[currentLayerIndex].Size / 2 + new Vector2(1, 0);
    }

    public Button NewLayerButton()
    {
        var layerButton = (Button)layerButtonPrefab.Instantiate();
        LayerButtons.Add(layerButton);
        layerButtonsContainer.AddChild(layerButton);
        int index = LayerButtons.IndexOf(layerButton);

        layerButton.Pressed += () => { SwitchLayer(index + 1); UpdateSongVoiceOverPlayBackPosition(); SetCopyPasteClearButtonsActive(true);};
        
        return layerButton;
    }

    public bool[,] GetCurrentLayer() => layersBeatActives[currentLayerIndex];
    public bool[,] SetCurrentLayer(bool[,] value) => layersBeatActives[currentLayerIndex] = value;
    public void NextLayer()
    {
        if (currentLayerIndex == layersAmount - 1) SwitchLayer(1);
        else SwitchLayer(currentLayerIndex + 2);
    }
    public void PreviousLayer()
    {
        if (currentLayerIndex == 0) SwitchLayer(layersAmount);
        else SwitchLayer(currentLayerIndex);
    }

    public void SwitchLayer(int layerToUse)
    {
        SamplesMixing_RememberKnobsForLayer();
        SetCurrentLayer(beatActives);
        currentLayerIndex = layerToUse - 1;
        beatActives = GetCurrentLayer();
        layerOutlineHolder.GlobalPosition = LayerButtons[currentLayerIndex].GlobalPosition + LayerButtons[currentLayerIndex].Size / 2 + new Vector2(1, 0);
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
        var timeperlayer = SongVoiceOver.instance.recordingLength / layersAmount;
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