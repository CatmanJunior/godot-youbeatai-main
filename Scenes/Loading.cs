using Godot;
using System;

public partial class Loading : Panel
{
    bool firstframedone = false;
    bool startedloading = false;

    public override void _Process(double delta)
    {
        UpdateLoadingAnimation();

        if (firstframedone)
        {
            if (!startedloading)
            {
                StartAsyncLoad();
                startedloading = true;
            }
        }
        else
        {
            firstframedone = true;
        }
    }

    async void StartAsyncLoad()
    {
        var tree = GetTree();

        // start the async loading
        ResourceLoader.LoadThreadedRequest("res://Scenes/main.tscn");

        // loop to check if loading async is done
        bool isloaded = false;
        while (!isloaded)
        {
            isloaded = ResourceLoader.LoadThreadedGetStatus("res://Scenes/main.tscn") == ResourceLoader.ThreadLoadStatus.Loaded;
            await ToSignal(tree, SceneTree.SignalName.ProcessFrame);
        }

        // if async loading is done, switch the scene
        var packedScene = (PackedScene)ResourceLoader.LoadThreadedGet("res://Scenes/main.tscn");
        tree.ChangeSceneToPacked(packedScene);
    }

    private void UpdateLoadingAnimation()
    {
        // updates animation each frame
    }
}