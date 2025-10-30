using Godot;

public partial class LayerChaosPadSelectButton : Sprite2D
{
    [Export] int id;
	[Export] public Button button;

    public override void _Ready()
    {
        button.ButtonUp += OnPress;
    }

	public void OnPress()
	{
		Manager.instance.SynthMixing_ChangeSynth(id);
	}
}