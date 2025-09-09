using Godot;

public partial class Manager : Node
{
    [Export] public AudioStream[] mainAudioFiles;
    [Export] public AudioStream[] mainAudioFilesAlt;
    [Export] public AudioStream metronome_sfx;
    [Export] AudioStream metronomealt_sfx;
    [Export] public AudioStream achievement_sfx;
}