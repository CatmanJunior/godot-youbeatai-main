using Godot;

public partial class RecordButton : Sprite2D
{
    [Export] int id;

	bool inside => IsPixelOpaque(GetLocalMousePosition());

    Color original_c;
    Color hover_c;
    Color pressed_c;

    public bool pressed = false;

    public override void _Ready()
    {
        original_c = SelfModulate;
        hover_c = original_c.Lightened(0.2f);
        pressed_c = new Color(1, 0, 0, 1);
    }


    public override void _Input(InputEvent inputEvent)
    {
		if (inputEvent is InputEventMouseButton mouseEvent && mouseEvent.ButtonIndex == MouseButton.Left)
		{
			// on release
			if (mouseEvent.IsReleased())
			{
				if (inside) OnPressed();
			}
		}
    }

    public override void _Process(double delta)
    {
        if (pressed) SelfModulate = pressed_c;
        else if (inside) SelfModulate = hover_c;
        else SelfModulate = original_c;
    }

    public void OnPressed()
    {
        // on click
    }
}