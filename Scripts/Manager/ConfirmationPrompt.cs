using System;
using Godot;

public partial class ConfirmationPrompt : Panel
{
    public static ConfirmationPrompt instance = null;

    [Export] public Button confirmationButtonAgree;
    [Export] public Button confirmationButtonCancel;

    private Action chachedAgreeAction = null;

    public override void _Ready()
    {
        if (instance == null) instance = this;
    }

    public override void _ExitTree()
    {
        if (instance == this) instance = null;
    }
    
    public void Open(Action agreeAction)
    {
        // show confirmation prompt
        Position = new Vector2(-224.0f, -112.0f);

        // set agree button action
        chachedAgreeAction = agreeAction;
        confirmationButtonAgree.ButtonUp += chachedAgreeAction;
        confirmationButtonAgree.ButtonUp += Close;

        // set disagree button
        confirmationButtonCancel.ButtonUp += Close;
    }

    public void Close()
    {
        // set aside confirmation prompt
        Position = new Vector2(-224.0f, -2000.0f);

        // reset agree button action
        confirmationButtonAgree.ButtonUp -= Close;
        confirmationButtonAgree.ButtonUp -= chachedAgreeAction;
        chachedAgreeAction = null;

        // reset disagree button
        confirmationButtonCancel.ButtonUp -= Close;
    }
}