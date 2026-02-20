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
    }

    private void OnMouseExited()
    {
        hovering = false;
        pressed = false;
    }

    private void OnGuiInput(InputEvent inputEvent)
    {
        if (inputEvent is InputEventMouseButton mouseEvent)
        {
            if (mouseEvent.Pressed && mouseEvent.ButtonIndex == MouseButton.Left && hovering)
            {


                pressed = true;
            }

            if (!mouseEvent.Pressed && mouseEvent.ButtonIndex == MouseButton.Left)
            {


                pressed = false;
            }
        }
    }
}