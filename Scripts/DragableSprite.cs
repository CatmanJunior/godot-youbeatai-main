using Godot;

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
            NewPosition(mouseMotionEvent.Position + dragOffset);
        }
    }

    public void NewPosition(Vector2 position)
    {
        // triangle edges
        Node2D[] corners = Manager.instance.corners;
        Vector2 a = corners[0].GlobalPosition;
        Vector2 b = corners[1].GlobalPosition;
        Vector2 c = corners[2].GlobalPosition;

        // free movement inside triangle
        var weights = Manager.instance.GetBarycentricWeights(position, a, b, c);
        if (Manager.instance.IsInsideTriangle(weights))
        {
            GlobalPosition = position;
            return;
        }

        // max dist from triangle
        float maxdist = Manager.instance.outerTriangleSize;

        var DistanceToSegment = (Vector2 p, Vector2 a, Vector2 b) =>
        {
            Vector2 ab = b - a;
            float t = (p - a).Dot(ab) / ab.LengthSquared();
            t = Mathf.Clamp(t, 0f, 1f);
            Vector2 projection = a + ab * t;
            return (p - projection).Length();
        };

        var ClosestPointOnSegment = (Vector2 p, Vector2 a, Vector2 b) =>
        {
            Vector2 ab = b - a;
            float t = (p - a).Dot(ab) / ab.LengthSquared();
            t = Mathf.Clamp(t, 0f, 1f);
            return a + ab * t;
        };

        // check distance from each edge
        float distAB = DistanceToSegment(position, a, b);
        float distBC = DistanceToSegment(position, b, c);
        float distCA = DistanceToSegment(position, c, a);

        float minDist = Mathf.Min(distAB, Mathf.Min(distBC, distCA));

        // if the position is too far from the closest edge, move it closer
        if (minDist > maxdist)
        {
            // direction from closest point on the triangle to position
            Vector2 closestPoint = position;
            if (minDist == distAB) closestPoint = ClosestPointOnSegment(position, a, b);
            else if (minDist == distBC) closestPoint = ClosestPointOnSegment(position, b, c);
            else if (minDist == distCA) closestPoint = ClosestPointOnSegment(position, c, a);

            Vector2 dir = (position - closestPoint).Normalized();
            position = closestPoint + dir * maxdist;
        }

        GlobalPosition = position;
    }
}