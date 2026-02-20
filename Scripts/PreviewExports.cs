using System;
using Godot;

public partial class PreviewExports : Node
{
    public static PreviewExports instance = null;

    [Export] public Button ListenSongExportButton;
    [Export] public Button ListenBeatExportButton;

    [Export] public AudioStreamPlayer audioPlayerSong;
    [Export] public AudioStreamPlayer audioPlayerBeat;

    public bool HasRecorded => RealTimeAudioRecording.instance.recording_result != null;

    public override void _Ready()
    {
        if (instance == null) instance = this;

        ListenSongExportButton.ButtonUp += () =>
        {
            if (!audioPlayerSong.Playing)
            {
                if (audioPlayerBeat.Playing) StopPlayingBeat();
                StartPlayingSong();
            }
            else
            {
                StopPlayingSong();
            }
        };

        ListenBeatExportButton.ButtonUp += () =>
        {
            if (!audioPlayerBeat.Playing)
            {
                if (audioPlayerSong.Playing) StopPlayingSong();
                StartPlayingBeat();
            }
            else
            {
                StopPlayingBeat();
            }
        };

        Manager.instance.settingsBackButton.ButtonUp += () =>
        {
            StopPlayingSong();
            StopPlayingBeat();
        };
    }

    void StopPlayingSong()
    {
        if (audioPlayerSong.Playing) audioPlayerSong.Stop();
    }

    void StopPlayingBeat()
    {
        if (audioPlayerBeat.Playing) audioPlayerBeat.Stop();
    }

    void StartPlayingSong()
    {
        var audioStreamWav = AudioStreamWav.LoadFromFile(AudioSaving.SaveRealTimeRecordedSongAsFile());
        audioPlayerSong.Stream = audioStreamWav;
        audioPlayerSong.Play();
    }

    void StartPlayingBeat()
    {
        var audioStreamWav = AudioStreamWav.LoadFromFile(AudioSaving.SaveRealTimeRecordedBeatAsFile());
        audioPlayerBeat.Stream = audioStreamWav;
        audioPlayerBeat.Play();
    }

    public override void _Process(double delta)
    {
        ListenSongExportButton.Disabled = !HasRecorded;
        ListenBeatExportButton.Disabled = !HasRecorded;

        Manager.instance.allLayersToMp3.Disabled = !HasRecorded;
        Manager.instance.saveToWavButton.Disabled = !HasRecorded;

        ListenSongExportButton.Text = audioPlayerSong.Playing ? "⏹️" : "▶️";
        ListenBeatExportButton.Text = audioPlayerBeat.Playing ? "⏹️" : "▶️";
    }

    public override void _ExitTree()
    {
        if (instance == this) instance = null;
    }
}