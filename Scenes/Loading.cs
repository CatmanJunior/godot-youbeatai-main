using Godot;
using System;

public partial class Loading : Panel
{
    bool firstframedone = false;

    public override async void _Process(double delta)
    {
        UpdateLoadingAnimation();

        if (!firstframedone)
        {
            firstframedone = true;
            return;
        }

        // cache tree
        var tree = GetTree();

        // load main scene async
        ResourceLoader.LoadThreadedRequest("res://Scenes/main.tscn");
        bool isloaded = ResourceLoader.LoadThreadedGetStatus("res://Scenes/main.tscn") == ResourceLoader.ThreadLoadStatus.Loaded;
        while (!isloaded) await ToSignal(tree, SceneTree.SignalName.ProcessFrame);

        // switch scene
        var packedScene = (PackedScene)ResourceLoader.LoadThreadedGet("res://Scenes/main.tscn");
        tree.ChangeSceneToPacked(packedScene);
    }

    private void UpdateLoadingAnimation()
    {
        // updates animation each frame
    }
}