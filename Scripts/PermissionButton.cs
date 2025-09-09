using Godot;

public partial class PermissionButton : Button
{
    public override void _Ready()
    {
        // when button is pressed
        Pressed += () =>
        {
            // if android
            if (OS.GetName() == "Android")
            {
                // ask permission
                OS.RequestPermission("android.permission.RECORD_AUDIO");
            }
        };
    }
}