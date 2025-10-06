using Godot;
using System;
using System.Collections.Generic;

public partial class Manager : Node
{
    public int currentLayerIndex = 0; // the currently active layer (the layer displayed on screen)
    public int layersAmount = 0; // the current amount of layers in the game
    public const int layersAmountMax = 10; // the maximum allowed amount of layers that can be created
    public const int layersAmountInitial = 3; // the initial amount of layers the game starts with
    public const int layersButtonsSize = 72; // the size of each layer button

    public List<bool[,]> layersBeatActives = []; // the actual interal data structure of the layers (ground truth)
    List<Button> LayerButtons = []; // buttons that represent each layer (they work like tabs in chrome. can be added/removed/reordered)

    public void SpawnInitialLayerButtons()
    {
        for (int i = 0; i < layersAmountInitial; i++) AddLayer();
    }

    public void AddLayer(string emoji = null) // adds a layer at the end of the list of layers
    {
        if (layersAmount == layersAmountMax) return;

        layersAmount++;
        NewLayerButton(emoji);
        layersBeatActives.Add(new bool[4, BpmManager.beatsAmount]);

        UpdateLayerButtonsUserInterface();
    }

    public async void RemoveLayer(int layer) // removes a layer by specific index (can be a layer in between other layers)
    {
        if (layersAmount <= 1) return;

        RemoveLayerButton(layer); // destroy the layer button
        await ToSignal(GetTree(), "process_frame");

        layersBeatActives.RemoveAt(layer); // destroy the internal layer data
        layersAmount--;

        // if the layer being deleted was the current active layer then go to first layer
        if (layer == currentLayerIndex) SwitchLayer(0, false);
    }

    public Button NewLayerButton(string emoji = null)
    {
        var layerButton = (Button)layerButtonPrefab.Instantiate();
        LayerButtons.Add(layerButton);
        layerButtonsContainer.AddChild(layerButton);

        if (emoji != null) layerButton.Text = emoji;
        else
        {
            var random = new Random();
            var index = random.Next(0, 4);
            string[] options = ["🌱", "📜", "🤩", "😀", "🏁"];
            layerButton.Text = options[index];
        }

        layerButton.Pressed += () =>
        {
            int layerIndex = LayerButtons.IndexOf(layerButton);
            SwitchLayer(layerIndex);
            SetCopyPasteClearButtonsActive(true);
        };

        return layerButton;
    }

    public void RemoveLayerButton(int layer)
    {
        if (layer < 0 || layer > LayerButtons.Count - 1) return;

        var buttonToRemove = LayerButtons[layer];
        layerButtonsContainer.RemoveChild(buttonToRemove);
        buttonToRemove.QueueFree();
        LayerButtons.Remove(buttonToRemove);
    }

    public void UpdateLayerButtonsUserInterface()
    {
        // transform container
        layerButtonsContainer.Size = new Vector2(layerButtonsContainer.GetChildCount() * layersButtonsSize, layersButtonsSize);
        layerButtonsContainer.GlobalPosition = new Vector2(-layerButtonsContainer.Size.X / 2, layerButtonsContainer.GlobalPosition.Y);

        // transform addlayerbutton
        addLayerButton.Size = layersButtonsSize * Vector2.One;
        if (layersAmount < layersAmountMax) addLayerButton.GlobalPosition = new (layerButtonsContainer.Size.X / 2 + 4, layerButtonsContainer.GlobalPosition.Y);
        else addLayerButton.GlobalPosition = new Vector2(9999, 9999);

        // transform outlineholder
        layerOutlineHolder.GlobalPosition = LayerButtons[currentLayerIndex].GlobalPosition + new Vector2(layersButtonsSize, layersButtonsSize) / 2;

        // transform songmode backpanel
        var backPanelOverSize = new Vector2(16, 8);
        songModeBackPanel.Size = layerButtonsContainer.Size + backPanelOverSize;
        songModeBackPanel.GlobalPosition = layerButtonsContainer.GlobalPosition - backPanelOverSize / 2;
    }

    public void SwitchLayer(int layerIndex, bool saveLayerFirst = true)
    {
        // do stuff with old layer
        SamplesMixing_RememberKnobsForLayer();

        // change layer
        if (saveLayerFirst) SetCurrentLayer(beatActives);
        currentLayerIndex = layerIndex;
        beatActives = GetCurrentLayer();
        
        // do stuff with new layer
        EmitSignal(SignalName.OnSwitchLayer, currentLayerIndex);
        layerVoiceOver0.SetSmallVolumeline();
        layerVoiceOver1.SetSmallVolumeline();
        layerVoiceOver0.SetBigVolumeline();
        layerVoiceOver1.SetBigVolumeline();
        SamplesMixing_ReApplyKnobsForLayer();
        UpdateSongVoiceOverPlayBackPosition();
        UpdateLayerButtonsUserInterface();
    }

    public bool[,] GetCurrentLayer() => layersBeatActives[currentLayerIndex];
    public bool[,] SetCurrentLayer(bool[,] value) => layersBeatActives[currentLayerIndex] = value;
    public void NextLayer()
    {
        if (currentLayerIndex == layersAmount - 1) SwitchLayer(0);
        else SwitchLayer(currentLayerIndex + 1);
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