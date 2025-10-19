using Godot;

public partial class Manager : Node
{
    [Export] public Panel emojiPrompt;
    [Export] public Button[] emojiButtons;
	[Export] public Button emojiPromptCancelButton;
    
    public void OpenEmojiPrompt()
    {
        // show email prompt
        emojiPrompt.Position = new Vector2(-224.0f, -112.0f);
    }
    public void CloseEmojiPrompt()
    {
        // set aside email prompt
        emojiPrompt.Position = new Vector2(-224.0f, -2000.0f);
    }
}