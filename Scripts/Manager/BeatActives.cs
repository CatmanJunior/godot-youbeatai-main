using Godot;

public partial class Manager : Node
{
    public bool[,] beatActives = new bool[4, BpmManager.beatsAmount];
}