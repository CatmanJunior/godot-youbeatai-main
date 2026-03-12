using Godot;
using System;

[GlobalClass]
public partial class ChordProgression : Resource
{
    [Export] public Chord[] progression { get; set; }
}
