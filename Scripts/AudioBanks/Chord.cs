using Godot;
using System;

public enum ChordType {
    MAJOR,
    MINOR,
    SEVEN,
    MAJOR7,
    MINOR7
}

[GlobalClass]
public partial class Chord : Resource
{
    [Export] public int base_note;
    [Export] public ChordType type;
}
