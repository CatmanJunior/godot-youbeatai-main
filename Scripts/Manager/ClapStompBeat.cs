using Godot;

using System;
using System.Data.Common;

public partial class Manager : Node
{
    public bool stomped = false;
    public bool clapped = false;
    public int clappedAmount = 0;
    public int clappedOnBeatAmount = 0;
    public int stompedAmount = 0;
    public int stompedOnBeatAmount = 0;

    private void CheckIfClappingOrStomping()
    {
        // check clap and stomp
        var volume = MicrophoneCapture.instance.volume;
        var frequency = MicrophoneCapture.instance.frequency;

        var treshold = volume_treshold.Value;
        var shouldclap = volume > treshold && frequency > ClapBiasSlider.Value;
        if (MicrophoneCapture.instance.IsClapping || Input.IsKeyPressed(Key.N))
        {
            if (!clapped)
            {
                if (!emailPromptOpen) OnClap();
                clapped = true;
            }
        }

        bool shouldstomp = volume > treshold && frequency < ClapBiasSlider.Value;
        if (MicrophoneCapture.instance.IsStamping || Input.IsKeyPressed(Key.M))
        {
            if (!stomped)
            {
                if (!emailPromptOpen) OnStomp();
                stomped = true;
            }
        }
    }

    public void OnClap()
    {
        if (timeafterplay < 0.2f) return;
        int ring = 1;
        bool active = beatActives[ring, BpmManager.instance.currentBeat];
        var sprite = beatSprites[ring, BpmManager.instance.currentBeat];
        if (active)
        {
            sprite.Scale += Vector2.One / 5;
            if (sprite.Scale.X > 3) sprite.Scale = Vector2.One * 3;
            progressBarValue += 2f;
            EmitProgressBarParticles();
            EmitBeatParticles(beatSprites[ring, BpmManager.instance.currentBeat].Position, colors[ring]);
            clappedOnBeatAmount++;
        }
        else
        {
            progressBarValue -= 1f;
        }
        clappedAmount++;
        draganddropButton1.Scale += Vector2.One / 10;
        if (draganddropButton1.Scale.X > 4) draganddropButton1.Scale = Vector2.One * 4;

        if (add_beats.ButtonPressed) ((DragAndDropButton)draganddropButton1).ButtonBehaviour();
    }

    public void OnStomp()
    {
        if (timeafterplay < 0.2f) return;
        int ring = 0;
        bool active = beatActives[ring, BpmManager.instance.currentBeat];
        var sprite = beatSprites[ring, BpmManager.instance.currentBeat];
        if (active)
        {
            sprite.Scale += Vector2.One / 5;
            if (sprite.Scale.X > 3) sprite.Scale = Vector2.One * 3;
            progressBarValue += 2f;
            EmitProgressBarParticles();
            EmitBeatParticles(beatSprites[ring, BpmManager.instance.currentBeat].Position, colors[ring]);
            stompedOnBeatAmount++;
        }
        else
        {
            progressBarValue -= 1f;
        }
        stompedAmount++;
        draganddropButton0.Scale += Vector2.One / 10;
        if (draganddropButton0.Scale.X > 4) draganddropButton0.Scale = Vector2.One * 4;

        if (add_beats.ButtonPressed) ((DragAndDropButton)draganddropButton0).ButtonBehaviour();

    }

    public void OnBeat()
    {
        if (metronome_sfx_enabled)
        {
            int beatsPerQuarter = BpmManager.beatsAmount / 4;
            if (BpmManager.instance.currentBeat % beatsPerQuarter == 0)
            {
                bool reatime_rec = RealTimeAudioRecording.instance.shouldRecord || RealTimeAudioRecording.instance.shouldRecord;
                bool layer_rec0 = layerVoiceOver0.shouldRecord || layerVoiceOver0.shouldRecord;
                bool layer_rec1 = layerVoiceOver1.shouldRecord || layerVoiceOver1.shouldRecord;
                bool song_rec = SongVoiceOver.instance.shouldRecord || RealTimeAudioRecording.instance.shouldRecord;

                if (reatime_rec || layer_rec0 || layer_rec1 || song_rec)
                {
                    if (BpmManager.instance.currentBeat != 0)
                    {
                        PlayExtraSFX(metronome_sfx);
                    }
                    else
                    {
                        GD.Print("skip top tic");
                    }
                }
                else // normal
                {
                    PlayExtraSFX(metronome_sfx);
                }
            }
        }

        if (beatActives[0, BpmManager.instance.currentBeat]) firstAudioPlayer.Play();
        if (beatActives[1, BpmManager.instance.currentBeat]) secondAudioPlayer.Play();
        if (beatActives[2, BpmManager.instance.currentBeat]) thirdAudioPlayer.Play();
        if (beatActives[3, BpmManager.instance.currentBeat]) fourthAudioPlayer.Play();

        if (beatActives[0, BpmManager.instance.currentBeat]) firstAudioPlayerAlt.Play();
        if (beatActives[1, BpmManager.instance.currentBeat]) secondAudioPlayerAlt.Play();
        if (beatActives[2, BpmManager.instance.currentBeat]) thirdAudioPlayerAlt.Play();
        if (beatActives[3, BpmManager.instance.currentBeat]) fourthAudioPlayerAlt.Play();

        if (beatActives[0, BpmManager.instance.currentBeat] && firstAudioPlayerRec.Stream != null) firstAudioPlayerRec.Play();
        if (beatActives[1, BpmManager.instance.currentBeat] && secondAudioPlayerRec.Stream != null) secondAudioPlayerRec.Play();
        if (beatActives[2, BpmManager.instance.currentBeat] && thirdAudioPlayerRec.Stream != null) thirdAudioPlayerRec.Play();
        if (beatActives[3, BpmManager.instance.currentBeat] && fourthAudioPlayerRec.Stream != null) fourthAudioPlayerRec.Play();

        clapped = false;
        stomped = false;

        if (layerLoopToggle.ButtonPressed || SongVoiceOver.instance.recording)
            if (BpmManager.instance.currentBeat == BpmManager.beatsAmount - 1) NextLayer();

        if (BpmManager.instance.currentBeat == 0)
        {
            layerVoiceOver0.OnTop();
            layerVoiceOver1.OnTop();

            // every loop also give energy
            if (progressBarValue < 50.0f) progressBarValue += 2.0f;
            else if (progressBarValue < 75.0f) progressBarValue += 1.0f;
            else if (progressBarValue < 90.0f) progressBarValue += 0.5f;
            else if (progressBarValue <= 999) progressBarValue -= 0.5f;

            if (!layerLoopToggle.ButtonPressed) UpdateSongVoiceOverPlayBackPosition();

            if (currentLayerIndex == 0)
            {
                RealTimeAudioRecording.instance.OnTop();
                SongVoiceOver.instance.OnTop();
            }
        }

        int nextbeat = BpmManager.instance.currentBeat + 1;
        if (nextbeat == BpmManager.beatsAmount) nextbeat = 0;

        bool clap_active = beatActives[1, nextbeat];
        if (clap_active) EmitSignal(SignalName.OnShouldClapEvent);

        bool stomp_active = beatActives[0, nextbeat];
        if (stomp_active) EmitSignal(SignalName.OnShouldStompEvent);

        float strength = 0.2f;
        float scale = 1f + ((Random.Shared.NextSingle() - 0.5f) * strength);
        fourthAudioPlayer.PitchScale = scale;
        fourthAudioPlayerAlt.PitchScale = scale;
        fourthAudioPlayerRec.PitchScale = scale;
    }
}