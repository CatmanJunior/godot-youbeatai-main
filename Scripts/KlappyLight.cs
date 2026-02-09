using Godot;

public partial class KlappyLight : PointLight2D
{

    // Called when the node enters the scene tree for the first time.
    public override void _Ready()
    {
        Color = new Color(1, 1, 1, 1);
    }

    // Called every frame. 'delta' is the elapsed time since the previous frame.
    public override void _Process(double delta)
    {
        CheckKey();
    }

    private void CheckKey()
    {
        if (Input.IsKeyPressed(Key.W))
        {
            Color = new Color("yellow");
        }
        else if (Input.IsKeyPressed(Key.A))
        {
            Color = new Color("green");
        }
        else if (Input.IsKeyPressed(Key.S))
        {
            Color = new Color("blue");
        }
        else if (Input.IsKeyPressed(Key.D))
        {
            Color = new Color("red");
        }
    }

}
