using Godot;
using System;

public partial class DragableSprite : Sprite2D
{
    private bool dragging = false;
    private Vector2 dragOffset = Vector2.Zero;

    public override void _Input(InputEvent inputEvent)
    {
        if (inputEvent is InputEventMouseButton mouseButtonEvent)
        {
            if (mouseButtonEvent.ButtonIndex == MouseButton.Left)
            {
                if (mouseButtonEvent.Pressed)
                {
                    if (IsPixelOpaque(GetLocalMousePosition()))
                    {
                        dragging = true;
                        dragOffset = GlobalPosition - mouseButtonEvent.Position;
                    }
                }
                else
                {
                    dragging = false;
                }
            }
        }

        if (inputEvent is InputEventMouseMotion mouseMotionEvent && dragging)
        {
            GlobalPosition = mouseMotionEvent.Position + dragOffset;
        }
    }
}