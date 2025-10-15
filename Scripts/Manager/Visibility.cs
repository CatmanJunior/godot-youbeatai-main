using Godot;

public partial class Manager : Node
{
    public void SetEntireInterfaceVisibility(bool visible)
    {
        SetRingVisibility(0, visible);
        SetRingVisibility(1, visible);
        SetRingVisibility(2, visible);
        SetRingVisibility(3, visible);
        progressBar.Visible = false; // temp fix
        PlayPauseButton.Visible = visible;
        SetMainButtonsVisibility(visible);
        SetRecordingButtonsVisibility(visible);
        SetDragAndDropButtonsVisibility(visible);
        SetLayerSwitchButtonsVisibility(visible);
        settingsButton.Visible = visible;
        layerLoopToggle.Visible = visible;
        muteSpeach.Visible = visible;
        cross.Visible = visible;
        bpmLabel.Visible = visible;
        metronome.Visible = visible;
        metronomebg.Visible = visible;
        chosen_emoticons_label.Visible = visible;
        achievementspanel.Visible = visible;
        SongVoiceOver.instance.recordSongButton.Visible = visible;
        RealTimeAudioRecording.instance.recordSongButton.Visible = visible;
        SongVoiceOver.instance.recordSongSprite.Visible = visible;
        RealTimeAudioRecording.instance.recordSongSprite.Visible = visible;
        SongVoiceOver.instance.progressbar.Visible = visible;
        RealTimeAudioRecording.instance.progressbar.Visible = visible;
        ((Sprite2D)layerVoiceOver0.recordLayerButton.GetParent()).Visible = visible;
        ((Sprite2D)layerVoiceOver1.recordLayerButton.GetParent()).Visible = visible;
        layerVoiceOver0.textureProgressBar.Visible = visible;
        layerVoiceOver1.textureProgressBar.Visible = visible;
        chaosPadTriangleSprite.Visible = visible;
        activateGreenChaosButton.Visible = visible;
        activatePurpleChaosButton.Visible = visible;
        layerVoiceOver0.bigLine.Visible = visible;
        layerVoiceOver1.bigLine.Visible = visible;
        layerButtonsContainer.Visible = visible;
    }

    public void SetGreenLayerVisibility(bool visible)
    {
        
        layerVoiceOver0.textureProgressBar.Visible = visible;
        activateGreenChaosButton.Visible = visible;
        layerVoiceOver0.bigLine.Visible = visible;
    }

    public void SetMicRecorderVisibility(bool visible)
    {
        ((Sprite2D)layerVoiceOver0.recordLayerButton.GetParent()).Visible = visible;
    }

    public void SetRingVisibility(int ring, bool visible)
    {
        for (int beat = 0; beat < BpmManager.beatsAmount; beat++) beatSprites[ring, beat].Visible = visible;
        for (int beat = 0; beat < BpmManager.beatsAmount; beat++) beatOutlines[ring, beat].Visible = visible;
        for (int beat = 0; beat < BpmManager.beatsAmount; beat++) templateSprites[ring, beat].Visible = visible;
    }

    public void SetMainButtonsVisibility(bool visible)
    {
        SaveLayoutButton.Visible = visible;
        LoadLayoutButton.Visible = visible;
        ClearLayoutButton.Visible = visible;
    }

    void SetEffectButtonsVisibility(bool visible)
    {
        BpmUpButton.Visible = visible;
        BpmDownButton.Visible = visible;
        bpmLabel.Visible = visible;
        swingslider.Visible = visible;
        swinglabel.Visible = visible;
        metronome.Visible = visible;
        metronomebg.Visible = visible;
        ReverbDelayManager.instance.reverbSlider.Visible = visible;
        ReverbDelayManager.instance.delaySlider.Visible = visible;
    }

    public void SetRecordingButtonsVisibility(bool visible)
    {
        recordSampleButton0.Visible = visible;
        recordSampleButton1.Visible = visible;
        recordSampleButton2.Visible = visible;
        recordSampleButton3.Visible = visible;
    }

    public void SetDragAndDropButtonsVisibility(bool visible)
    {
        draganddropButton0.Visible = visible;
        draganddropButton1.Visible = visible;
        draganddropButton2.Visible = visible;
        draganddropButton3.Visible = visible;
    }

    public void SetStompVisibility(bool visible)
    {
        draganddropButton0.Visible = visible;
    }

    public void SetClapVisibility(bool visible)
    {
        draganddropButton1.Visible = visible;
    }

    public void SetLayerSwitchButtonsVisibility(bool visible)
    {
        for (int i = 0; i < LayerButtons.Count; i++)
		{
			LayerButtons[i].Visible = visible;
        }
        
        layerOutline.Visible = visible;
    }

    public void SetLayerSwitchButtonsEnabled(bool enabled)
    {
        for (int i = 0; i < LayerButtons.Count; i++)
		{
			LayerButtons[i].Disabled = !enabled;
        }
    }

    private void UpdateAchievementsVisibility()
    {
        for (int i = 0; i < 6; i++)
        {
            float tresh = ((float)i + 1f) / 6f * 100f;
            if (progressBarValue > tresh - layersAmountMax)
            {
                Unlockables[i].Visible = true;
                UnlockablesQuestion[i].Visible = false;
            }
            else
            {
                Unlockables[i].Visible = false;
                UnlockablesQuestion[i].Visible = true;
            }
        }
    }
}