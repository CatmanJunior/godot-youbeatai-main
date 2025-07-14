using Godot;
using System;

public partial class PermissionButton : Button
{
    public override void _Ready()
    {
        Pressed += () =>
        {
            Pressed += () => OS.RequestPermission("android.permission.RECORD_AUDIO");
        };
    }
}