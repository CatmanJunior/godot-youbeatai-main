using Godot;
using System;

public partial class Blocker : Panel
{
    private bool hovering = false;

    public override void _Ready()
    {
        MouseEntered += OnMouseEntered;
        MouseExited += OnMouseExited;
        GuiInput += OnGuiInput;
    }

    private void OnMouseEntered()
    {
        hovering = true;
        GD.Print("Blocker hover start.");
    }

    private void OnMouseExited()
    {
        hovering = false;
        GD.Print("Blocker hover stopped.");
    }

    private void OnGuiInput(InputEvent inputEvent)
    {
        if (inputEvent is InputEventMouseButton mouseEvent)
        {
            if (mouseEvent.Pressed && mouseEvent.ButtonIndex == MouseButton.Left)
            {
                GD.Print("Blocker clicked.");
            }
        }
    }
}