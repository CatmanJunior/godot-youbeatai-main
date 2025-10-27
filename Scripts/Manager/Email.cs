using System;
using Godot;

public partial class Manager : Node
{
    [Export] public Panel emailPrompt;
    [Export] public LineEdit emailInput;
    [Export] public Button emailEnter;
    public bool emailPromptOpen = false;

    private Action cachedEmailPromptAction = null;

    public void OpenEmailPrompt(Action todo)
    {
        // show email prompt
        emailPrompt.Position = new Vector2(-636, -356);
        emailPromptOpen = true;

        // set button action
        cachedEmailPromptAction = todo;
        emailEnter.ButtonUp += cachedEmailPromptAction;
        emailEnter.ButtonUp += CloseEmailPrompt;
    }

    public void CloseEmailPrompt()
    {
        // set aside email prompt
        emailPrompt.Position = new Vector2(-636, -2000);
        emailPromptOpen = false;

        // reset agree button action
        emailEnter.ButtonUp -= CloseEmailPrompt;
        emailEnter.ButtonUp -= cachedEmailPromptAction;
        cachedEmailPromptAction = null;
    }
}