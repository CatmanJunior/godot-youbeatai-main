using Godot;

public partial class Manager : Node
{
    [Export] public Panel emailPrompt;
    [Export] public TextEdit emailInput;
    [Export] public Button emailEnter;
    public bool emailPromptOpen = false;
    public void OpenEmailPrompt()
    {
        // show email prompt
        emailPrompt.Position = new Vector2(-636, -356);
        emailPromptOpen = true;
    }
    public void CloseEmailPrompt()
    {
        // set aside email prompt
        emailPrompt.Position = new Vector2(-636, -2000);
        emailPromptOpen = false;
    }
}