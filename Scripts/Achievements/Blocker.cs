using Godot;
using System;

public partial class Blocker : Panel
{
    public bool pressed = false;
    public bool hovering = false;

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
        pressed = false;
        GD.Print("Blocker hover stopped.");
    }

    private void OnGuiInput(InputEvent inputEvent)
    {
        if (inputEvent is InputEventMouseButton mouseEvent)
        {
            if (mouseEvent.Pressed && mouseEvent.ButtonIndex == MouseButton.Left && hovering)
            {
                GD.Print("Blocker pressed.");
                pressed = true;
            }

            if (!mouseEvent.Pressed && mouseEvent.ButtonIndex == MouseButton.Left)
            {
                GD.Print("Blocker released.");
                pressed = false;
            }
        }
    }
}