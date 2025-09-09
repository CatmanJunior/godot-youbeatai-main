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
        emailPrompt.Position = new Vector2(-128, emailPrompt.Position.Y);
        emailPromptOpen = true;
    }
    public void CloseEmailPrompt()
    {
        // set aside email prompt
        emailPrompt.Position = new Vector2(-2000, emailPrompt.Position.Y);
        emailPromptOpen = false;
    }
}