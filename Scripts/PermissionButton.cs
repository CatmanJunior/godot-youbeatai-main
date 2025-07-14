using Godot;
using System;

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
                if (OS.RequestPermission("android.permission.RECORD_ANDROID") == false)
                {
                    // if not granted then quit
                    GetTree().Quit();
                }
            }
        };
    }
}