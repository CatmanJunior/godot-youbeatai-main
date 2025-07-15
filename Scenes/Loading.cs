using Godot;
using System;
using System.Threading.Tasks;

public partial class Loading : Panel
{
    [Export] AnimatedSprite2D animation;

    bool firstframedone = false;
    bool startedloading = false;

    public override void _Ready()
    {
        animation.Play();
        animation.AnimationFinished += () => animation.Play();
    }

    public override void _Process(double delta)
    {
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

        // check periodicly if loading is done
        bool isloaded = false;
        while (!isloaded)
        {
            isloaded = ResourceLoader.LoadThreadedGetStatus("res://Scenes/main.tscn") == ResourceLoader.ThreadLoadStatus.Loaded;
            await Task.Delay(1000);
        }

        // if async loading is done, switch the scene
        var packedScene = (PackedScene)ResourceLoader.LoadThreadedGet("res://Scenes/main.tscn");
        tree.ChangeSceneToPacked(packedScene);
    }
}