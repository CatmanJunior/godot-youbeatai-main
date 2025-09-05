using Godot;
using System;

public partial class LayerChaosPadSelectButton : Sprite2D
{
    [Export] int id;

    bool inside => IsPixelOpaque(GetLocalMousePosition());

    public override void _Input(InputEvent inputEvent)
    {
		if (inputEvent is InputEventMouseButton mouseEvent && mouseEvent.ButtonIndex == MouseButton.Left)
		{
			if (mouseEvent.IsReleased())
			{
				if (inside) OnPress();
			}
		}
    }

	public void OnPress()
	{
		Manager.instance.SynthMixing_ChangeSynth(id);
	}
}