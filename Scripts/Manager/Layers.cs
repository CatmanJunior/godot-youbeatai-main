using Godot;
using System.Collections.Generic;
using System.Linq;

public partial class Manager : Node
{
    public int currentLayerIndex = 0; // the currently active layer (the layer displayed on screen)
    public int layersAmount = 0; // the current amount of layers in the game
    public const int layersAmountMax = 10; // the maximum allowed amount of layers that can be created
    public const int layersAmountInitial = 4; // the initial amount of layers the game starts with
    public const int layersButtonsSize = 72; // the size of each layer button

    public List<bool[,]> layersBeatActives = []; // the actual interal data structure of the layers (ground truth)
    List<Button> LayerButtons = []; // buttons that represent each layer (they work like tabs in chrome. can be added/removed/reordered)

    public List<AudioStream> layersVoiceOvers0 => layerVoiceOver0.layersVoiceOvers;
    public List<AudioStream> layersVoiceOvers1 => layerVoiceOver1.layersVoiceOvers;

    public void SpawnInitialLayerButtons()
    {
        for (int i = 0; i < layersAmountInitial; i++) AddLayer(i);
        SwitchLayerNextFrame(0);
    }

    public void AddLayer(int layer, string emoji = null) // adds a layer at the end of the list of layers
    {
        if (layersAmount == layersAmountMax) return;

        layersAmount++;
        NewLayerButton(layer, emoji);

        layersBeatActives.Insert(layer, new bool[4, BpmManager.beatsAmount]);
        layersVoiceOvers0.Insert(layer, null);
        layersVoiceOvers1.Insert(layer, null);
        SamplesMixing_knobPositions.Insert(layer, GetStandardKnobPositionsSamples());
        SynthMixing_knobPositions.Insert(layer, GetStandardKnobPositionsSynth());
        EmitSignal(SignalName.OnAddLayerEvent, layersBeatActives.IndexOf(layersBeatActives.Last()));

        SortLayerButtonsInContainerBasedOnTheirIndex();
        UpdateLayerButtonsUserInterface();

        SwitchLayerNextFrame(layer);

        // inset silence into song covering the length of this new layer
        if (SongVoiceOver.instance?.voiceOver != null) AudioSaving.InsertSilentLayerPartOfRecordings(currentLayerIndex + 1);
    }

    public void SortLayerButtonsInContainerBasedOnTheirIndex()
    {
        var buttons = new List<Button>();
        var children = layerButtonsContainer.GetChildren();
        foreach (var child in children) if (child is Button button) buttons.Add(button);

        // sort buttons based on their index
        buttons.Sort((a, b) => LayerButtons.IndexOf(a).CompareTo(LayerButtons.IndexOf(b)));

        // move the children to the correct order
        for (int i = 0; i < buttons.Count; i++) layerButtonsContainer.MoveChild(buttons[i], i);
    }

    public async void RemoveLayer(int layer) // removes a layer by specific index (can be a layer in between other layers)
    {
        if (layersAmount <= 1) return;

        // remove part of song that is on this layer
        if (SongVoiceOver.instance.voiceOver != null) AudioSaving.RemoveLayerPartOfRecordings(currentLayerIndex);

        RemoveLayerButton(layer); // destroy the layer button
        await ToSignal(GetTree(), "process_frame");

        layersBeatActives.RemoveAt(layer); // destroy the internal layer data
        layersVoiceOvers0.RemoveAt(layer);
        layersVoiceOvers1.RemoveAt(layer);
        SamplesMixing_knobPositions.RemoveAt(layer);
        SynthMixing_knobPositions.RemoveAt(layer);
        EmitSignal(SignalName.OnRemoveLayerEvent, layer);
        layersAmount--;

        // if the layer being deleted was the current active layer then go to first layer
        if (layer == currentLayerIndex) SwitchLayer(0, false);
    }

    public Button NewLayerButton(int layer, string emoji = null)
    {
        var layerButton = (Button)layerButtonPrefab.Instantiate();
        LayerButtons.Insert(layer, layerButton);
        layerButtonsContainer.AddChild(layerButton);

        if (emoji != null) layerButton.Text = emoji;
        else
        {
            string[] options = ["🌱", "📜", "🤩", "🏁"];
            layerButton.Text = options[layer];
        }

        layerButton.Pressed += () =>
        {
            anyLayerButtonHasBeenPressed = true;
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
        layerButtonsContainer.Position = new Vector2(-layerButtonsContainer.Size.X / 2, layerButtonsContainer.Position.Y);

        // transform outlineholder
        layerOutlineHolder.GlobalPosition = LayerButtons[currentLayerIndex].GlobalPosition + new Vector2(layersButtonsSize, layersButtonsSize) / 2;

        // transform songmode backpanel
        if (songModeBackPanel != null)
        {
            var backPanelOverSize = new Vector2(16, 8);
            songModeBackPanel.Size = layerButtonsContainer.Size + backPanelOverSize;
            songModeBackPanel.Position = layerButtonsContainer.Position - backPanelOverSize / 2;
        }

        // set proper color of layer buttons
        for (int i = 0; i < LayerButtons.Count; i++)
        {
            LayerButtons[i].SelfModulate = colors[6];
        }
    }

    public void UpdateLayerButtonsUserInterfaceDelayed() => GetTree().CreateTimer(0.2).Timeout += UpdateLayerButtonsUserInterface;

    public void SwitchLayer(int layerIndex, bool saveLayerFirst = true)
    {
        // change layer
        if (saveLayerFirst)
        {
            SetCurrentLayer(beatActives);

            if (chaosPadMode == ChaosPadMode.SampleMixing) SamplesMixing_StoreActiveKnob();
            if (chaosPadMode == ChaosPadMode.SynthMixing) SynthMixing_StoreActiveKnob();
            if (chaosPadMode == ChaosPadMode.SongMixing) SongMixing_StoreActiveKnob();
        }
        currentLayerIndex = layerIndex;
        beatActives = GetCurrentLayer();

        if (chaosPadMode == ChaosPadMode.SampleMixing) SamplesMixing_RetrieveActiveKnob();
        if (chaosPadMode == ChaosPadMode.SynthMixing) SynthMixing_RetrieveActiveKnob();
        if (chaosPadMode == ChaosPadMode.SongMixing) SongMixing_RetrieveActiveKnob();

        // do stuff with new layer
        EmitSignal(SignalName.OnSwitchLayer, currentLayerIndex);
        layerVoiceOver0.SetSmallVolumeline();
        layerVoiceOver1.SetSmallVolumeline();
        layerVoiceOver0.SetBigVolumeline();
        layerVoiceOver1.SetBigVolumeline();
        UpdateSongVoiceOverPlayBackPosition();
        UpdateLayerButtonsUserInterface();

        Manager.instance.showTemplate = false;
    }

    public async void SwitchLayerNextFrame(int layerIndex, bool saveLayerFirst = true)
    {
        // wait one frame
        await ToSignal(GetTree(), "process_frame");

        // switch layer
        SwitchLayer(layerIndex, saveLayerFirst);
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