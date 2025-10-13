using Godot;

public partial class Manager : Node
{
    [Signal] public delegate void OnSwitchLayerEventHandler(int layer);
    [Signal] public delegate void OnShouldClapEventEventHandler();
    [Signal] public delegate void OnShouldStompEventEventHandler();
    [Signal] public delegate void OnClearLayerEventEventHandler();
    [Signal] public delegate void OnCopyLayerEventEventHandler(int layer);
    [Signal] public delegate void OnPasteLayerEventEventHandler(int layer);
    [Signal] public delegate void OnRemoveLayerEventEventHandler(int layer);
    [Signal] public delegate void OnAddLayerEventEventHandler(int layer);
    [Signal] public delegate void SetGreenSynthEventHandler(Resource font, int instr);
    [Signal] public delegate void SetPurpleSynthEventHandler(Resource font, int instr);
}