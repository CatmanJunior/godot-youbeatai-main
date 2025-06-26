using Godot;
using System;

public partial class RecordBeatButton : Sprite2D
{
	[Export] int ring = 0;

	bool inside => IsPixelOpaque(GetLocalMousePosition());
	float timePressing = 0;
	bool pressing = false;

    Color original;
    Color darkened;

    public override void _Ready()
    {
        original = SelfModulate;
        darkened = SelfModulate.Darkened(0.2f);
    }


    public override void _Input(InputEvent inputEvent)
    {
		if (inputEvent is InputEventMouseButton mouseEvent && mouseEvent.ButtonIndex == MouseButton.Left)
		{
			// on press
			if (mouseEvent.IsPressed())
			{
				pressing = true;
			} 

			// on release
			if (mouseEvent.IsReleased())
			{
				pressing = false;

				if (inside) StartRecord();
			}
		}
    }

    public override void _Process(double delta)
    {
		if (pressing) timePressing += (float)delta;
		else timePressing = 0;
		if (inside) SelfModulate = darkened;
        else SelfModulate = original;
    }

    public void StartRecord()
    {
        GD.Print("start");
    }

    public void StopRecord()
    {
        GD.Print("stop");
    }
}