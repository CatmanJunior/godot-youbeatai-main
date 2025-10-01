using Godot;

public partial class Manager : Node
{
    public AudioStreamPlayer2D firstAudioPlayer;
    public AudioStreamPlayer2D secondAudioPlayer;
    public AudioStreamPlayer2D thirdAudioPlayer;
    public AudioStreamPlayer2D fourthAudioPlayer;
    public AudioStreamPlayer2D firstAudioPlayerAlt;
    public AudioStreamPlayer2D secondAudioPlayerAlt;
    public AudioStreamPlayer2D thirdAudioPlayerAlt;
    public AudioStreamPlayer2D fourthAudioPlayerAlt;
    public AudioStreamPlayer2D firstAudioPlayerRec;
    public AudioStreamPlayer2D secondAudioPlayerRec;
    public AudioStreamPlayer2D thirdAudioPlayerRec;
    public AudioStreamPlayer2D fourthAudioPlayerRec;
    public AudioStreamPlayer2D sfxAudioPlayer;

    private void InitAllAudioPlayers()
    {
        // init audioplayers
        sfxAudioPlayer = new AudioStreamPlayer2D();
        AddChild(sfxAudioPlayer);
        firstAudioPlayer = new AudioStreamPlayer2D();
        secondAudioPlayer = new AudioStreamPlayer2D();
        thirdAudioPlayer = new AudioStreamPlayer2D();
        fourthAudioPlayer = new AudioStreamPlayer2D();
        AddChild(firstAudioPlayer);
        AddChild(secondAudioPlayer);
        AddChild(thirdAudioPlayer);
        AddChild(fourthAudioPlayer);
        firstAudioPlayerAlt = new AudioStreamPlayer2D();
        secondAudioPlayerAlt = new AudioStreamPlayer2D();
        thirdAudioPlayerAlt = new AudioStreamPlayer2D();
        fourthAudioPlayerAlt = new AudioStreamPlayer2D();
        AddChild(firstAudioPlayerAlt);
        AddChild(secondAudioPlayerAlt);
        AddChild(thirdAudioPlayerAlt);
        AddChild(fourthAudioPlayerAlt);
        firstAudioPlayerRec = new AudioStreamPlayer2D();
        secondAudioPlayerRec = new AudioStreamPlayer2D();
        thirdAudioPlayerRec = new AudioStreamPlayer2D();
        fourthAudioPlayerRec = new AudioStreamPlayer2D();
        AddChild(firstAudioPlayerRec);
        AddChild(secondAudioPlayerRec);
        AddChild(thirdAudioPlayerRec);
        AddChild(fourthAudioPlayerRec);
        firstAudioPlayer.Stream = mainAudioFiles[0];
        secondAudioPlayer.Stream = mainAudioFiles[1];
        thirdAudioPlayer.Stream = mainAudioFiles[2];
        fourthAudioPlayer.Stream = mainAudioFiles[3];
        firstAudioPlayerAlt.Stream = mainAudioFilesAlt[0];
        secondAudioPlayerAlt.Stream = mainAudioFilesAlt[1];
        thirdAudioPlayerAlt.Stream = mainAudioFilesAlt[2];
        fourthAudioPlayerAlt.Stream = mainAudioFilesAlt[3];
        firstAudioPlayer.Bus = "Beats";
        secondAudioPlayer.Bus = "Beats";
        thirdAudioPlayer.Bus = "Beats";
        fourthAudioPlayer.Bus = "Beats";
        firstAudioPlayerAlt.Bus = "Beats";
        secondAudioPlayerAlt.Bus = "Beats";
        thirdAudioPlayerAlt.Bus = "Beats";
        fourthAudioPlayerAlt.Bus = "Beats";
        firstAudioPlayerRec.Bus = "Beats";
        secondAudioPlayerRec.Bus = "Beats";
        thirdAudioPlayerRec.Bus = "Beats";
        fourthAudioPlayerRec.Bus = "Beats";

        EmitSignal(SignalName.SetGreenSynth, bank.green_soundfont, bank.green_instrument_id);
		EmitSignal(SignalName.SetPurpleSynth, bank.purple_soundfont, bank.purple_instrument_id);
    }
}