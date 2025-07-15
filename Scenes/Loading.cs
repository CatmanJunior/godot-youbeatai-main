using Godot;
using System;

public partial class Loading : Panel
{
    bool firstframedone = false;

    public override void _Process(double delta)
    {
        if (firstframedone) GetTree().ChangeSceneToFile("res://Scenes/main.tscn");
        else firstframedone = true;
    }
}