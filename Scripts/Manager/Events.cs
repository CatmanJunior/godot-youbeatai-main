using Godot;

public partial class Manager : Node
{
    [Signal] public delegate void OnSwitchLayerEventHandler(int layer);
    [Signal] public delegate void OnShouldClapEventEventHandler();
    [Signal] public delegate void OnShouldStompEventEventHandler();
}