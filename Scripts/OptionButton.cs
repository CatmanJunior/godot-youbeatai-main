using Godot;

public partial class MyOptionButton : OptionButton
{
    public override void _Process(double delta)
    {
        ResizePopup();
    }

    private void ResizePopup()
    {
        var popup = GetPopup();
        if (popup != null) popup.ContentScaleSize = (Vector2I)(Size * 2);
    }
}