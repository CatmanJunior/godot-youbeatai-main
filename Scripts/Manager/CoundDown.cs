using Godot;

public partial class Manager
{
    [Export] public Panel coundDownPanel;
    [Export] public Label coundDownLabel;

    private bool isShowingCountDown = false;
    
    public void ShowCountDown()
    {
        coundDownPanel.Position = micButtonLocation.GlobalPosition - coundDownPanel.Size / 2 * coundDownPanel.Scale;
        isShowingCountDown = true;
    }

    public void CloseCountDown()
    {
        coundDownPanel.Position = -coundDownPanel.Size / 2 + Vector2.Up * 1000;
        isShowingCountDown = false;
    }

    public void UpdateCountDownLabel()
    {
        coundDownLabel.Text = CalculateTimeUntilTop().ToString("0");
    }

    public float CalculateTimeUntilTop()
    {
        int curbeat = BpmManager.instance.currentBeat;
        int beatsUntilTop = BpmManager.beatsAmount - curbeat - 1;
        int fourBeatsUntilTop = beatsUntilTop / 4;
        float timeUntilTop = beatsUntilTop * BpmManager.instance.baseTimePerBeat;
        return fourBeatsUntilTop + 1;
    }
}